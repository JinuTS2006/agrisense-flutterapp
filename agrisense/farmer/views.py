from django.shortcuts import render
from django.contrib.auth.decorators import login_required
import requests
import pandas as pd
import os
from ml_module.crop_recommendation import recommend_top_crops
from ml_module.yield_prediction import predict_yield, MODEL_FILE, pickle
from farmer.models import FarmerProfile
from django.shortcuts import render
from django.contrib import messages
from ml_module.yield_prediction import predict_yield
from .models import FarmerProfile
from django.shortcuts import render
from farmer.models import FarmerProfile
from ml_module.yield_prediction import predict_yield
from ml_module.weather import get_weather_for_city
from farmer.models import FarmerProfile
from ml_module.crop_recommendation import recommend_top_crops
# Load historical weather dataset once
weather_df = pd.read_csv("ml_module/data/state_weather_data_1997_2020.csv")

#@login_required
# def farmer_dashboard(request):
#     profile, _ = FarmerProfile.objects.get_or_create(
#         user=request.user,
#         defaults={"city": "Bangalore", "state": "Karnataka"}
#     )
#     return render(request, "farmer/dashboard.html", {
#         "city": profile.city
#     })

# Authorization decorator (optional)
def farmer_required(view_func):
    def wrapper(request, *args, **kwargs):
        if request.user.is_authenticated and getattr(request.user, "role", None) == "farmer":
            return view_func(request, *args, **kwargs)
        else:
            messages.error(request, "You are not authorized to access this page.")
            return redirect("accounts:login")
    return wrapper
@login_required
def farmer_home(request):
    # Optional: check if the logged-in user is actually a farmer
    if request.user.role != "farmer":
        messages.error(request, "You are not authorized to access this page.")
        return redirect("accounts:login")
    
    return render(request, "farmer/home.html")


@login_required
def crop_recommendation(request):
    profile, _ = FarmerProfile.objects.get_or_create(
        user=request.user,
        defaults={"city": "Bangalore", "state": "Karnataka"}
    )

    city = profile.city
    state = profile.state

    # Default inputs
    default_inputs = {
        "N": 90,
        "P": 42,
        "K": 43,
        "ph": 6.5
    }

    # Weather defaults
    weather = {
        "temperature": 25,
        "humidity": 50,
        "rainfall": 0
    }

    # Live weather
    try:
        API_KEY = "REDACTED_API_KEY"
        url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={API_KEY}&units=metric"
        res = requests.get(url, timeout=5).json()

        weather["temperature"] = res["main"]["temp"]
        weather["humidity"] = res["main"]["humidity"]
        weather["rainfall"] = res.get("rain", {}).get("1h", 0)
    except:
        pass

    # Historical rainfall fallback
    state_rain = weather_df.loc[
        weather_df["state"] == state, "total_rainfall_mm"
    ]
    if not state_rain.empty:
        weather["rainfall"] = state_rain.mean()

    recommended_crops = None

    if request.method == "POST":
        try:
            N = float(request.POST.get("N", default_inputs["N"]))
            P = float(request.POST.get("P", default_inputs["P"]))
            K = float(request.POST.get("K", default_inputs["K"]))
            ph = float(request.POST.get("ph", default_inputs["ph"]))
        except ValueError:
            N, P, K, ph = default_inputs.values()

        input_features = {
            "N": N,
            "P": P,
            "K": K,
            "temperature": weather["temperature"],
            "humidity": weather["humidity"],
            "ph": ph,
            "rainfall": weather["rainfall"]
        }

        top_crops = recommend_top_crops(input_features, top_n=3)

        recommended_crops = [
            {"crop": crop, "probability": round(prob * 100, 2)}
            for crop, prob in top_crops
        ]

    return render(request, "farmer/recommendation.html", {
        "farmer_profile": profile,
        "weather": weather,
        "default_inputs": default_inputs,
        "recommended_crops": recommended_crops
    })




@login_required


