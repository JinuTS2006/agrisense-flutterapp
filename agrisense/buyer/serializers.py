from rest_framework import serializers
from .models import BuyerProfile, Cart, Order
from farmer.serializers import ProductSerializer

class BuyerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = BuyerProfile
        fields = '__all__'
        read_only_fields = ['user']

class CartSerializer(serializers.ModelSerializer):
    product_details = ProductSerializer(source='product', read_only=True)

    class Meta:
        model = Cart
        fields = '__all__'
        read_only_fields = ['buyer']

class OrderSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_image = serializers.ImageField(source='product.image', read_only=True)

    class Meta:
        model = Order
        fields = '__all__'
        read_only_fields = ['buyer', 'product', 'quantity', 'total_price', 'created_at']
