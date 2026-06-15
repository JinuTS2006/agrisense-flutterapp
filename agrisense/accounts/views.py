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

def diagnose_server(request):
    import subprocess, os, sys
    from django.http import HttpResponse
    
    output = []
    
    # 1. Python version
    output.append(f"Python Version: {sys.version}")
    
    # 2. Check api_views.py
    try:
        import hashlib
        # Try both paths just in case
        for p in ["agrisense/buyer/api_views.py", "buyer/api_views.py"]:
            if os.path.exists(p):
                with open(p, "rb") as f:
                    h = hashlib.md5(f.read()).hexdigest()
                output.append(f"api_views.py MD5 ({p}): {h}")
                with open(p, "r", encoding="utf-8") as f:
                    content = f.read()
                output.append(f"Has signing: {'signing' in content}")
                output.append(f"Has CheckoutSession: {'CheckoutSession' in content}")
                break
    except Exception as e:
        output.append(f"Error reading api_views.py: {e}")

        
    # 3. Run showmigrations
    try:
        from django.core.management import call_command
        from io import StringIO
        out = StringIO()
        call_command("showmigrations", stdout=out)
        output.append(f"Migrations:\n{out.getvalue()}")
    except Exception as e:
        output.append(f"Showmigrations failed: {e}")
        
    # 4. Check for error logs
    try:
        output.append(f"CWD: {os.getcwd()}")
        output.append(f"CWD contents: {os.listdir('.')}")
        log_paths = ["django_error_log.txt", "agrisense/django_error_log.txt"]
        found = False
        for lp in log_paths:
            if os.path.exists(lp):
                with open(lp, "r", encoding="utf-8") as f:
                    err_content = f.read()
                output.append(f"Error Log ({lp}):\n{err_content}")
                found = True
                break
        if not found:
            output.append("No error log file found.")
    except Exception as e:
        output.append(f"Error reading error logs: {e}")
        
    return HttpResponse("\n\n".join(output), content_type="text/plain")


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
