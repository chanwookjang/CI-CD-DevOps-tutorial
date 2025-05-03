# URLs to access these views:
# - /api/token/ to get the token
# - /api/token/refresh/ to refresh the token

# In your urls.py file, add:

from rest_framework_simplejwt.views import TokenRefreshView
from django.urls import path
from .views import MyTokenObtainPairView, RegisterView
from . import views

urlpatterns = [
    path('', views.home),
    path('api/auth/login/', MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/auth/register/', RegisterView.as_view(), name='register'),
]