from django.db import models
from django.conf import settings
from farmer.models import Order

class DeliveryAgentProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    full_name = models.CharField(max_length=200, blank=True)
    phone_number = models.CharField(max_length=20, blank=True)
    city = models.CharField(max_length=100, blank=True)
    state = models.CharField(max_length=100, blank=True)
    email = models.EmailField(blank=True)
    def __str__(self):
        return self.user.username


class Assignment(models.Model):
    agent = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    order = models.ForeignKey(Order, on_delete=models.CASCADE)
    status = models.CharField(
        max_length=50,
        choices=[("pending", "Pending"), ("picked", "Picked Up"), ("delivered", "Delivered")],
        default="pending"
    )
    assigned_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Assignment #{self.id} - {self.order.product.name}"


# delivery/models.py
from django.db import models
from accounts.models import User
from farmer.models import Order

class DeliveryAssignment(models.Model):
    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("picked_up", "Picked Up"),
        ("delivered", "Delivered"),
        ("failed", "Failed"),
    ]

    delivery_agent = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="assignments"
    )
    order = models.OneToOneField(
        Order, on_delete=models.CASCADE, related_name="delivery_assignment"
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    delivery_otp = models.CharField(max_length=6, blank=True, null=True)
    assigned_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.order.id} -> {self.delivery_agent.username}"
