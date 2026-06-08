from django.urls import path
from . import views

app_name = "delivery"

urlpatterns = [
    path("dashboard/", views.delivery_dashboard, name="dashboard"),
    path("profile/", views.delivery_profile_view, name="profile"),
    path("assignments/", views.my_assignments, name="view_assignments"),
    path("assignments/update/<int:assignment_id>/", views.update_assignment_status, name="update_assignment_status"),
]
