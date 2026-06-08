from django.db import models

# Create your models here.
from django.db import models
from django.conf import settings

class AdminProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    full_name = models.CharField(max_length=200, blank=True)
    phone_number = models.CharField(max_length=20, blank=True)
    
    def __str__(self):
        return self.user.username
