from rest_framework import views, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from accounts.models import User
from accounts.serializers import UserSerializer
from farmer.models import Product, Order as FarmerOrder
from buyer.models import Order as BuyerOrder
from delivery.models import DeliveryAssignment

class AdminDashboardAPIView(views.APIView):
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request):
        stats = {
            "total_users": User.objects.count(),
            "total_farmers": User.objects.filter(role="farmer").count(),
            "total_buyers": User.objects.filter(role="buyer").count(),
            "total_delivery": User.objects.filter(role="delivery").count(),
            "total_products": Product.objects.count(),
            "total_orders": BuyerOrder.objects.count(),
            "pending_deliveries": DeliveryAssignment.objects.filter(status="pending").count(),
        }
        return Response(stats)

class AdminUsersAPIView(views.APIView):
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request):
        users = User.objects.exclude(is_superuser=True)
        return Response(UserSerializer(users, many=True).data)

class AdminEditUserAPIView(views.APIView):
    permission_classes = [IsAuthenticated, IsAdminUser]

    def put(self, request, pk):
        try:
            user = User.objects.get(id=pk)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
            
        serializer = UserSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        try:
            user = User.objects.get(id=pk)
            user.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
