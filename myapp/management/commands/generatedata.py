from django.core.management.base import BaseCommand
from faker import Faker

from myapp.models import Organization, Member

class Command(BaseCommand):
    help = "Generate app data"


    def handle(self, *args, **options):
        fake = Faker()
        org = Organization.objects.create(name=fake.company())
           
        for _ in range(500):
            Member.objects.create(name=fake.name(), organization=org)
