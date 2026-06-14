from rest_framework import views, viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
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

import random
from django.core.cache import cache

class CheckoutInitiateAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        cart_items = Cart.objects.filter(buyer=request.user)
        if not cart_items.exists():
            return Response({"error": "Cart is empty"}, status=status.HTTP_400_BAD_REQUEST)

        address = request.data.get("address")
        phone = request.data.get("phone")
        email = request.data.get("email")
        if not address or not phone or not email:
            return Response({"error": "Address, phone number, and email are required"}, status=status.HTTP_400_BAD_REQUEST)

        # Generate OTP
        otp = str(random.randint(100000, 999999))
        
        # Save session to cache
        session_key = f"checkout_otp_{request.user.id}"
        cache.set(session_key, {
            "otp": otp,
            "address": address,
            "phone": phone,
            "email": email
        }, timeout=300) # Valid for 5 minutes

        # Send OTP via Email
        from django.core.mail import send_mail
        from django.conf import settings
        try:
            send_mail(
                subject='Agrisense - Your Checkout OTP',
                message=f'Your OTP for completing the purchase is: {otp}\nThis OTP is valid for 5 minutes.',
                from_email=getattr(settings, 'EMAIL_HOST_USER', 'noreply@agrisense.com'),
                recipient_list=[email],
                fail_silently=False,
            )
            print(f"--- SENT CHECKOUT OTP TO {email}: {otp} ---")
        except Exception as e:
            print(f"--- ERROR SENDING OTP EMAIL: {e} ---")
            print(f"--- FALLBACK CHECKOUT OTP FOR {request.user.username}: {otp} ---")

        return Response({
            "message": "OTP generated successfully",
            "otp": otp # Returning OTP here for easy testing from Flutter app
        })

class CheckoutAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from farmer.models import Order as FarmerOrder
        from delivery.models import DeliveryAssignment, DeliveryAgentProfile

        cart_items = Cart.objects.filter(buyer=request.user)
        if not cart_items.exists():
            return Response({"error": "Cart is empty"}, status=status.HTTP_400_BAD_REQUEST)

        # Verify OTP
        otp_input = request.data.get("otp")
        session_key = f"checkout_otp_{request.user.id}"
        session_data = cache.get(session_key)

        if not session_data or session_data.get("otp") != otp_input:
            return Response({"error": "Invalid or expired OTP"}, status=status.HTTP_400_BAD_REQUEST)

        address = session_data.get("address")
        phone = session_data.get("phone")
        email = session_data.get("email")

        # Save the checkout email to the user so the delivery OTP can reach them
        if email and request.user.email != email:
            request.user.email = email
            request.user.save()

        # Pick first available delivery agent (same as website)
        agent_profile = DeliveryAgentProfile.objects.first()
        if not agent_profile:
            return Response({"error": "No delivery agent available at the moment."}, status=status.HTTP_400_BAD_REQUEST)

        orders = []
        for item in cart_items:
            product = item.product

            total_price = item.quantity * product.price

            # Validate quantity
            if product.quantity < item.quantity:
                return Response({"error": f"Not enough stock for {product.name}. Available: {product.quantity}"}, status=status.HTTP_400_BAD_REQUEST)

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
                status="Pending"
            )

            # 2. Create farmer order (for delivery assignment tracking)
            farmer_order = FarmerOrder.objects.create(
                buyer=request.user,
                product=product,
                quantity=item.quantity,
                total_price=total_price,
                delivery_address=address,
                contact_number=phone,
                status="pending"
            )

            # 3. Assign delivery agent (same as website)
            DeliveryAssignment.objects.create(
                order=farmer_order,
                delivery_agent=agent_profile.user
            )

            orders.append(buyer_order)

        cart_items.delete()
        cache.delete(session_key)

        return Response({
            "message": f"Order placed successfully and assigned to {agent_profile.full_name}.",
            "agent_name": agent_profile.full_name,
            "orders": OrderSerializer(orders, many=True).data
        })

class OrderHistoryAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        orders = Order.objects.filter(buyer=request.user).order_by('-created_at')
        return Response(OrderSerializer(orders, many=True).data)
