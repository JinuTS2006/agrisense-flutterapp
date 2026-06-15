import random
import traceback
import json

from rest_framework import views, viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.core import signing

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
# Checkout Initiate  – generates OTP, returns a signed token (NO DB/cache)
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
            try:
                cart_items = Cart.objects.filter(buyer=request.user)
                if not cart_items.exists():
                    return Response({"error": "Cart is empty"}, status=status.HTTP_400_BAD_REQUEST)
                print("[CHECKOUT] Cart retrieved successfully.")
            except Exception as e:
                print(f"[CHECKOUT] Error retrieving cart: {e}")
                raise e

            try:
                address = request.data.get("address")
                phone = request.data.get("phone")
                email = request.data.get("email")
                if not address or not phone or not email:
                    return Response(
                        {"error": "Address, phone number, and email are required"},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                print("[CHECKOUT] Request validation successful.")
            except Exception as e:
                print(f"[CHECKOUT] Error during validation: {e}")
                raise e

            try:
                otp = str(random.randint(100000, 999999))
                token_data = {
                    "otp": otp,
                    "address": address,
                    "phone": phone,
                    "email": email,
                    "user_id": request.user.pk,
                }
                checkout_token = signing.dumps(token_data, salt="checkout-otp")
                print(f"[CHECKOUT] OTP and token generated for {request.user.username}.")
            except Exception as e:
                print(f"[CHECKOUT] Error during token generation: {e}")
                raise e

            try:
                from django.core.mail import send_mail
                from django.conf import settings
                print(f"[CHECKOUT] Attempting to send email from {settings.EMAIL_HOST_USER} to {email}...")
                send_mail(
                    subject="Agrisense - Your Checkout OTP",
                    message=f"Your OTP for completing the purchase is: {otp}\nThis OTP is valid for 5 minutes.",
                    from_email=settings.EMAIL_HOST_USER,
                    recipient_list=[email],
                    fail_silently=False,
                )
                print(f"[CHECKOUT] Email sent to {email} successfully.")
            except Exception as e:
                import traceback
                print(f"[CHECKOUT] Email error: {e}")
                traceback.print_exc()

            return Response({
                "message": "OTP generated successfully",
                "otp": otp,
                "checkout_token": checkout_token,
            })

        except Exception as e:
            tb = traceback.format_exc()
            print(f"[CHECKOUT INITIATE ERROR]\n{tb}")
            try:
                import os
                log_path = "/tmp/django_error_log.txt"
                with open(log_path, "a", encoding="utf-8") as f:
                    f.write(f"=== CHECKOUT INITIATE ERROR ===\n{tb}\n\n")
            except Exception as write_err:
                print(f"Failed to write log: {write_err}")
            return Response(
                {"error": f"Checkout error: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


# ---------------------------------------------------------------------------
# Checkout Complete  – verifies OTP from signed token and places orders
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

            otp_input = request.data.get("otp")
            checkout_token = request.data.get("checkout_token", "")

            if not otp_input:
                return Response({"error": "OTP is required"}, status=status.HTTP_400_BAD_REQUEST)

            # Verify the signed token (max_age=300 = 5 minutes)
            try:
                token_data = signing.loads(checkout_token, salt="checkout-otp", max_age=300)
            except signing.BadSignature:
                return Response({"error": "Invalid or expired checkout session"}, status=status.HTTP_400_BAD_REQUEST)
            except signing.SignatureExpired:
                return Response({"error": "Checkout session expired. Please try again."}, status=status.HTTP_400_BAD_REQUEST)

            # Verify OTP matches
            if token_data.get("otp") != otp_input:
                return Response({"error": "Invalid OTP"}, status=status.HTTP_400_BAD_REQUEST)

            # Verify user matches
            if token_data.get("user_id") != request.user.pk:
                return Response({"error": "Invalid checkout session"}, status=status.HTTP_400_BAD_REQUEST)

            address = token_data["address"]
            phone = token_data["phone"]
            email = token_data["email"]

            # Save the checkout email to the user
            if email and request.user.email != email:
                request.user.email = email
                request.user.save()

            # Robust random selection of delivery agent
            agent_profiles = list(DeliveryAgentProfile.objects.all())
            selected_agent = random.choice(agent_profiles) if agent_profiles else None
            agent_name = selected_agent.full_name if selected_agent else "Unassigned"

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
                if selected_agent:
                    DeliveryAssignment.objects.create(
                        order=farmer_order,
                        delivery_agent=selected_agent.user,
                    )

                orders.append(buyer_order)

            cart_items.delete()

            return Response({
                "message": f"Order placed successfully and assigned to {agent_name}.",
                "agent_name": agent_name,
                "orders": OrderSerializer(orders, many=True).data,
            })

        except Exception as e:
            tb = traceback.format_exc()
            print(f"[CHECKOUT COMPLETE ERROR]\n{tb}")
            return Response(
                {"error": f"Checkout error: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class OrderHistoryAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        orders = Order.objects.filter(buyer=request.user).order_by('-created_at')
        return Response(OrderSerializer(orders, many=True).data)


class TestCheckoutInitiateAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        return Response({"message": "test initiate works"})

