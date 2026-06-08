from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login
from django.contrib import messages

from django.shortcuts import redirect
from django.contrib.auth import authenticate, login
from django.contrib import messages

def login_view(request):
    if request.method == "POST":
        username = request.POST.get("username")
        password = request.POST.get("password")
        user = authenticate(request, username=username, password=password)

        if user:
            login(request, user)
            # Redirect based on role
            if user.role == "admin":
                return redirect("admin_panel:dashboard")  # <-- your admin dashboard URL
            elif user.role == "farmer":
                return redirect("farmer:dashboard")
            elif user.role == "buyer":
                return redirect("buyer:dashboard")
            elif user.role == "delivery":
                return redirect("delivery:dashboard")
            else:
                messages.error(request, "Invalid user role.")
                return redirect("accounts:login")
        else:
            messages.error(request, "Invalid username or password.")
            return redirect("accounts:login")
    return render(request, "accounts/login.html")



from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login
from django.contrib import messages
from .models import User
from farmer.models import FarmerProfile
from buyer.models import BuyerProfile
from delivery.models import DeliveryAgentProfile

def home(request):
    return render(request, "accounts/home.html")

def register_role(request, role):
    if role not in ["farmer", "buyer", "delivery"]:
        return redirect("accounts:home")  # fallback

    if request.method == "POST":
        username = request.POST.get("username")
        password = request.POST.get("password")
        full_name = request.POST.get("full_name")
        phone_number = request.POST.get("phone_number")
        city = request.POST.get("city")
        state = request.POST.get("state")

        # Check if user exists
        if User.objects.filter(username=username).exists():
            messages.error(request, "Username already taken")
            return redirect(f"/accounts/register/{role}/")

        # CREATE USER AND SAVE ROLE
        user = User.objects.create_user(
            username=username,
            password=password,
            first_name=full_name,
            role=role    # <-- Important: assign the role here
        )
        user.save()

        # CREATE PROFILE BASED ON ROLE
        if role == "farmer":
            FarmerProfile.objects.create(user=user, city=city, state=state)
        elif role == "buyer":
            BuyerProfile.objects.create(user=user, city=city, state=state)
        elif role == "delivery":
            DeliveryAgentProfile.objects.create(user=user, city=city, state=state)

        messages.success(request, f"{role.capitalize()} registration successful! Please login.")
        return redirect("accounts:login")

    return render(request, "accounts/register.html", {"role": role})
