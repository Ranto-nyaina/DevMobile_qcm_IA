from django.urls import path

from .views import (
    inscription,
    connexion,
    profil_utilisateur,
    deconnexion,
)

from qcm.views import liste_etudiants


urlpatterns = [

    # Inscription
    path(
        "inscription/",
        inscription,
        name="inscription"
    ),

    # Connexion
    path(
        "connexion/",
        connexion,
        name="connexion"
    ),

    # Profil (GET = consulter, PUT = modifier)
    path(
        "profil/",
        profil_utilisateur,
        name="profil_utilisateur"
    ),

    # Liste des étudiants
    path(
        "etudiants/",
        liste_etudiants,
        name="liste_etudiants"
    ),

    #Deconnexion
    path(
        "deconnexion/",
        deconnexion,
        name="deconnexion"
    ),
]