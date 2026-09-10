from django.contrib.auth.models import User

from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

from accounts.models import ProfilUtilisateur

from .models import (
    QCM,
    Devoir,
    QuestionOuverte,
    Proposition,
    Question,
    QuestionDevoir,
    ReponseDevoir,
    NIVEAU_CHOICES
)

from .serializers import QCMSerializer

from .services.generation_qcm import generer_qcm
from .services.pdf_service import extraire_texte_pdf
from .services.correction_service import corriger_reponse

from .services.plagiat_service import (
    analyser_plagiat,
    comparer_devoirs
)


NIVEAUX_VALIDES = [choix[0] for choix in NIVEAU_CHOICES]


# ============================================================
# PROFIL DE L'UTILISATEUR AUTHENTIFIE
# Remplace l'ancien système où user_id/username/role
# étaient envoyés (et donc falsifiables) par le client.
# ============================================================

def get_profil(request):

    try:

        return request.user.profil

    except ProfilUtilisateur.DoesNotExist:

        return None


def verifier_role(request, role_requis):

    profil = get_profil(request)

    if profil is None:

        return Response(
            {
                "error": "Profil utilisateur introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    if profil.role != role_requis:

        return Response(
            {
                "error": (
                    "Accès refusé. "
                    f"Cette fonctionnalité est réservée "
                    f"au rôle : {role_requis}."
                ),
                "role_recu": profil.role,
                "role_requis": role_requis
            },
            status=status.HTTP_403_FORBIDDEN
        )

    return None


# ============================================================
# LISTE DES ETUDIANTS
# ENSEIGNANT UNIQUEMENT
# ============================================================

@api_view(["GET"])
def liste_etudiants(request):

    refus = verifier_role(
        request,
        "enseignant"
    )

    if refus:
        return refus

    etudiants = User.objects.filter(
        profil__role="etudiant"
    ).distinct().order_by("username")

    data = []

    for etudiant in etudiants:

        data.append(
            {
                "id": etudiant.id,
                "username": etudiant.username,
                "email": etudiant.email,
                "niveau": etudiant.profil.niveau,
            }
        )

    return Response(data)


# ============================================================
# DEVOIRS : LISTE
# ============================================================

@api_view(["GET"])
def liste_devoirs(request):

    profil = get_profil(request)

    if profil is None:

        return Response(
            {
                "error": "Profil utilisateur introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    user = request.user
    role = profil.role

    if role == "enseignant":

        devoirs = Devoir.objects.filter(
            enseignant=user
        ).order_by("-date_creation")

        niveau_filtre = request.query_params.get("niveau")

        if niveau_filtre:
            devoirs = devoirs.filter(
                etudiant__profil__niveau=niveau_filtre
            )

    elif role == "etudiant":

        devoirs = Devoir.objects.filter(
            etudiant=user
        ).order_by("-date_creation")

    else:

        return Response(
            {
                "error": "Rôle utilisateur invalide."
            },
            status=status.HTTP_403_FORBIDDEN
        )

    data = []

    for devoir in devoirs:

        nombre_questions = (
            QuestionDevoir.objects
            .filter(devoir=devoir)
            .count()
        )

        data.append(
            {
                "id": devoir.id,
                "enseignant": devoir.enseignant.username,
                "enseignant_id": devoir.enseignant.id,
                "etudiant": devoir.etudiant.username,
                "etudiant_id": devoir.etudiant.id,
                "titre": devoir.titre,
                "contenu": devoir.contenu,
                "date_creation": devoir.date_creation,
                "nombre_questions": nombre_questions,
                "termine": devoir.termine
            }
        )

    return Response(data)


# ============================================================
# CREER DEVOIR
# ENSEIGNANT UNIQUEMENT
# ============================================================

@api_view(["POST"])
def enregistrer_devoir(request):

    refus = verifier_role(
        request,
        "enseignant"
    )

    if refus:
        return refus

    enseignant = request.user

    niveau = request.data.get("niveau")
    titre = request.data.get("titre")
    contenu = request.data.get("contenu", "")
    questions = request.data.get("questions", [])

    if not niveau or not titre:

        return Response(
            {
                "error": "niveau et titre sont obligatoires."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    if niveau not in NIVEAUX_VALIDES:

        return Response(
            {
                "error":
                    "Niveau invalide. Valeurs acceptées : "
                    f"{', '.join(NIVEAUX_VALIDES)}."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    if not questions:

        return Response(
            {
                "error":
                    "Le devoir doit contenir au moins une question."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    etudiants = User.objects.filter(
        profil__niveau=niveau
    )

    if not etudiants.exists():

        return Response(
            {
                "error":
                    f"Aucun étudiant inscrit au niveau {niveau}."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    questions_objets = []

    for question_id in questions:

        try:

            questions_objets.append(
                QuestionOuverte.objects.get(id=question_id)
            )

        except QuestionOuverte.DoesNotExist:

            return Response(
                {
                    "error":
                        f"Question {question_id} introuvable."
                },
                status=status.HTTP_404_NOT_FOUND
            )

    devoirs_crees = []

    for etudiant in etudiants:

        devoir = Devoir.objects.create(
            enseignant=enseignant,
            etudiant=etudiant,
            titre=titre,
            contenu=contenu
        )

        for index, question in enumerate(
            questions_objets,
            start=1
        ):

            QuestionDevoir.objects.create(
                devoir=devoir,
                question=question,
                ordre=index
            )

        devoirs_crees.append(devoir.id)

    return Response(
        {
            "message":
                "Devoir créé avec succès pour le niveau.",

            "niveau": niveau,
            "nombre_etudiants": len(devoirs_crees),
            "devoirs_ids": devoirs_crees,
            "titre": titre,
            "nombre_questions": len(questions_objets)
        },
        status=status.HTTP_201_CREATED
    )


# ============================================================
# SUPPRIMER DEVOIR
# ============================================================

@api_view(["DELETE"])
def supprimer_devoir(request, pk):

    refus = verifier_role(
        request,
        "enseignant"
    )

    if refus:
        return refus

    try:

        devoir = Devoir.objects.get(
            pk=pk
        )

    except Devoir.DoesNotExist:

        return Response(
            {
                "error": "Devoir introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    if devoir.enseignant != request.user:

        return Response(
            {
                "error":
                    "Vous ne pouvez supprimer que "
                    "vos propres devoirs."
            },
            status=status.HTTP_403_FORBIDDEN
        )

    devoir.delete()

    return Response(
        {
            "message": "Devoir supprimé avec succès."
        },
        status=status.HTTP_200_OK
    )


# ============================================================
# DETAIL DEVOIR
# ============================================================

@api_view(["GET"])
def detail_devoir(request, pk):

    profil = get_profil(request)

    if profil is None:

        return Response(
            {
                "error": "Profil utilisateur introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    try:

        devoir = Devoir.objects.get(
            pk=pk
        )

    except Devoir.DoesNotExist:

        return Response(
            {
                "error": "Devoir introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    if profil.role == "etudiant":

        if devoir.etudiant != request.user:

            return Response(
                {
                    "error":
                        "Vous n'avez pas accès à ce devoir."
                },
                status=status.HTTP_403_FORBIDDEN
            )

    elif profil.role == "enseignant":

        if devoir.enseignant != request.user:

            return Response(
                {
                    "error":
                        "Vous n'avez pas accès à ce devoir."
                },
                status=status.HTTP_403_FORBIDDEN
            )

    else:

        return Response(
            {
                "error": "Rôle invalide."
            },
            status=status.HTTP_403_FORBIDDEN
        )

    questions = (
        QuestionDevoir.objects
        .filter(devoir=devoir)
        .order_by("ordre")
    )

    data_questions = []

    for question_devoir in questions:

        question = question_devoir.question

        data_questions.append(
            {
                "id": question.id,
                "ordre": question_devoir.ordre,
                "question": question.question,
                "points": question.points
            }
        )

    return Response(
        {
            "id": devoir.id,
            "enseignant": devoir.enseignant.username,
            "etudiant": devoir.etudiant.username,
            "titre": devoir.titre,
            "contenu": devoir.contenu,
            "date_creation": devoir.date_creation,
            "nombre_questions": len(data_questions),
            "termine": devoir.termine,
            "questions": data_questions
        }
    )


# ============================================================
# REPONDRE DEVOIR
# ============================================================

@api_view(["POST"])
def repondre_devoir(request, pk):

    refus = verifier_role(
        request,
        "etudiant"
    )

    if refus:
        return refus

    etudiant = request.user

    try:

        devoir = Devoir.objects.get(
            pk=pk
        )

    except Devoir.DoesNotExist:

        return Response(
            {
                "error": "Devoir introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    if devoir.etudiant != etudiant:

        return Response(
            {
                "error":
                    "Ce devoir ne vous appartient pas."
            },
            status=status.HTTP_403_FORBIDDEN
        )

    if devoir.termine:

        return Response(
            {
                "error":
                    "Ce devoir est déjà terminé."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    question_id = request.data.get(
        "question_id"
    )

    reponse_etudiant = request.data.get(
        "reponse_etudiant",
        ""
    ).strip()

    if not question_id:

        return Response(
            {
                "error":
                    "question_id est obligatoire."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    if not reponse_etudiant:

        return Response(
            {
                "error":
                    "La réponse ne peut pas être vide."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    try:

        question_devoir = (
            QuestionDevoir.objects.get(
                devoir=devoir,
                question_id=question_id
            )
        )

    except QuestionDevoir.DoesNotExist:

        return Response(
            {
                "error":
                    "Cette question n'appartient "
                    "pas à ce devoir."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    question = question_devoir.question

    resultat = corriger_reponse(
        reponse_etudiant,
        question.reponse_correcte
    )

    score = float(
        resultat.get("score", 0)
    )

    points = float(
        question.points
    )

    note = (
        score / 100
    ) * points

    reponse, created = (
        ReponseDevoir.objects.update_or_create(
            devoir=devoir,
            question=question,
            defaults={
                "reponse_etudiant": reponse_etudiant,
                "score": score,
                "note": round(note, 2),
                "resultat": resultat.get("resultat", ""),
                "niveau": resultat.get("niveau", "")
            }
        )
    )

    return Response(
        {
            "message": "Réponse enregistrée et corrigée.",
            "devoir_id": devoir.id,
            "question_id": question.id,
            "score": reponse.score,
            "note": reponse.note,
            "points": question.points,
            "resultat": reponse.resultat,
            "niveau": reponse.niveau
        }
    )


# ============================================================
# TERMINER DEVOIR
# ============================================================

@api_view(["POST"])
def terminer_devoir(request, pk):

    refus = verifier_role(
        request,
        "etudiant"
    )

    if refus:
        return refus

    etudiant = request.user

    try:

        devoir = Devoir.objects.get(
            pk=pk
        )

    except Devoir.DoesNotExist:

        return Response(
            {
                "error": "Devoir introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    if devoir.etudiant != etudiant:

        return Response(
            {
                "error":
                    "Ce devoir ne vous appartient pas."
            },
            status=status.HTTP_403_FORBIDDEN
        )

    if devoir.termine:

        return Response(
            {
                "error": "Devoir déjà terminé."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    questions = QuestionDevoir.objects.filter(
        devoir=devoir
    )

    reponses = ReponseDevoir.objects.filter(
        devoir=devoir
    )

    points_total = sum(
        float(q.question.points)
        for q in questions
    )

    points_obtenus = sum(
        float(r.note)
        for r in reponses
    )

    if points_total > 0:

        note_finale = (
            points_obtenus / points_total
        ) * 20

    else:

        note_finale = 0

    devoir.termine = True

    devoir.save(
        update_fields=["termine"]
    )

    return Response(
        {
            "message": "Devoir terminé.",
            "devoir_id": devoir.id,
            "etudiant": devoir.etudiant.username,
            "titre": devoir.titre,
            "nombre_questions": questions.count(),
            "questions_repondues": reponses.count(),
            "points_obtenus": round(points_obtenus, 2),
            "points_total": round(points_total, 2),
            "note_finale": round(note_finale, 2)
        }
    )


# ============================================================
# RESULTAT DEVOIR
# ============================================================

@api_view(["GET"])
def resultat_devoir(request, pk):

    profil = get_profil(request)

    if profil is None:

        return Response(
            {
                "error": "Profil utilisateur introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    try:

        devoir = Devoir.objects.get(
            pk=pk
        )

    except Devoir.DoesNotExist:

        return Response(
            {
                "error": "Devoir introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    if profil.role == "etudiant":

        if devoir.etudiant != request.user:

            return Response(
                {
                    "error":
                        "Vous ne pouvez pas consulter "
                        "le résultat d'un autre étudiant."
                },
                status=status.HTTP_403_FORBIDDEN
            )

    elif profil.role == "enseignant":

        if devoir.enseignant != request.user:

            return Response(
                {
                    "error":
                        "Vous ne pouvez pas consulter "
                        "ce devoir."
                },
                status=status.HTTP_403_FORBIDDEN
            )

    else:

        return Response(
            {
                "error": "Rôle invalide."
            },
            status=status.HTTP_403_FORBIDDEN
        )

    questions = (
        QuestionDevoir.objects
        .filter(devoir=devoir)
        .order_by("ordre")
    )

    reponses = ReponseDevoir.objects.filter(
        devoir=devoir
    )

    points_total = sum(
        float(q.question.points)
        for q in questions
    )

    points_obtenus = sum(
        float(r.note)
        for r in reponses
    )

    note_finale = (
        (points_obtenus / points_total) * 20
        if points_total > 0
        else 0
    )

    details = []

    for question_devoir in questions:

        question = question_devoir.question

        try:

            reponse = ReponseDevoir.objects.get(
                devoir=devoir,
                question=question
            )

            details.append(
                {
                    "question_id": question.id,
                    "question": question.question,
                    "points": question.points,
                    "reponse_etudiant": reponse.reponse_etudiant,
                    "reponse_correcte": question.reponse_correcte,
                    "score": reponse.score,
                    "note": reponse.note,
                    "resultat": reponse.resultat,
                    "niveau": reponse.niveau
                }
            )

        except ReponseDevoir.DoesNotExist:

            details.append(
                {
                    "question_id": question.id,
                    "question": question.question,
                    "points": question.points,
                    "reponse_etudiant": "",
                    "reponse_correcte": question.reponse_correcte,
                    "score": 0,
                    "note": 0,
                    "resultat": "Non répondu",
                    "niveau": "Non répondu"
                }
            )

    return Response(
        {
            "devoir_id": devoir.id,
            "etudiant": devoir.etudiant.username,
            "titre": devoir.titre,
            "nombre_questions": questions.count(),
            "questions_repondues": reponses.count(),
            "points_obtenus": round(points_obtenus, 2),
            "points_total": round(points_total, 2),
            "note_finale": round(note_finale, 2),
            "termine": devoir.termine,
            "details": details
        }
    )


# ============================================================
# QUESTIONS OUVERTES
# ENSEIGNANT
# ============================================================

@api_view(["GET"])
def liste_questions_ouvertes(request):

    refus = verifier_role(
        request,
        "enseignant"
    )

    if refus:
        return refus

    questions = (
        QuestionOuverte.objects
        .all()
        .order_by("-id")
    )

    data = []

    for question in questions:

        data.append(
            {
                "id": question.id,
                "question": question.question,
                "points": question.points,
                "date_creation": question.date_creation
            }
        )

    return Response(data)


# ============================================================
# CREER QUESTION OUVERTE
# ENSEIGNANT
# ============================================================

@api_view(["POST"])
def creer_question_ouverte(request):

    refus = verifier_role(
        request,
        "enseignant"
    )

    if refus:
        return refus

    question = request.data.get(
        "question"
    )

    reponse_correcte = request.data.get(
        "reponse_correcte"
    )

    points = request.data.get(
        "points",
        10
    )

    if not question or not reponse_correcte:

        return Response(
            {
                "error":
                    "La question et la réponse "
                    "correcte sont obligatoires."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    try:

        points = float(points)

    except (ValueError, TypeError):

        return Response(
            {
                "error":
                    "Les points doivent être un nombre."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    question_ouverte = (
        QuestionOuverte.objects.create(
            question=question,
            reponse_correcte=reponse_correcte,
            points=points
        )
    )

    return Response(
        {
            "message": "Question créée avec succès.",
            "id": question_ouverte.id,
            "question": question_ouverte.question,
            "points": question_ouverte.points
        },
        status=status.HTTP_201_CREATED
    )


# ============================================================
# SUPPRIMER QUESTION OUVERTE
# ============================================================

@api_view(["DELETE"])
def supprimer_question_ouverte(request, pk):

    refus = verifier_role(
        request,
        "enseignant"
    )

    if refus:
        return refus

    try:

        question = QuestionOuverte.objects.get(
            pk=pk
        )

    except QuestionOuverte.DoesNotExist:

        return Response(
            {
                "error": "Question introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    if QuestionDevoir.objects.filter(
        question=question
    ).exists():

        return Response(
            {
                "error":
                    "Impossible de supprimer cette question : "
                    "elle est utilisée dans au moins un devoir."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    question.delete()

    return Response(
        {
            "message": "Question supprimée avec succès."
        },
        status=status.HTTP_200_OK
    )


# ============================================================
# CORRECTION QUESTION OUVERTE
# ETUDIANT
# ============================================================

@api_view(["POST"])
def corriger_question_ouverte(request):

    refus = verifier_role(
        request,
        "etudiant"
    )

    if refus:
        return refus

    question_id = request.data.get(
        "question_id"
    )

    reponse_etudiant = request.data.get(
        "reponse_etudiant"
    )

    if not question_id or not reponse_etudiant:

        return Response(
            {
                "error":
                    "question_id et "
                    "reponse_etudiant "
                    "sont obligatoires."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    try:

        question = QuestionOuverte.objects.get(
            id=question_id
        )

    except QuestionOuverte.DoesNotExist:

        return Response(
            {
                "error": "Question ouverte introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    resultat = corriger_reponse(
        reponse_etudiant,
        question.reponse_correcte
    )

    note = (
        resultat["score"] / 100
    ) * question.points

    return Response(
        {
            "question": question.question,
            "reponse_etudiant": reponse_etudiant,
            "reponse_correcte": question.reponse_correcte,
            "score": resultat["score"],
            "note": round(note, 2),
            "points": question.points,
            "resultat": resultat["resultat"],
            "niveau": resultat["niveau"]
        }
    )


# ============================================================
# PLAGIAT : TOUS LES DEVOIRS
# ============================================================

@api_view(["GET"])
def analyser_tous_les_devoirs(request):

    refus = verifier_role(
        request,
        "enseignant"
    )

    if refus:
        return refus

    devoirs = Devoir.objects.all()

    if devoirs.count() < 2:

        return Response(
            {
                "message": "Il faut au moins deux devoirs.",
                "resultats": []
            }
        )

    resultats = comparer_devoirs(
        devoirs
    )

    return Response(
        {
            "nombre_devoirs": devoirs.count(),
            "resultats": resultats
        }
    )


# ============================================================
# ANALYSER DEUX TEXTES
# ============================================================

@api_view(["POST"])
def detecter_plagiat(request):

    refus = verifier_role(
        request,
        "enseignant"
    )

    if refus:
        return refus

    texte1 = request.data.get(
        "texte1"
    )

    texte2 = request.data.get(
        "texte2"
    )

    if not texte1 or not texte2:

        return Response(
            {
                "error":
                    "Les deux textes sont obligatoires."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    resultat = analyser_plagiat(
        texte1,
        texte2
    )

    return Response(resultat)


# ============================================================
# SOUMETTRE DEVOIR PLAGIAT
#
# NOTE : cette vue n'avait AUCUNE vérification de rôle avant
# ce changement, et n'est appelée par aucun écran Flutter du
# projet actuel (code mort observé). Avec la config globale
# IsAuthenticated, elle exige désormais d'être connecté (avant,
# elle était accessible sans authentification du tout). Je
# n'ajoute pas de vérification de rôle supplémentaire pour ne
# pas changer son comportement au-delà de l'exigence
# d'authentification imposée par le changement de settings.
# ============================================================

@api_view(["POST"])
def soumettre_devoir_plagiat(request):

    try:

        etudiant_username = request.data.get(
            "etudiant"
        )

        titre = request.data.get(
            "titre",
            ""
        ).strip()

        contenu = request.data.get(
            "contenu",
            ""
        ).strip()

        if not etudiant_username:

            return Response(
                {
                    "error":
                        "Le nom d'utilisateur "
                        "est obligatoire."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if not contenu:

            return Response(
                {
                    "error":
                        "Le contenu du devoir "
                        "est obligatoire."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        try:

            etudiant = User.objects.get(
                username=etudiant_username
            )

        except User.DoesNotExist:

            return Response(
                {
                    "error": "Étudiant introuvable."
                },
                status=status.HTTP_404_NOT_FOUND
            )

        anciens_devoirs = (
            Devoir.objects
            .filter(etudiant=etudiant)
            .exclude(contenu="")
        )

        score_max = 0
        devoir_similaire = None

        for ancien in anciens_devoirs:

            try:

                resultat_comparaison = analyser_plagiat(
                    contenu,
                    ancien.contenu
                )

                score = resultat_comparaison["similarite"]

                if score > score_max:

                    score_max = score
                    devoir_similaire = ancien

            except Exception:

                continue

        devoir = Devoir.objects.create(
            enseignant=etudiant,
            etudiant=etudiant,
            titre=titre or "Devoir sans titre",
            contenu=contenu
        )

        if score_max >= 80:
            resultat = "Plagiat très élevé"
        elif score_max >= 60:
            resultat = "Forte similarité"
        elif score_max >= 40:
            resultat = "Similarité moyenne"
        else:
            resultat = "Aucune similarité importante"

        return Response(
            {
                "message": "Devoir soumis avec succès.",
                "devoir_id": devoir.id,
                "similarite_max": round(score_max, 2),
                "resultat": resultat,
                "devoir_similaire_id": (
                    devoir_similaire.id
                    if devoir_similaire
                    else None
                )
            },
            status=status.HTTP_201_CREATED
        )

    except Exception as e:

        return Response(
            {
                "error": str(e)
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ============================================================
# QCM : LISTE
# - Enseignant : tout par défaut, filtre optionnel ?niveau=
# - Etudiant   : filtré sur son propre niveau (via son profil,
#                jamais falsifiable par le client)
# ============================================================

@api_view(["GET"])
def liste_qcm(request):

    profil = get_profil(request)

    if profil is None:

        return Response(
            {
                "error": "Profil utilisateur introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    qcms = QCM.objects.all().order_by("-date_creation")

    if profil.role == "etudiant":

        if not profil.niveau:

            return Response([])

        qcms = qcms.filter(niveau=profil.niveau)

    elif profil.role == "enseignant":

        niveau_filtre = request.query_params.get("niveau")

        if niveau_filtre:
            qcms = qcms.filter(niveau=niveau_filtre)

    serializer = QCMSerializer(qcms, many=True)

    return Response(serializer.data)


# ============================================================
# QCM : DETAIL
# ============================================================

@api_view(["GET"])
def detail_qcm(request, pk):

    try:

        qcm = QCM.objects.get(
            pk=pk
        )

    except QCM.DoesNotExist:

        return Response(
            {
                "error": "QCM introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    serializer = QCMSerializer(
        qcm
    )

    return Response(
        serializer.data
    )


# ============================================================
# SUPPRIMER QCM
# ============================================================

@api_view(["DELETE"])
def supprimer_qcm(request, pk):

    refus = verifier_role(
        request,
        "enseignant"
    )

    if refus:
        return refus

    try:

        qcm = QCM.objects.get(
            pk=pk
        )

    except QCM.DoesNotExist:

        return Response(
            {
                "error": "QCM introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    qcm.delete()

    return Response(
        {
            "message": "QCM supprimé avec succès."
        },
        status=status.HTTP_200_OK
    )


# ============================================================
# GENERER QCM TEXTE
# ============================================================

@api_view(["POST"])
def generer_qcm_api(request):

    refus = verifier_role(
        request,
        "enseignant"
    )

    if refus:
        return refus

    titre = request.data.get("titre")
    texte = request.data.get("texte")
    niveau = request.data.get("niveau")
    nombre_questions = request.data.get("nombre_questions", 5)

    if not titre or not texte:

        return Response(
            {
                "error":
                    "Le titre et le texte "
                    "sont obligatoires."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    if niveau not in NIVEAUX_VALIDES:

        return Response(
            {
                "error":
                    "Niveau invalide. Valeurs acceptées : "
                    f"{', '.join(NIVEAUX_VALIDES)}."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    try:

        nombre_questions = int(nombre_questions)

        if nombre_questions <= 0:
            raise ValueError()

        qcm = generer_qcm(
            titre=titre,
            texte=texte,
            nombre_questions=nombre_questions
        )

        qcm.niveau = niveau
        qcm.save(update_fields=["niveau"])

        serializer = QCMSerializer(
            qcm
        )

        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED
        )

    except ValueError:

        return Response(
            {
                "error":
                    "Le nombre de questions "
                    "doit être positif."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    except Exception as e:

        return Response(
            {
                "error": str(e)
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ============================================================
# GENERER QCM PDF
# ============================================================

@api_view(["POST"])
def generer_qcm_pdf(request):

    refus = verifier_role(
        request,
        "enseignant"
    )

    if refus:
        return refus

    fichier = request.FILES.get("fichier")

    titre = request.data.get(
        "titre",
        "QCM généré depuis PDF"
    )

    niveau = request.data.get("niveau")

    nombre_questions = request.data.get(
        "nombre_questions",
        5
    )

    if fichier is None:

        return Response(
            {
                "error": "Aucun fichier PDF fourni."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    if not fichier.name:

        return Response(
            {
                "error": "Le nom du fichier est vide."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    if not fichier.name.lower().endswith(".pdf"):

        return Response(
            {
                "error": "Le fichier doit être un PDF."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    if fichier.size == 0:

        return Response(
            {
                "error": "Le fichier PDF est vide."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    if niveau not in NIVEAUX_VALIDES:

        return Response(
            {
                "error":
                    "Niveau invalide. Valeurs acceptées : "
                    f"{', '.join(NIVEAUX_VALIDES)}."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    try:

        nombre_questions = int(nombre_questions)

        if nombre_questions <= 0:

            return Response(
                {
                    "error":
                        "Le nombre de questions doit être positif."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        texte = extraire_texte_pdf(
            fichier
        )

        if not texte:

            return Response(
                {
                    "error":
                        "Impossible d'extraire le texte du PDF."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        qcm = generer_qcm(
            titre=titre,
            texte=texte,
            nombre_questions=nombre_questions
        )

        qcm.niveau = niveau
        qcm.save(update_fields=["niveau"])

        serializer = QCMSerializer(
            qcm
        )

        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED
        )

    except ValueError as e:

        return Response(
            {
                "error": str(e)
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    except Exception as e:

        import traceback
        traceback.print_exc()

        return Response(
            {
                "error": str(e),
                "type": type(e).__name__
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ============================================================
# CORRECTION QCM
# ============================================================

@api_view(["POST"])
def corriger_question_qcm(request):

    refus = verifier_role(
        request,
        "etudiant"
    )

    if refus:
        return refus

    question_id = request.data.get(
        "question_id"
    )

    reponse = request.data.get(
        "reponse"
    )

    if not question_id or reponse is None:

        return Response(
            {
                "error":
                    "question_id et reponse "
                    "sont obligatoires."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    try:

        question = Question.objects.get(
            id=question_id
        )

    except Question.DoesNotExist:

        return Response(
            {
                "error": "Question QCM introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    if question.type_question != "qcm":

        return Response(
            {
                "error":
                    "Cette question n'est pas "
                    "une question QCM."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    reponse_choisie = str(
        reponse
    ).strip()

    proposition = (
        question.propositions
        .filter(texte=reponse_choisie)
        .first()
    )

    if proposition is None:

        return Response(
            {
                "question_id": question.id,
                "reponse": reponse_choisie,
                "correcte": False,
                "score": 0,
                "message": "Proposition invalide."
            }
        )

    correcte = proposition.est_correcte

    return Response(
        {
            "question_id": question.id,
            "reponse": reponse_choisie,
            "correcte": correcte,
            "score": 1 if correcte else 0,
            "message": (
                "Bonne réponse." if correcte else "Mauvaise réponse."
            )
        }
    )