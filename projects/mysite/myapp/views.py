from django.shortcuts import render
from django.http import HttpResponse

def home(request):
    return HttpResponse("Hello Prometheus! version 1111111111111 project")

# Create your views here.
