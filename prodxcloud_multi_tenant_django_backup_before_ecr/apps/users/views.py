# URLs to access these views:
# - /api/token/ to get the token
# - /api/token/refresh/ to refresh the token

from django.shortcuts import render
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .serializers import RegisterSerializer, MyTokenObtainPairSerializer
from django.urls import path
from rest_framework import generics
from .models import MyUser
from rest_framework.permissions import AllowAny
from django.http import HttpResponse

class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer

class RegisterView(generics.CreateAPIView):
    queryset = MyUser.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]

def home(request):
    return HttpResponse("Hello, this is the home page!")