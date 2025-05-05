# users/serializers.py

from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        data['email'] = self.user.email
        data['first_name'] = self.user.first_name
        data['last_name'] = self.user.last_name
        return data

# serializers.py
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import MyUser

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True) # scync
    first_name = serializers.CharField(required=True)  # 
    last_name = serializers.CharField(required=True)   #

    class Meta:
        model = MyUser # Change this to your custom user model
        fields = ['email', 'password', 'first_name', 'last_name'] # scync
        
    def create(self, validated_data):
        user = MyUser.objects.create_user( # ⭐ DB INSERT 쿼리 실행 / 이메일 중복체크도 실행행
            email=validated_data['email'], # scync
            password=validated_data['password'], #
            first_name=validated_data['first_name'],  #
            last_name=validated_data['last_name']     #
        )
        return user