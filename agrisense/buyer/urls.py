from django.urls import path

app_name = 'buyer'

from django.urls import path
from . import views

app_name = "buyer"

urlpatterns = [
    path("dashboard/", views.buyer_home, name="dashboard"),
    path("products/", views.browse_products, name="browse_products"),
    path("orders/", views.order_history, name="order_history"),
    path("profile/", views.buyer_profile_view, name="buyer_profile"),
    path("cart/add/<int:product_id>/", views.add_to_cart, name="add_to_cart"),
    path("cart/", views.view_cart, name="view_cart"),
    path("cart/checkout/", views.checkout_cart, name="checkout_cart"),
    path("logout/", views.buyer_logout, name="logout"),

]

