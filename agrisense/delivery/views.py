# delivery/views.py
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required
from .models import DeliveryAssignment
from django.contrib import messages

@login_required
def delivery_dashboard(request):
    if request.user.role != "delivery":
        messages.error(request, "You are not authorized to access this page.")
        return redirect("accounts:login")

    assignments = DeliveryAssignment.objects.filter(delivery_agent=request.user)
    context = {
        "total_assignments": assignments.count(),
        "pending": assignments.filter(status="pending").count(),
        "delivered": assignments.filter(status="delivered").count(),
    }
    return render(request, "delivery/dashboard.html", context)

@login_required
def my_assignments(request):
    assignments = DeliveryAssignment.objects.filter(delivery_agent=request.user)
    return render(request, "delivery/assignments.html", {"assignments": assignments})

@login_required
def update_assignment_status(request, assignment_id):
    assignment = get_object_or_404(DeliveryAssignment, id=assignment_id, delivery_agent=request.user)
    
    if request.method == "POST":
        status = request.POST.get("status")
        if status in dict(DeliveryAssignment.STATUS_CHOICES):
            assignment.status = status
            assignment.save()
            messages.success(request, f"Assignment #{assignment.id} updated to {status}.")
        else:
            messages.error(request, "Invalid status selected.")
        return redirect("delivery:view_assignments")
    
    return render(request, "delivery/update_assignment_status.html", {
        "assignment": assignment,
        "status_choices": DeliveryAssignment.STATUS_CHOICES
    })

from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from .models import DeliveryAgentProfile  # your delivery agent profile model

@login_required
def delivery_profile_view(request):
    # Ensure only delivery agents access this page
    if request.user.role != "delivery":
        messages.error(request, "You are not authorized to access this page.")
        return redirect("accounts:login")

    # Get or create profile
    profile, _ = DeliveryAgentProfile.objects.get_or_create(user=request.user)

    if request.method == "POST":
        # Update profile fields
        profile.full_name = request.POST.get("full_name", profile.full_name)
        profile.phone_number = request.POST.get("phone_number", profile.phone_number)
        profile.city = request.POST.get("city", profile.city)
        profile.state = request.POST.get("state", profile.state)
        profile.save()
        messages.success(request, "Profile updated successfully!")

    return render(request, "delivery/profile.html", {"profile": profile})
