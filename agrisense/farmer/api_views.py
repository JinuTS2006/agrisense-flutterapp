from rest_framework import views, viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Product, FarmerProfile, Order
from .serializers import ProductSerializer, FarmerProfileSerializer, OrderSerializer
from rest_framework.parsers import MultiPartParser, FormParser
import requests
import pandas as pd
from ml_module.crop_recommendation import recommend_top_crops
from ml_module.yield_prediction import predict_yield, MODEL_FILE, pickle

class FarmerProfileAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = FarmerProfile.objects.get_or_create(
            user=request.user,
            defaults={"city": "Bangalore", "state": "Karnataka"}
        )
        serializer = FarmerProfileSerializer(profile)
        return Response(serializer.data)

    def put(self, request):
        profile = FarmerProfile.objects.get(user=request.user)
        serializer = FarmerProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ProductViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = ProductSerializer
    parser_classes = (MultiPartParser, FormParser)

    def get_queryset(self):
        return Product.objects.filter(farmer=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(farmer=self.request.user)

class FarmerOrderViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = OrderSerializer

    def get_queryset(self):
        return Order.objects.filter(product__farmer=self.request.user).order_by('-created_at')

class OrderStatusUpdateAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        try:
            order = Order.objects.get(id=pk, product__farmer=request.user)
        except Order.DoesNotExist:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get("status")
        if new_status in dict(Order.STATUS_CHOICES):
            order.status = new_status
            order.save()
            return Response(OrderSerializer(order).data)
        return Response({'error': 'Invalid status'}, status=status.HTTP_400_BAD_REQUEST)

class CropRecommendationAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        profile, _ = FarmerProfile.objects.get_or_create(
            user=request.user,
            defaults={"city": "Bangalore", "state": "Karnataka"}
        )
        weather = {"temperature": 25, "humidity": 50, "rainfall": 0}
        try:
            API_KEY = "REDACTED_API_KEY"
            url = f"http://api.openweathermap.org/data/2.5/weather?q={profile.city}&appid={API_KEY}&units=metric"
            res = requests.get(url, timeout=5).json()
            weather["temperature"] = res["main"]["temp"]
            weather["humidity"] = res["main"]["humidity"]
            weather["rainfall"] = res.get("rain", {}).get("1h", 0)
        except:
            pass
        
        input_features = {
            "N": float(request.data.get("N", 90)),
            "P": float(request.data.get("P", 42)),
            "K": float(request.data.get("K", 43)),
            "temperature": weather["temperature"],
            "humidity": weather["humidity"],
            "ph": float(request.data.get("ph", 6.5)),
            "rainfall": weather["rainfall"]
        }
        top_crops = recommend_top_crops(input_features, top_n=3)
        recommended_crops = [{"crop": crop, "probability": round(prob * 100, 2)} for crop, prob in top_crops]
        return Response({"recommended_crops": recommended_crops, "weather": weather})

class YieldPredictionAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from ml_module.yield_prediction import CROP_MAPPING
        return Response({"crops": list(CROP_MAPPING.keys())})

    def post(self, request):
        crop_name = request.data.get("crop")
        profile, _ = FarmerProfile.objects.get_or_create(user=request.user)
        weather = {"avg_temp_c": 25, "avg_humidity_percent": 50, "total_rainfall_mm": 0}
        try:
            API_KEY = "REDACTED_API_KEY"
            url = f"http://api.openweathermap.org/data/2.5/weather?q={profile.city}&appid={API_KEY}&units=metric"
            res = requests.get(url, timeout=5).json()
            weather["avg_temp_c"] = res["main"]["temp"]
            weather["avg_humidity_percent"] = res["main"]["humidity"]
            weather["total_rainfall_mm"] = res.get("rain", {}).get("1h", 0)
        except:
            pass
        
        input_data = {
            "N": float(request.data.get("N", 90)),
            "P": float(request.data.get("P", 42)),
            "K": float(request.data.get("K", 43)),
            "pH": float(request.data.get("pH", 6.5)),
            "avg_temp_c": weather["avg_temp_c"],
            "avg_humidity_percent": weather["avg_humidity_percent"],
            "total_rainfall_mm": weather["total_rainfall_mm"]
        }
        
        try:
            predicted_yield = predict_yield(crop_name, input_data)
            return Response({"predicted_yield": predicted_yield})
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

class ProfitAnalysisAPIView(views.APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            price_df = pd.read_csv("ml_module/data/crop_price_state.csv")
            return Response({
                "states": price_df["state"].unique().tolist(),
                "crops": price_df["crop"].str.lower().unique().tolist()
            })
        except Exception as e:
            return Response({"states": [], "crops": []})

    def post(self, request):
        state = request.data.get("state")
        crop = request.data.get("crop", "").strip().lower()
        area = float(request.data.get("area", 0))
        predicted_yield = float(request.data.get("yield", 0))

        try:
            price_df = pd.read_csv("ml_module/data/crop_price_state.csv")
            price_df["crop"] = price_df["crop"].str.lower()
            row = price_df[(price_df["state"] == state) & (price_df["crop"] == crop)]
            
            if row.empty:
                return Response({"error": "Price data not available for this crop in the selected state."}, status=status.HTTP_404_NOT_FOUND)
            
            price_per_tonne = float(row.iloc[0]["avg_price_per_tonne"])
            cost_per_ha = float(row.iloc[0]["avg_cost_per_ha"])
            
            total_yield = predicted_yield * area
            revenue = total_yield * price_per_tonne
            cost = cost_per_ha * area
            profit = revenue - cost
            
            return Response({
                "total_yield": total_yield,
                "price": price_per_tonne,
                "revenue": revenue,
                "cost": cost,
                "profit": profit
            })
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
