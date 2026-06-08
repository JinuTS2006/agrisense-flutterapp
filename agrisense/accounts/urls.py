from django.urls import path
from .views import login_view
from . import views
app_name = 'accounts'

urlpatterns = [
    path("", views.home, name="home"),
    path('login/', views.login_view, name='login'),
    path("register/<str:role>/", views.register_role, name="register_role"),

]
