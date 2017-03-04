from rest_framework import serializers
from django.contrib.auth.models import User
from .models import *


class ProfileSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(
                     max_length=30,
                     allow_blank=True,
                     source='user.first_name'
                 )
    last_name = serializers.CharField(
                    max_length=30,
                    allow_blank=True,
                    source='user.last_name'
                )
    class Meta:
        model = Profile
        fields = ('id', 'first_name', 'last_name',
                  'avatar_url')

class MessageSerializer(serializers.ModelSerializer):
    author = serializers.SerializerMethodField(method_name='get_mauthor')
    def get_mauthor(self, post):
        return ProfileSerializer(**{'context': self.context}).to_representation(post.author)
    class Meta:
        model = Message
        fields = '__all__'

class ChatSerializer(serializers.ModelSerializer):
    last_message = serializers.SerializerMethodField(method_name='mget_last_message')
    
    def mget_last_message(self, chat):
        return (MessageSerializer(**{'context': self.context}).
            to_representation(chat[0].messages.
                order_by('-add_time').first()))

    class Meta:
        model = Chat
        fields = ('last_message', 'id')

class UserListSerializer(ProfileSerializer):
    has_chat = serializers.SerializerMethodField()
    chat = serializers.SerializerMethodField()

    def get_chat_ins(self, profile):
        return Chat.objects.filter(users__in=[ profile,
                self.context['request'].user.profile]).first()

    def get_has_chat(self, profile):
        return (ChatSerializer(**{'context': self.context}).
                to_representation(self.get_chat_ins(profile)))

    def get_chat(self, profile):        
        return False

    class Meta:
        model = Profile
        fields = ('id', 'first_name', 'last_name',
                  'avatar_url', 'has_chat', 'chat')


