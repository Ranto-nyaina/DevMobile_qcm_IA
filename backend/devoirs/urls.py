from django.urls import path

from .views import (
    corriger_question,
    analyser_plagiat
)


urlpatterns = [
    path(
        "corriger/",
        corriger_question,
        name="corriger_question"
    ),

    path(
        "plagiat/",
        analyser_plagiat,
        name="analyser_plagiat"
    ),
]