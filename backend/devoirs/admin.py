from django.contrib import admin

from .models import Devoir, Reponse, AnalysePlagiat


@admin.register(Devoir)
class DevoirAdmin(admin.ModelAdmin):
    list_display = ["id", "titre", "etudiant", "note"]


@admin.register(Reponse)
class ReponseAdmin(admin.ModelAdmin):
    list_display = ["id", "devoir", "question", "note"]


@admin.register(AnalysePlagiat)
class AnalysePlagiatAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "devoir",
        "devoir_compare",
        "pourcentage_similarite",
        "plagiat_detecte",
    ]