from django.urls import path
from .api_views import AdminDashboardAPIView, AdminUsersAPIView, AdminEditUserAPIView

app_name = 'admin_api'

urlpatterns = [
    path('dashboard/', AdminDashboardAPIView.as_view(), name='api_dashboard'),
    path('users/', AdminUsersAPIView.as_view(), name='api_users'),
    path('users/<int:pk>/', AdminEditUserAPIView.as_view(), name='api_edit_user'),
]
