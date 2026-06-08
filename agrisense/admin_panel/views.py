from django.shortcuts import render
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required
from django.contrib import messages
# Create your views here.
@login_required
def admin_dashboard(request):
    if request.user.role != "admin":
        messages.error(request, "You are not authorized to access this page.")
        return redirect("accounts:login")

    from farmer.models import Product, Order as FarmerOrder
    from buyer.models import Order as BuyerOrder
    from delivery.models import DeliveryAssignment
    from accounts.models import User

    total_users = User.objects.count()
    total_farmers = User.objects.filter(role="farmer").count()
    total_buyers = User.objects.filter(role="buyer").count()
    total_delivery = User.objects.filter(role="delivery").count()
    total_products = Product.objects.count()
    total_orders = BuyerOrder.objects.count()
    pending_deliveries = DeliveryAssignment.objects.filter(status="pending").count()

    context = {
        "total_users": total_users,
        "total_farmers": total_farmers,
        "total_buyers": total_buyers,
        "total_delivery": total_delivery,
        "total_products": total_products,
        "total_orders": total_orders,
        "pending_deliveries": pending_deliveries,
    }
    return render(request, "admin/dashboard.html", context)

@login_required
def admin_users(request):
    if request.user.role != "admin":
        messages.error(request, "Unauthorized access.")
        return redirect("accounts:login")
    from accounts.models import User

    users = User.objects.all().order_by("-date_joined")
    return render(request, "admin/users.html", {"users": users})

@login_required
def admin_edit_user(request, user_id):
    from accounts.models import User
    user = get_object_or_404(User, id=user_id)
    if request.method == "POST":
        user.username = request.POST.get("username", user.username)
        user.email = request.POST.get("email", user.email)
        user.role = request.POST.get("role", user.role)
        user.save()
        messages.success(request, "User updated successfully.")
        return redirect("admin_panel:users")
    return render(request, "admin/edit_user.html", {"user": user})

@login_required
def admin_delete_user(request, user_id):
    from accounts.models import User
    user = get_object_or_404(User, id=user_id)
    user.delete()
    messages.success(request, "User deleted successfully.")
    return redirect("admin_panel:users")
