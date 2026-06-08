from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .api_views import (
    FarmerProfileAPIView,
    ProductViewSet,
    FarmerOrderViewSet,
    OrderStatusUpdateAPIView,
    CropRecommendationAPIView,
    YieldPredictionAPIView,
    ProfitAnalysisAPIView
)

router = DefaultRouter()
router.register(r'products', ProductViewSet, basename='product')
router.register(r'orders', FarmerOrderViewSet, basename='order')

app_name = 'farmer_api'

urlpatterns = [
    path('profile/', FarmerProfileAPIView.as_view(), name='api_profile'),
    path('orders/<int:pk>/status/', OrderStatusUpdateAPIView.as_view(), name='api_order_status'),
    path('recommendation/', CropRecommendationAPIView.as_view(), name='api_recommendation'),
    path('yield/', YieldPredictionAPIView.as_view(), name='api_yield'),
    path('profit/', ProfitAnalysisAPIView.as_view(), name='api_profit'),
    path('', include(router.urls)),
]
