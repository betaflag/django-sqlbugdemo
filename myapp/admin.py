from django.contrib import admin
from django.db.models import Count

from myapp import models     

class OrganizationAdmin(admin.ModelAdmin):
    search_fields = ["name", "member__name"]
    list_display = ["name", "member_count"]    
    
    class Meta:
        model = models.Organization
        
    def get_queryset(self, request):
        return super().get_queryset(request).annotate(Count("member"))
    
    def member_count(self, instance):
        return instance.member__count
    

admin.site.register(models.Member)
admin.site.register(models.Organization, OrganizationAdmin)
