from rest_framework import serializers
from .models import DeliveryAgentProfile, DeliveryAssignment

class DeliveryAgentProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryAgentProfile
        fields = '__all__'
        read_only_fields = ['user']

class DeliveryAssignmentSerializer(serializers.ModelSerializer):
    order_details = serializers.SerializerMethodField()

    class Meta:
        model = DeliveryAssignment
        fields = '__all__'
        read_only_fields = ['delivery_agent', 'order', 'assigned_at', 'updated_at']

    def get_order_details(self, obj):
        from farmer.serializers import OrderSerializer
        return OrderSerializer(obj.order).data
