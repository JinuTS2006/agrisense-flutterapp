from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .api_views import (
    BuyerProfileAPIView,
    BrowseProductsAPIView,
    CartViewSet,
    CheckoutAPIView,
    CheckoutInitiateAPIView,
    TestCheckoutInitiateAPIView,
    OrderHistoryAPIView
)

router = DefaultRouter()
router.register(r'cart', CartViewSet, basename='cart')

app_name = 'buyer_api'

urlpatterns = [
    path('profile/', BuyerProfileAPIView.as_view(), name='api_profile'),
    path('products/', BrowseProductsAPIView.as_view(), name='api_browse_products'),
    path('cart/checkout/test-initiate/', TestCheckoutInitiateAPIView.as_view(), name='api_test_checkout_initiate'),
    path('cart/checkout/initiate/', CheckoutInitiateAPIView.as_view(), name='api_checkout_initiate'),
    path('cart/checkout/', CheckoutAPIView.as_view(), name='api_checkout'),
    path('orders/', OrderHistoryAPIView.as_view(), name='api_order_history'),
    path('', include(router.urls)),
]
