from django import forms
from .models import FarmerProfile

class FarmerProfileForm(forms.ModelForm):
    class Meta:
        model = FarmerProfile
        fields = [
            "full_name",
            "phone_number",
            "email",
            "state",
            "city"
        ]
from .models import Product

class ProductForm(forms.ModelForm):
    class Meta:
        model = Product
        fields = ["name", "description", "price", "quantity", "image"]
