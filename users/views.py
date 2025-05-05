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
    serializer_class = MyTokenObtainPairSerializer # 로그인 시 DB 조회 / 이메일로 사용자 조회(SELECT ... WHERE email=...)를 수행합니다.

class RegisterView(generics.CreateAPIView): # 회원가입 API
    # CreateAPIView는 POST 요청을 처리하는 뷰입니다.
    queryset = MyUser.objects.all()  # MyUser.objects.all()은 DB에서 모든 사용자 정보를 가져옵니다.
    # 하지만 CreateAPIView는 POST 요청을 처리하기 때문에 queryset은 사용되지 않습니다. 필수 속성이라 일단 넣어둡니다.
    serializer_class = RegisterSerializer # 내부서 MyUser.objects.create_user()를 호출해 실제 DB에 회원을 저장합니다
    permission_classes = [AllowAny]

def home(request):
    return HttpResponse("Hello, this is the home page!")