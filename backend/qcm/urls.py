from django.urls import path

from . import views


urlpatterns = [

    # ========================================================
    # ETUDIANT
    # ========================================================

    path(
        "etudiants/",
        views.liste_etudiants,
        name="liste_etudiants"
    ),

    # ========================================================
    # DEVOIRS
    # ========================================================

    path(
        "devoirs/",
        views.liste_devoirs,
        name="liste_devoirs"
    ),

    path(
        "devoirs/creer/",
        views.enregistrer_devoir,
        name="enregistrer_devoir"
    ),

    path(
        "devoirs/<int:pk>/supprimer/",
        views.supprimer_devoir,
        name="supprimer_devoir"
    ),

    path(
        "devoirs/<int:pk>/",
        views.detail_devoir,
        name="detail_devoir"
    ),

    path(
        "devoirs/<int:pk>/repondre/",
        views.repondre_devoir,
        name="repondre_devoir"
    ),

    path(
        "devoirs/<int:pk>/terminer/",
        views.terminer_devoir,
        name="terminer_devoir"
    ),

    path(
        "devoirs/<int:pk>/resultat/",
        views.resultat_devoir,
        name="resultat_devoir"
    ),

    # ========================================================
    # QUESTIONS OUVERTES
    # ========================================================

    path(
        "questions-ouvertes/",
        views.liste_questions_ouvertes,
        name="liste_questions_ouvertes"
    ),

    path(
        "questions-ouvertes/creer/",
        views.creer_question_ouverte,
        name="creer_question_ouverte"
    ),

    path(
        "questions-ouvertes/<int:pk>/supprimer/",
        views.supprimer_question_ouverte,
        name="supprimer_question_ouverte"
    ),

    path(
        "question-ouverte/corriger/",
        views.corriger_question_ouverte,
        name="corriger_question_ouverte"
    ),

    # ========================================================
    # PLAGIAT
    # ========================================================

    path(
        "plagiat/tous/",
        views.analyser_tous_les_devoirs,
        name="plagiat_tous"
    ),

    path(
        "plagiat/",
        views.detecter_plagiat,
        name="detecter_plagiat"
    ),

    path(
        "devoirs/plagiat/",
        views.soumettre_devoir_plagiat,
        name="soumettre_devoir_plagiat"
    ),

    # ========================================================
    # QCM
    # ========================================================

    path(
        "<int:pk>/supprimer/",
        views.supprimer_qcm,
        name="supprimer_qcm"
    ),

    path(
        "<int:pk>/",
        views.detail_qcm,
        name="detail_qcm"
    ),

    path(
        "generer/",
        views.generer_qcm_api,
        name="generer_qcm"
    ),

    path(
        "generer-pdf/",
        views.generer_qcm_pdf,
        name="generer_qcm_pdf"
    ),

    path(
        "question-qcm/corriger/",
        views.corriger_question_qcm,
        name="corriger_question_qcm"
    ),

    path(
        "",
        views.liste_qcm,
        name="liste_qcm"
    ),
]