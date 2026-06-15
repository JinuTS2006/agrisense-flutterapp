from rest_framework import views, viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import DeliveryAgentProfile, DeliveryAssignment
from .serializers import DeliveryAgentProfileSerializer, DeliveryAssignmentSerializer
from django.shortcuts import get_object_or_404
import random

class GenerateDeliveryOTPAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        assignment = get_object_or_404(DeliveryAssignment, id=pk, delivery_agent=request.user)
        
        # Generate new OTP
        otp = str(random.randint(100000, 999999))
        assignment.delivery_otp = otp
        assignment.save()

        # Send OTP via email to the buyer (in background thread so API doesn't block)
        buyer = assignment.order.buyer
        buyer_email = buyer.email
        if buyer_email:
            import threading
            from django.core.mail import send_mail
            from django.conf import settings as django_settings
            def _send():
                try:
                    print(f"[DELIVERY OTP] Attempting to send email from {django_settings.EMAIL_HOST_USER} to {buyer_email}...")
                    send_mail(
                        subject='Agrisense - Delivery Verification OTP',
                        message=f'Your delivery verification OTP is: {otp}\nPlease share this with the delivery agent to confirm receipt of your order.',
                        from_email=django_settings.EMAIL_HOST_USER,
                        recipient_list=[buyer_email],
                        fail_silently=False,
                    )
                    print(f"[DELIVERY OTP] Email sent asynchronously to {buyer_email} successfully.")
                except Exception as e:
                    import traceback
                    print(f"[DELIVERY OTP] Email error in background thread: {e}")
                    traceback.print_exc()
            threading.Thread(target=_send).start()
        else:
            print(f"[DELIVERY OTP] No email for buyer. OTP for order #{assignment.order.id}: {otp}")

        print(f"--- DELIVERY OTP GENERATED: {otp} for assignment {pk} ---")
        return Response({
            "message": "Delivery OTP sent to buyer's email.",
            "otp": otp
        })

class DeliveryAgentProfileAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = DeliveryAgentProfile.objects.get_or_create(user=request.user)
        return Response(DeliveryAgentProfileSerializer(profile).data)

    def put(self, request):
        profile, _ = DeliveryAgentProfile.objects.get_or_create(user=request.user)
        serializer = DeliveryAgentProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class DeliveryAssignmentViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = DeliveryAssignmentSerializer

    def get_queryset(self):
        return DeliveryAssignment.objects.filter(delivery_agent=self.request.user).order_by('-assigned_at')

class UpdateAssignmentStatusAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        assignment = get_object_or_404(DeliveryAssignment, id=pk, delivery_agent=request.user)
        new_status = request.data.get("status")

        if new_status in dict(DeliveryAssignment.STATUS_CHOICES):
            if new_status == "delivered":
                otp_input = request.data.get("otp")
                if not assignment.delivery_otp:
                    return Response({"error": "Delivery OTP not generated. Please generate one first."}, status=status.HTTP_400_BAD_REQUEST)
                if assignment.delivery_otp != otp_input:
                    return Response({"error": "Invalid Delivery OTP."}, status=status.HTTP_400_BAD_REQUEST)

            assignment.status = new_status
            assignment.save()

            # Optional: update main order status if delivered
            if new_status == "delivered":
                assignment.order.status = "delivered"
                assignment.order.save()

            return Response(DeliveryAssignmentSerializer(assignment).data)
        
        return Response({"error": "Invalid status"}, status=status.HTTP_400_BAD_REQUEST)
