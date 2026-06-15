from django.urls import path
from .api_views import LoginAPIView, RegisterAPIView, ChatbotAPIView, DiagnosticLogAPIView
from rest_framework_simplejwt.views import TokenRefreshView

app_name = 'accounts_api'

urlpatterns = [
    path('login/', LoginAPIView.as_view(), name='api_login'),
    path('register/<str:role>/', RegisterAPIView.as_view(), name='api_register'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('chatbot/', ChatbotAPIView.as_view(), name='api_chatbot'),
    path('logs/', DiagnosticLogAPIView.as_view(), name='api_logs'),
]
