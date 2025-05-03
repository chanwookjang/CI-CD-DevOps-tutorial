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

##아래를 myuser model을 쓰도록 수정해야함
from .models import MyUser

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = MyUser # Change this to your custom user model
        fields = ['email', 'password']
        
    def create(self, validated_data):
        user = MyUser.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
        )
        return user