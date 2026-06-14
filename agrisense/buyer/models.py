from django.db import models
# Create your models here.
from django.db import models
from django.conf import settings
from farmer.models import Product

class BuyerProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    full_name = models.CharField(max_length=200, blank=True)
    phone_number = models.CharField(max_length=20, blank=True)
    city = models.CharField(max_length=100, blank=True)
    state = models.CharField(max_length=100, blank=True)

    def __str__(self):
        return self.user.username

class Cart(models.Model):
    buyer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)

class Order(models.Model):
    buyer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField()
    total_price = models.FloatField()
    delivery_address = models.TextField(blank=True, null=True)
    contact_number = models.CharField(max_length=20, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=50, default="Pending")  # Pending, Delivered, etc.

class CheckoutSession(models.Model):
    buyer = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='checkout_session')
    otp = models.CharField(max_length=6)
    address = models.TextField()
    phone = models.CharField(max_length=20)
    email = models.EmailField()
    created_at = models.DateTimeField(auto_now=True)
