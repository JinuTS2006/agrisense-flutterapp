from django.shortcuts import render

# Create your views here.
# buyer/views.py
from django.shortcuts import render
from django.contrib.auth.decorators import login_required

from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from farmer.models import Product
from .models import BuyerProfile, Order, Cart

@login_required
def buyer_home(request):
    if request.user.role != "buyer":
        messages.error(request, "You are not authorized to access this page.")
        return redirect("accounts:login")
    
    return render(request, "buyer/home.html")

@login_required
def browse_products(request):
    products = Product.objects.all().order_by("-created_at")
    return render(request, "buyer/browse_products.html", {"products": products})

@login_required
def add_to_cart(request, product_id):
    product = get_object_or_404(Product, id=product_id)
    cart_item, created = Cart.objects.get_or_create(buyer=request.user, product=product)
    if not created:
        cart_item.quantity += 1
        cart_item.save()
    messages.success(request, f"{product.name} added to cart.")
    return redirect("buyer:browse_products")

@login_required
def view_cart(request):
    cart_items = Cart.objects.filter(buyer=request.user)

    # Add total price per item
    for item in cart_items:
        item.total_price = item.quantity * item.product.price

    return render(request, "buyer/cart.html", {"cart_items": cart_items})


from farmer.models import Order as FarmerOrder


from buyer.models import Cart, Order as BuyerOrder
from farmer.models import Order as FarmerOrder
from delivery.models import DeliveryAssignment, DeliveryAgentProfile
from django.shortcuts import redirect
from django.contrib import messages
from django.contrib.auth.decorators import login_required

@login_required
def checkout_cart(request):
    cart_items = Cart.objects.filter(buyer=request.user)
    if not cart_items.exists():
        messages.error(request, "Your cart is empty.")
        return redirect("buyer:browse_products")

    # pick first available delivery agent
    agent_profile = DeliveryAgentProfile.objects.first()
    if not agent_profile:
        messages.error(request, "No delivery agent available at the moment.")
        return redirect("buyer:browse_products")

    for item in cart_items:
        # 1️⃣ Create buyer order
        buyer_order = BuyerOrder.objects.create(
            buyer=request.user,
            product=item.product,
            quantity=item.quantity,
            total_price=item.quantity * item.product.price,
        )

        # 2️⃣ Create farmer order (same info) for DeliveryAssignment
        farmer_order = FarmerOrder.objects.create(
            buyer=request.user,
            product=item.product,
            quantity=item.quantity,
            total_price=item.quantity * item.product.price,
        )

        # 3️⃣ Assign delivery
        DeliveryAssignment.objects.create(
            order=farmer_order,             # now using farmer.models.Order
            delivery_agent=agent_profile.user  # must be User instance
        )

    cart_items.delete()
    messages.success(request, f"Order placed successfully and assigned to {agent_profile.full_name}.")
    return redirect("buyer:order_history")


@login_required
def order_history(request):
    orders = Order.objects.filter(buyer=request.user).order_by("-created_at")
    return render(request, "buyer/orders.html", {"orders": orders})

@login_required
def buyer_profile_view(request):
    profile, _ = BuyerProfile.objects.get_or_create(user=request.user)
    if request.method == "POST":
        profile.full_name = request.POST.get("full_name", profile.full_name)
        profile.phone_number = request.POST.get("phone_number", profile.phone_number)
        profile.city = request.POST.get("city", profile.city)
        profile.state = request.POST.get("state", profile.state)
        profile.save()
        messages.success(request, "Profile updated successfully.")
    return render(request, "buyer/profile.html", {"profile": profile})
from django.contrib.auth import logout
@login_required
def buyer_logout(request):
    logout(request)
    messages.success(request, "You have been logged out successfully.")
    return redirect("accounts:login")