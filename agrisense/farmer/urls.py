#
# from django.urls import path
# from .views import farmer_dashboard

# app_name = 'farmer'

# urlpatterns = [
#     path('dashboard/', farmer_dashboard, name='dashboard'),
# ]
# 
from django.urls import path
from . import views
app_name = "farmer"   
urlpatterns = [
    path("dashboard/", views.farmer_home, name="dashboard"),
    path("recommendation/", views.crop_recommendation, name="recommendation"),
    path("yield/", views.yield_prediction_view, name="yield_prediction"),
    path("profit/", views.profit_analysis_view, name="profit"),
    path("profile/", views.farmer_profile_view, name="farmer_profile"),
    path("products/add/", views.add_product, name="add_product"),
    path("products/", views.my_products, name="my_products"),
    path("products/edit/<int:product_id>/", views.edit_product, name="edit_product"),
    path("products/delete/<int:product_id>/", views.delete_product, name="delete_product"),
    path("orders/", views.farmer_orders, name="farmer_orders"),
    path("orders/update/<int:order_id>/", views.update_order_status, name="update_order_status"),

]
