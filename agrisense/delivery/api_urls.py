from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .api_views import (
    DeliveryAgentProfileAPIView,
    DeliveryAssignmentViewSet,
    UpdateAssignmentStatusAPIView,
    GenerateDeliveryOTPAPIView
)

router = DefaultRouter()
router.register(r'assignments', DeliveryAssignmentViewSet, basename='assignment')

app_name = 'delivery_api'

urlpatterns = [
    path('profile/', DeliveryAgentProfileAPIView.as_view(), name='api_profile'),
    path('assignments/<int:pk>/status/', UpdateAssignmentStatusAPIView.as_view(), name='api_update_status'),
    path('assignments/<int:pk>/generate_otp/', GenerateDeliveryOTPAPIView.as_view(), name='api_generate_otp'),
    path('', include(router.urls)),
]
