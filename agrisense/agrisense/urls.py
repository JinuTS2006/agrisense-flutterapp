"""
URL configuration for agrisense project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.shortcuts import redirect
from django.conf import settings
from django.conf.urls.static import static
from accounts.views import home

# urlpatterns = [
#     path('', lambda request: redirect('/accounts/login/')),  # literal path, works 100%
#     path('admin/', admin.site.urls),
#     path('accounts/', include('accounts.urls')),
#     path('farmer/', include('farmer.urls')),
#     path('buyer/', include('buyer.urls')),
#     path('delivery/', include('delivery.urls')),
# ]


urlpatterns = [
    path('', home, name='home'),  # Main landing page
    path('admin/', admin.site.urls),
    path('accounts/', include(('accounts.urls', 'accounts'), namespace='accounts')),
    path('farmer/', include('farmer.urls')),
    path('buyer/', include('buyer.urls',namespace='buyer')),
    path('delivery/', include('delivery.urls')),
    path('admin_panel/', include('admin_panel.urls')),
    
    # API Routes
    path('api/v1/accounts/', include('accounts.api_urls')),
    path('api/v1/farmer/', include('farmer.api_urls')),
    path('api/v1/buyer/', include('buyer.api_urls')),
    path('api/v1/delivery/', include('delivery.api_urls')),
    path('api/v1/admin/', include('admin_panel.api_urls')),
]
from django.views.static import serve
from django.urls import re_path

# Always serve media files (including on Render where DEBUG=False)
urlpatterns += [
    re_path(r'^media/(?P<path>.*)$', serve, {'document_root': settings.MEDIA_ROOT}),
]


