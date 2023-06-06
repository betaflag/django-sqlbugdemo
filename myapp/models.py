from django.db import models
    
class Organization(models.Model):
    name = models.CharField(max_length=255)

class Member(models.Model):
    name = models.CharField(max_length=255)
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, null=True)
    