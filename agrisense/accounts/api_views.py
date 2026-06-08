from rest_framework import views, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .models import User
from farmer.models import FarmerProfile
from buyer.models import BuyerProfile
from delivery.models import DeliveryAgentProfile
from .serializers import UserSerializer, RegisterSerializer

class LoginAPIView(views.APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")

        user = authenticate(username=username, password=password)
        if user:
            refresh = RefreshToken.for_user(user)
            return Response({
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": UserSerializer(user).data
            })
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

class RegisterAPIView(views.APIView):
    permission_classes = [AllowAny]

    def post(self, request, role):
        if role not in ["farmer", "buyer", "delivery"]:
            return Response({"error": "Invalid role"}, status=status.HTTP_400_BAD_REQUEST)

        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data
            user = User.objects.create_user(
                username=data['username'],
                password=data['password'],
                first_name=data['full_name'],
                phone=data.get('phone_number', ''),
                role=role
            )

            city = data.get('city', '')
            state = data.get('state', '')

            if role == "farmer":
                FarmerProfile.objects.create(user=user, city=city, state=state)
            elif role == "buyer":
                BuyerProfile.objects.create(user=user, city=city, state=state)
            elif role == "delivery":
                DeliveryAgentProfile.objects.create(user=user, city=city, state=state)

            refresh = RefreshToken.for_user(user)
            return Response({
                "message": f"{role.capitalize()} registration successful!",
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": UserSerializer(user).data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
