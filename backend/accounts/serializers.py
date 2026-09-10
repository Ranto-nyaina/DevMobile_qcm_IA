from django.contrib.auth.models import User
from rest_framework import serializers

from .models import ProfilUtilisateur, NIVEAU_CHOICES


class InscriptionSerializer(serializers.Serializer):

    username = serializers.CharField(
        max_length=150,
        required=True
    )

    password = serializers.CharField(
        write_only=True,
        min_length=4,
        required=True
    )

    email = serializers.EmailField(
        required=True
    )

    role = serializers.ChoiceField(
        choices=[
            ("enseignant", "Enseignant"),
            ("etudiant", "Étudiant"),
        ],
        required=True
    )

    niveau = serializers.ChoiceField(
        choices=NIVEAU_CHOICES,
        required=False,
        allow_null=True
    )

    def validate_username(self, value):

        value = value.strip()

        if not value:
            raise serializers.ValidationError(
                "Le nom d'utilisateur est obligatoire."
            )

        if User.objects.filter(
            username__iexact=value
        ).exists():

            raise serializers.ValidationError(
                "Ce nom d'utilisateur existe déjà."
            )

        return value

    def validate_email(self, value):

        value = value.strip().lower()

        if User.objects.filter(
            email__iexact=value
        ).exists():

            raise serializers.ValidationError(
                "Cette adresse email existe déjà."
            )

        return value

    def validate(self, data):

        role = data.get("role")
        niveau = data.get("niveau")

        if role == "etudiant" and not niveau:
            raise serializers.ValidationError(
                {
                    "niveau":
                        "Le niveau est obligatoire pour un étudiant."
                }
            )

        return data

    def create(self, validated_data):

        username = validated_data["username"]
        password = validated_data["password"]
        email = validated_data["email"]
        role = validated_data["role"]

        # Un enseignant n'a pas de niveau, même s'il en a
        # envoyé un par erreur.
        niveau = (
            validated_data.get("niveau")
            if role == "etudiant"
            else None
        )

        user = User.objects.create_user(
            username=username,
            password=password,
            email=email
        )

        ProfilUtilisateur.objects.create(
            user=user,
            role=role,
            niveau=niveau
        )

        return user


class ConnexionSerializer(serializers.Serializer):

    username = serializers.CharField(
        required=True
    )

    password = serializers.CharField(
        write_only=True,
        required=True
    )