from django.contrib.auth import authenticate
from django.contrib.auth.models import User

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from rest_framework.response import Response
from rest_framework import status

from .models import ProfilUtilisateur
from .serializers import InscriptionSerializer


# ============================================================
# INSCRIPTION
# ============================================================

@api_view(["POST"])
@permission_classes([AllowAny])
def inscription(request):

    serializer = InscriptionSerializer(
        data=request.data
    )

    if not serializer.is_valid():

        return Response(
            {
                "error": "Données invalides.",
                "details": serializer.errors,
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    try:

        user = serializer.save()

        profil = user.profil

        token, _ = Token.objects.get_or_create(user=user)

        return Response(
            {
                "message": "Compte créé avec succès.",
                "token": token.key,
                "user_id": user.id,
                "username": user.username,
                "email": user.email,
                "role": profil.role,
                "niveau": profil.niveau,
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
# CONNEXION
# ============================================================

@api_view(["POST"])
@permission_classes([AllowAny])
def connexion(request):

    email = request.data.get("email")
    password = request.data.get("password")

    if not email or not password:

        return Response(
            {
                "error":
                    "L'email et le mot de passe sont obligatoires."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    try:

        user = User.objects.get(
            email=email
        )

    except User.DoesNotExist:

        return Response(
            {
                "error":
                    "Email ou mot de passe incorrect."
            },
            status=status.HTTP_401_UNAUTHORIZED
        )

    user = authenticate(
        username=user.username,
        password=password
    )

    if user is None:

        return Response(
            {
                "error":
                    "Email ou mot de passe incorrect."
            },
            status=status.HTTP_401_UNAUTHORIZED
        )

    if not user.is_active:

        return Response(
            {
                "error":
                    "Ce compte est désactivé."
            },
            status=status.HTTP_403_FORBIDDEN
        )

    try:

        profil = user.profil

    except ProfilUtilisateur.DoesNotExist:

        return Response(
            {
                "error":
                    "Le profil utilisateur est introuvable."
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

    token, _ = Token.objects.get_or_create(user=user)

    return Response(
        {
            "message": "Connexion réussie.",
            "token": token.key,
            "user_id": user.id,
            "username": user.username,
            "email": user.email,
            "role": profil.role,
            "niveau": profil.niveau,
        },
        status=status.HTTP_200_OK
    )


# ============================================================
# DECONNEXION
# Révoque le token courant. Le client doit ensuite oublier
# le token stocké localement.
# ============================================================

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deconnexion(request):

    try:

        request.user.auth_token.delete()

    except Exception:

        pass

    return Response(
        {
            "message": "Déconnexion réussie."
        },
        status=status.HTTP_200_OK
    )


# ============================================================
# INFORMATIONS UTILISATEUR
# GET  -> récupérer le profil du token en cours
# PUT  -> modifier le profil du token en cours
#
# N'accepte plus username/user_id en paramètre : le profil
# concerné est toujours celui du token, jamais un autre.
# ============================================================

@api_view(["GET", "PUT"])
@permission_classes([IsAuthenticated])
def profil_utilisateur(request):

    user = request.user

    try:

        profil = user.profil

    except ProfilUtilisateur.DoesNotExist:

        return Response(
            {
                "error":
                    "Profil utilisateur introuvable."
            },
            status=status.HTTP_404_NOT_FOUND
        )

    # ========================================================
    # GET
    # ========================================================

    if request.method == "GET":

        return Response(
            {
                "user_id": user.id,
                "username": user.username,
                "email": user.email,
                "role": profil.role,
                "niveau": profil.niveau,
            },
            status=status.HTTP_200_OK
        )

    # ========================================================
    # PUT : MODIFICATION
    # ========================================================

    nouveau_username = (
        request.data.get("username")
        or user.username
    )

    nouvel_email = (
        request.data.get("email")
        or user.email
    )

    ancien_mot_de_passe = request.data.get(
        "ancien_mot_de_passe"
    )

    nouveau_mot_de_passe = request.data.get(
        "nouveau_mot_de_passe"
    )

    confirmation_mot_de_passe = request.data.get(
        "confirmation_mot_de_passe"
    )

    nouveau_username = nouveau_username.strip()

    if not nouveau_username:

        return Response(
            {
                "error":
                    "Le nom d'utilisateur est obligatoire."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    if User.objects.filter(
        username=nouveau_username
    ).exclude(
        id=user.id
    ).exists():

        return Response(
            {
                "error":
                    "Ce nom d'utilisateur est déjà utilisé."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    nouvel_email = nouvel_email.strip()

    if not nouvel_email:

        return Response(
            {
                "error":
                    "L'adresse email est obligatoire."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    if User.objects.filter(
        email=nouvel_email
    ).exclude(
        id=user.id
    ).exists():

        return Response(
            {
                "error":
                    "Cette adresse email est déjà utilisée."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    modification_mot_de_passe = (
        ancien_mot_de_passe is not None
        or nouveau_mot_de_passe is not None
        or confirmation_mot_de_passe is not None
    )

    if modification_mot_de_passe:

        if not ancien_mot_de_passe:

            return Response(
                {
                    "error":
                        "L'ancien mot de passe est obligatoire."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if not nouveau_mot_de_passe:

            return Response(
                {
                    "error":
                        "Le nouveau mot de passe est obligatoire."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if not confirmation_mot_de_passe:

            return Response(
                {
                    "error":
                        "La confirmation du mot de passe est obligatoire."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if not user.check_password(
            ancien_mot_de_passe
        ):

            return Response(
                {
                    "error":
                        "L'ancien mot de passe est incorrect."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if len(nouveau_mot_de_passe) < 6:

            return Response(
                {
                    "error":
                        "Le nouveau mot de passe doit contenir "
                        "au moins 6 caractères."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if (
            nouveau_mot_de_passe
            != confirmation_mot_de_passe
        ):

            return Response(
                {
                    "error":
                        "Les deux nouveaux mots de passe "
                        "ne correspondent pas."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(
            nouveau_mot_de_passe
        )

    user.username = nouveau_username
    user.email = nouvel_email

    user.save()

    return Response(
        {
            "message": "Profil modifié avec succès.",
            "user_id": user.id,
            "username": user.username,
            "email": user.email,
            "role": profil.role,
            "niveau": profil.niveau,
        },
        status=status.HTTP_200_OK
    )