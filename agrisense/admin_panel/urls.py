from django.urls import path
from . import views

app_name = "admin_panel"  # <-- important for namespacing

urlpatterns = [
    path("dashboard/", views.admin_dashboard, name="dashboard"),
    path("users/", views.admin_users, name="users"),
    path("users/edit/<int:user_id>/", views.admin_edit_user, name="edit_user"),
    path("users/delete/<int:user_id>/", views.admin_delete_user, name="delete_user"),
]