# Function to fetch weather for a city
def get_weather_for_city(city):
    API_KEY = "YOUR_OPENWEATHER_API_KEY"  # Replace with your key
    try:
        url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={API_KEY}&units=metric"
        res = requests.get(url).json()
        weather = {
            "avg_temp_c": res["main"]["temp"],
            "avg_humidity_percent": res["main"]["humidity"],
            "total_rainfall_mm": res.get("rain", {}).get("1h", 0)
        }
        return weather
    except:
        return {"avg_temp_c": 25, "avg_humidity_percent": 50, "total_rainfall_mm": 0}


@login_required
def yield_prediction_view(request):
    user = request.user
    profile, _ = FarmerProfile.objects.get_or_create(
        user=user, defaults={"city": "Bangalore", "state": "Karnataka"}
    )

    predicted_yield = None
    crop_list = []

    # Load model and label encoder
    try:
        with open(MODEL_FILE, "rb") as f:
            model, le = pickle.load(f)
        crop_list = le.classes_
    except Exception as e:
        print("Error loading yield model:", e)

    if request.method == "POST":
        try:
            # Get inputs safely, fallback defaults if missing
            N = float(request.POST.get("N", 90))
            P = float(request.POST.get("P", 42))
            K = float(request.POST.get("K", 43))
            pH = float(request.POST.get("pH", 6.5))
            crop_name = request.POST.get("crop")

            # Fetch weather automatically
            city = profile.city
            API_KEY = "REDACTED_API_KEY"
            weather = {"avg_temp_c": 25, "avg_humidity_percent": 50, "total_rainfall_mm": 0}
            try:
                url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={API_KEY}&units=metric"
                res = requests.get(url).json()
                weather["avg_temp_c"] = res["main"]["temp"]
                weather["avg_humidity_percent"] = res["main"]["humidity"]
                weather["total_rainfall_mm"] = res.get("rain", {}).get("1h", 0)
            except:
                pass

            input_data = {
                "N": N,
                "P": P,
                "K": K,
                "pH": pH,
                "avg_temp_c": weather["avg_temp_c"],
                "avg_humidity_percent": weather["avg_humidity_percent"],
                "total_rainfall_mm": weather["total_rainfall_mm"]
            }

            # Predict yield
            predicted_yield = predict_yield(crop_name, input_data)

        except Exception as e:
            print("Error predicting yield:", e)
            predicted_yield = None

    return render(request, "farmer/yield.html", {
        "farmer_profile": profile,
        "predicted_yield": predicted_yield,
        "crop_list": crop_list
    })


from ml_module.profit_analysis import calculate_profit
from ml_module.yield_prediction import predict_yield
from farmer.models import FarmerProfile
from django.contrib.auth.decorators import login_required
from django.shortcuts import render

from django.contrib import messages

@login_required
def profit_analysis_view(request):
    profit_result = None

    price_df = pd.read_csv("ml_module/data/crop_price_state.csv")

    states = sorted(price_df["state"].unique())
    crop_list = sorted(price_df["crop"].unique())

    if request.method == "POST":
        try:
            state = request.POST.get("state")
            crop = request.POST.get("crop").strip().lower()
            area = float(request.POST.get("area"))
            predicted_yield = float(request.POST.get("yield"))

            price_df["crop"] = price_df["crop"].str.lower()

            row = price_df[
                (price_df["state"] == state) &
                (price_df["crop"] == crop)
            ]

            if row.empty:
                messages.error(
                    request,
                    "Price data not available for this crop in the selected state."
                )
            else:
                price_per_tonne = float(row.iloc[0]["avg_price_per_tonne"])
                cost_per_ha = float(row.iloc[0]["avg_cost_per_ha"])

                total_yield = predicted_yield * area
                revenue = total_yield * price_per_tonne
                cost = cost_per_ha * area
                profit = revenue - cost

                profit_result = {
                    "total_yield": total_yield,
                    "price": price_per_tonne,
                    "revenue": revenue,
                    "cost": cost,
                    "profit": profit
                }

        except Exception as e:
            messages.error(request, "Invalid input. Please check all fields.")
            print("Profit Analysis Error:", e)

    return render(request, "farmer/profit.html", {
        "profit_result": profit_result,
        "states": states,
        "crop_list": crop_list
    })

