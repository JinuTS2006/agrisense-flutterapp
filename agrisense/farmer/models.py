from django.db import models

# Create your models here.
from django.db import models
from accounts.models import User

class Product(models.Model):
    farmer = models.ForeignKey(User, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    price = models.FloatField()
    quantity = models.FloatField()
    image = models.ImageField(upload_to="products/", null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class FarmerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)

    full_name = models.CharField(max_length=100, blank=True)
    phone_number = models.CharField(max_length=15, blank=True)
    email = models.EmailField(blank=True)
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    country = models.CharField(max_length=100, default="India")

from django.db import models

class CropMarketPrice(models.Model):
    crop = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    avg_price_per_quintal = models.FloatField()
    last_updated = models.DateField(auto_now=True)

    def __str__(self):
        return f"{self.crop} - {self.state}"
from django.db import models
from django.contrib.auth.models import User

from django.db import models
from accounts.models import User

class Order(models.Model):
    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("confirmed", "Confirmed"),
        ("shipped", "Shipped"),
        ("delivered", "Delivered"),
        ("cancelled", "Cancelled"),
    ]

    buyer = models.ForeignKey(User, on_delete=models.CASCADE, related_name="buyer_orders")
    product = models.ForeignKey("Product", on_delete=models.CASCADE, related_name="farmer_orders")
    quantity = models.FloatField()
    total_price = models.FloatField()
    delivery_address = models.TextField(blank=True, null=True)
    contact_number = models.CharField(max_length=20, blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
