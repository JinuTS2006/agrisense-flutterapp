import random
import traceback
import datetime

from rest_framework import views, viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.core.cache import cache
from django.utils import timezone

from .models import BuyerProfile, Cart, Order
from farmer.models import Product
from .serializers import BuyerProfileSerializer, CartSerializer, OrderSerializer
from farmer.serializers import ProductSerializer


class BuyerProfileAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = BuyerProfile.objects.get_or_create(user=request.user)
        return Response(BuyerProfileSerializer(profile).data)

    def put(self, request):
        profile, _ = BuyerProfile.objects.get_or_create(user=request.user)
        serializer = BuyerProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class BrowseProductsAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        query = request.query_params.get("q", "")
        products = Product.objects.all()
        if query:
            products = products.filter(name__icontains=query)
        return Response(ProductSerializer(products, many=True).data)


class CartViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = CartSerializer

    def get_queryset(self):
        return Cart.objects.filter(buyer=self.request.user)

    def perform_create(self, serializer):
        serializer.save(buyer=self.request.user)


# ---------------------------------------------------------------------------
# OTP storage helpers – try CheckoutSession model first, fall back to cache
# ---------------------------------------------------------------------------
def _save_checkout_session(user, otp, address, phone, email):
    """Save checkout session data. DB model first, cache fallback."""
    try:
        from .models import CheckoutSession
        CheckoutSession.objects.update_or_create(
            buyer=user,
            defaults={"otp": otp, "address": address, "phone": phone, "email": email},
        )
        return "db"
    except Exception as e:
        print(f"[CHECKOUT] CheckoutSession DB save failed: {e}")
        # Fallback: use Django cache
        cache_key = f"checkout_{user.pk}"
        cache.set(cache_key, {
            "otp": otp,
            "address": address,
            "phone": phone,
            "email": email,
            "created_at": timezone.now().isoformat(),
        }, timeout=300)  # 5 minutes
        return "cache"


def _load_checkout_session(user):
    """Load checkout session data. Returns dict or None."""
    # Try DB first
    try:
        from .models import CheckoutSession
        session = CheckoutSession.objects.filter(buyer=user).first()
        if session:
            return {
                "otp": session.otp,
                "address": session.address,
                "phone": session.phone,
                "email": session.email,
                "created_at": session.created_at,
                "source": "db",
                "obj": session,
            }
    except Exception as e:
        print(f"[CHECKOUT] CheckoutSession DB load failed: {e}")

    # Fallback: try cache
    cache_key = f"checkout_{user.pk}"
    data = cache.get(cache_key)
    if data:
        created_str = data.get("created_at", "")
        try:
            created_at = datetime.datetime.fromisoformat(created_str)
            if timezone.is_naive(created_at):
                created_at = timezone.make_aware(created_at)
        except Exception:
            created_at = timezone.now()
        return {
            "otp": data["otp"],
            "address": data["address"],
            "phone": data["phone"],
            "email": data["email"],
            "created_at": created_at,
            "source": "cache",
            "obj": None,
        }

    return None


def _delete_checkout_session(user, session_info):
    """Delete checkout session data from whatever store it came from."""
    try:
        if session_info.get("source") == "db" and session_info.get("obj"):
            session_info["obj"].delete()
        else:
            cache_key = f"checkout_{user.pk}"
            cache.delete(cache_key)
    except Exception as e:
        print(f"[CHECKOUT] Session delete failed: {e}")


