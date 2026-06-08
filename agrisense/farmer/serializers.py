from rest_framework import serializers
from .models import Product, FarmerProfile, Order

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = '__all__'
        read_only_fields = ['farmer', 'created_at']

class FarmerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = FarmerProfile
        fields = '__all__'
        read_only_fields = ['user']

class OrderSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    buyer_name = serializers.CharField(source='buyer.first_name', read_only=True)

    class Meta:
        model = Order
        fields = '__all__'
        read_only_fields = ['buyer', 'product', 'quantity', 'total_price', 'created_at', 'updated_at']
