# Django MySQL 8.0 bug demo

I found that MySQL have some difficulties to run queries in the admin of my main application and I've created this repositoruy to reproduce the issue.

## Steps to reproduce

```sh
python manage.py migrate
python manage.py loaddata data.json
python manage.py createsuperuser
python manage.py runserver
```

With the server running, go to the admin http://127.0.0.1:8000/admin, select Organizations and trigger a search or go directly to http://127.0.0.1:8000/admin/myapp/organization/?q=as. Notice that MySQL will hang indefinitly.

## The models

A simple One to Many using `ForeignKey` field.

```py
class Organization(models.Model):
    name = models.CharField(max_length=255)

class Member(models.Model):
    name = models.CharField(max_length=255)
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, null=True)
```

## The admin generator

This combination of `search_fields` and `annotate` causes the issue when using the built-in search feature of the admin.

```py
class OrganizationAdmin(admin.ModelAdmin):
    search_fields = ["name", "member__name"]
    list_display = ["name", "member_count"]    
    
    class Meta:
        model = models.Organization
        
    def get_queryset(self, request):
        return super().get_queryset(request).annotate(Count("member"))
    
    def member_count(self, instance):
        return instance.member__count
```

## The data

In order to reproduce the problem, the tables just needs a few rows.

```py
org = Organization.objects.create(name=fake.company())
    
for _ in range(500):
    Member.objects.create(name=fake.name(), organization=org)
```

## The SQL

This is the resulting SQL query that the admin makes that crashes MySQL 8.0 (but not MySQL 5.7)

```sql
SELECT
    `myapp_organization`.`id`,
    `myapp_organization`.`name`,
    COUNT(`myapp_member`.`id`) AS `member__count`
FROM
    `myapp_organization`
    LEFT OUTER JOIN `myapp_member` ON (
        `myapp_organization`.`id` = `myapp_member`.`organization_id`
    )
WHERE
    EXISTS(
        SELECT
            1 AS `a`
        FROM
            `myapp_organization` U0
            LEFT OUTER JOIN `myapp_member` U1 ON (U0.`id` = U1.`organization_id`)
            LEFT OUTER JOIN `myapp_member` U2 ON (U0.`id` = U2.`organization_id`)
        WHERE
            (
                (
                    U0.`name` LIKE '%a%'
                    OR U2.`name` LIKE '%a%'
                )
                AND U0.`id` = (`myapp_organization`.`id`)
            )
        GROUP BY
            U0.`id`
        ORDER BY
            NULL
        LIMIT
            1
    )
GROUP BY
    `myapp_organization`.`id`
ORDER BY
    `myapp_organization`.`name` ASC,
    `myapp_organization`.`id` DESC;
```

## The Root Cause

Because of the ForeignKey, the `ChangeList.get_queryset` applies the `ModelAdmin.get_queryset` filters multiple times.

At [this line](https://github.com/django/django/blob/7cc138a58f73c17f07cfaf459ef8e7677ac41ac0/django/contrib/admin/views/main.py#LL584C23-L584C36), the `root_queryset` (which refer to `ModelAdmin.get_queryset`) filters the queryset from `get_search_results` which also contains the result of `ModelAdmin.get_queryset` which puts the `.annotate()` at multiple places in the query (and subqueries).

This build the SQL query above. In MySQL 8.0, with 500 members, the cost of this operation is 500 * 500 * 500 (or 125000000).

## The Solution

Call `.annotate()` on the `ChangeList` queryset using a custom `ChangeList`

```py
class CustomChangeList(ChangeList):
    def get_queryset(self, request):
        return super().get_queryset(request).annotate(Count("member"))
        

class OrganizationAdmin(admin.ModelAdmin):
    search_fields = ["name", "member__name"]
    list_display = ["name", "member_count"]    
    
    class Meta:
        model = models.Organization
    
    def member_count(self, instance):
        return instance.member__count
    
    def get_changelist(self, request, **kwargs):
        return CustomChangeList
```