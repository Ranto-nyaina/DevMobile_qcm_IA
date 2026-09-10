from django.contrib import admin

from .models import (
    QuestionOuverte,
    Devoir,
    QuestionDevoir,
    ReponseDevoir,
    QCM,
    Question,
    Proposition,
)


@admin.register(QuestionOuverte)
class QuestionOuverteAdmin(admin.ModelAdmin):

    list_display = (
        "id",
        "question",
        "points",
        "date_creation",
    )

    search_fields = (
        "question",
        "reponse_correcte",
    )


@admin.register(Devoir)
class DevoirAdmin(admin.ModelAdmin):

    list_display = (
        "id",
        "titre",
        "enseignant",
        "etudiant",
        "date_creation",
    )

    list_filter = (
        "date_creation",
    )

    search_fields = (
        "titre",
        "enseignant__username",
        "etudiant__username",
    )


@admin.register(QuestionDevoir)
class QuestionDevoirAdmin(admin.ModelAdmin):

    list_display = (
        "id",
        "devoir",
        "question",
        "ordre",
    )


@admin.register(ReponseDevoir)
class ReponseDevoirAdmin(admin.ModelAdmin):

    list_display = (
        "id",
        "devoir",
        "question",
        "score",
        "note",
        "niveau",
        "date_reponse",
    )

    list_filter = (
        "niveau",
        "resultat",
    )


@admin.register(QCM)
class QCMAdmin(admin.ModelAdmin):

    list_display = (
        "id",
        "titre",
        "date_creation",
    )

    search_fields = (
        "titre",
        "description",
    )


@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):

    list_display = (
        "id",
        "qcm",
        "texte",
        "type_question",
    )

    list_filter = (
        "type_question",
    )

    search_fields = (
        "texte",
    )


@admin.register(Proposition)
class PropositionAdmin(admin.ModelAdmin):

    list_display = (
        "id",
        "question",
        "texte",
        "est_correcte",
    )

    list_filter = (
        "est_correcte",
    )

    search_fields = (
        "texte",
    )