from django.contrib.auth.decorators import login_required
from django.contrib import messages
from .models import FarmerProfile
from .forms import FarmerProfileForm

@login_required
def farmer_profile_view(request):
    profile, _ = FarmerProfile.objects.get_or_create(
        user=request.user,
        defaults={
            "email": request.user.email,
            "city": "",
            "state": ""
        }
    )

    if request.method == "POST":
        form = FarmerProfileForm(request.POST, instance=profile)
        if form.is_valid():
            form.save()
            messages.success(request, "Profile updated successfully.")
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = FarmerProfileForm(instance=profile)

    return render(request, "farmer/profile.html", {
        "form": form
    })
from django.shortcuts import redirect
from django.contrib import messages

def ensure_profile_complete(request):
    profile = FarmerProfile.objects.filter(user=request.user).first()

    if not profile or not profile.state or not profile.city:
        messages.warning(
            request,
            "Please complete your profile (state and city) before using this feature."
        )
        return redirect("farmer_profile")

    return None

from .forms import ProductForm
from .models import Product

@login_required
def add_product(request):
    if request.method == "POST":
        form = ProductForm(request.POST, request.FILES)
        if form.is_valid():
            product = form.save(commit=False)
            product.farmer = request.user
            product.save()
            messages.success(request, "Product listed successfully.")
            return redirect("farmer:my_products")
    else:
        form = ProductForm()

    return render(request, "farmer/add_product.html", {"form": form})


@login_required
def my_products(request):
    products = Product.objects.filter(farmer=request.user).order_by("-created_at")
    return render(request, "farmer/my_products.html", {"products": products})

from django.shortcuts import get_object_or_404, redirect
@login_required
def edit_product(request, product_id):
    product = get_object_or_404(Product, id=product_id, farmer=request.user)

    if request.method == "POST":
        form = ProductForm(request.POST, request.FILES, instance=product)
        if form.is_valid():
            form.save()
            messages.success(request, "Product updated successfully.")
            return redirect("farmer:my_products")
    else:
        form = ProductForm(instance=product)

    return render(request, "farmer/edit_product.html", {
        "form": form,
        "product": product
    })
@login_required
def delete_product(request, product_id):
    product = get_object_or_404(Product, id=product_id, farmer=request.user)

    if request.method == "POST":
        product.delete()
        messages.success(request, "Product deleted successfully.")
        return redirect("farmer:my_products")

    return render(request, "farmer/delete_product.html", {
        "product": product
    })

from django.contrib.auth.decorators import login_required
from django.shortcuts import render, get_object_or_404, redirect
from .models import Order
from django.contrib import messages
from farmer.models import Order

@login_required
def farmer_orders(request):
    # Only allow farmers
    if request.user.role != "farmer":
        messages.error(request, "You are not authorized to access this page.")
        return redirect("accounts:login")
    
    orders = Order.objects.filter(product__farmer=request.user).order_by("-created_at")
    return render(request, "farmer/orders.html", {"orders": orders})


@login_required
def update_order_status(request, order_id):
    order = get_object_or_404(Order, id=order_id, product__farmer=request.user)
    
    if request.method == "POST":
        new_status = request.POST.get("status")
        if new_status in dict(Order.STATUS_CHOICES):
            order.status = new_status
            order.save()
            messages.success(request, f"Order #{order.id} status updated to {new_status}.")
        else:
            messages.error(request, "Invalid status selected.")
        return redirect("farmer:farmer_orders")
    
    return render(request, "farmer/update_order_status.html", {"order": order, "status_choices": Order.STATUS_CHOICES})