# ---------------------------------------------------------------------------
# Checkout Initiate  – generates OTP
# ---------------------------------------------------------------------------
class CheckoutInitiateAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            cart_items = Cart.objects.filter(buyer=request.user)
            if not cart_items.exists():
                return Response({"error": "Cart is empty"}, status=status.HTTP_400_BAD_REQUEST)

            address = request.data.get("address")
            phone = request.data.get("phone")
            email = request.data.get("email")
            if not address or not phone or not email:
                return Response(
                    {"error": "Address, phone number, and email are required"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # Generate OTP
            otp = str(random.randint(100000, 999999))

            # Persist session (DB → cache fallback)
            store = _save_checkout_session(request.user, otp, address, phone, email)
            print(f"[CHECKOUT] OTP stored via {store} for {request.user.username}: {otp}")

            # Try to send OTP via Email (non-blocking)
            try:
                from django.core.mail import send_mail
                from django.conf import settings
                send_mail(
                    subject="Agrisense - Your Checkout OTP",
                    message=f"Your OTP for completing the purchase is: {otp}\nThis OTP is valid for 5 minutes.",
                    from_email=getattr(settings, "EMAIL_HOST_USER", "noreply@agrisense.com"),
                    recipient_list=[email],
                    fail_silently=True,
                )
                print(f"[CHECKOUT] OTP email sent to {email}")
            except Exception as e:
                print(f"[CHECKOUT] Email send error (non-fatal): {e}")

            return Response({
                "message": "OTP generated successfully",
                "otp": otp,  # Returned for easy testing from Flutter app
            })

        except Exception as e:
            tb = traceback.format_exc()
            print(f"[CHECKOUT INITIATE ERROR]\n{tb}")
            return Response(
                {"error": f"Server error during checkout initiation: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


# ---------------------------------------------------------------------------
# Checkout Complete  – verifies OTP and places orders
# ---------------------------------------------------------------------------
class CheckoutAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            from farmer.models import Order as FarmerOrder
            from delivery.models import DeliveryAssignment, DeliveryAgentProfile

            cart_items = Cart.objects.filter(buyer=request.user)
            if not cart_items.exists():
                return Response({"error": "Cart is empty"}, status=status.HTTP_400_BAD_REQUEST)

            # Verify OTP
            otp_input = request.data.get("otp")
            session_info = _load_checkout_session(request.user)

            if not session_info or session_info["otp"] != otp_input:
                return Response({"error": "Invalid or expired OTP"}, status=status.HTTP_400_BAD_REQUEST)

            # Check expiration (5 minutes)
            if timezone.now() - session_info["created_at"] > datetime.timedelta(minutes=5):
                _delete_checkout_session(request.user, session_info)
                return Response({"error": "Invalid or expired OTP"}, status=status.HTTP_400_BAD_REQUEST)

            address = session_info["address"]
            phone = session_info["phone"]
            email = session_info["email"]

            # Save the checkout email to the user so the delivery OTP can reach them
            if email and request.user.email != email:
                request.user.email = email
                request.user.save()

            # Pick first available delivery agent
            agent_profile = DeliveryAgentProfile.objects.first()
            agent_name = agent_profile.full_name if agent_profile else "Unassigned"

            orders = []
            for item in cart_items:
                product = item.product
                total_price = item.quantity * product.price

                # Validate quantity
                if product.quantity < item.quantity:
                    return Response(
                        {"error": f"Not enough stock for {product.name}. Available: {product.quantity}"},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

                # Deduct inventory
                product.quantity -= item.quantity
                product.save()

                # 1. Create buyer order
                buyer_order = Order.objects.create(
                    buyer=request.user,
                    product=product,
                    quantity=item.quantity,
                    total_price=total_price,
                    delivery_address=address,
                    contact_number=phone,
                    status="Pending",
                )

                # 2. Create farmer order (for delivery assignment tracking)
                farmer_order = FarmerOrder.objects.create(
                    buyer=request.user,
                    product=product,
                    quantity=item.quantity,
                    total_price=total_price,
                    delivery_address=address,
                    contact_number=phone,
                    status="pending",
                )

                # 3. Assign delivery agent if available
                if agent_profile:
                    DeliveryAssignment.objects.create(
                        order=farmer_order,
                        delivery_agent=agent_profile.user,
                    )

                orders.append(buyer_order)

            cart_items.delete()
            _delete_checkout_session(request.user, session_info)

            return Response({
                "message": f"Order placed successfully and assigned to {agent_name}.",
                "agent_name": agent_name,
                "orders": OrderSerializer(orders, many=True).data,
            })

        except Exception as e:
            tb = traceback.format_exc()
            print(f"[CHECKOUT COMPLETE ERROR]\n{tb}")
            return Response(
                {"error": f"Server error during checkout: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class OrderHistoryAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        orders = Order.objects.filter(buyer=request.user).order_by('-created_at')
        return Response(OrderSerializer(orders, many=True).data)
