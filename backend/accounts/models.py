from django.db import models
from django.contrib.auth.models import User


NIVEAU_CHOICES = [
    ("L1", "L1"),
    ("L2", "L2"),
    ("L3", "L3"),
    ("M1", "M1"),
    ("M2", "M2"),
]


class ProfilUtilisateur(models.Model):

    ROLE_CHOICES = [
        ("enseignant", "Enseignant"),
        ("etudiant", "Etudiant"),
    ]

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="profil"
    )

    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES
    )

    # Uniquement pertinent pour un étudiant.
    # Un enseignant garde ce champ vide.
    niveau = models.CharField(
        max_length=5,
        choices=NIVEAU_CHOICES,
        blank=True,
        null=True
    )

    def __str__(self):
        if self.role == "etudiant" and self.niveau:
            return f"{self.user.username} - {self.role} ({self.niveau})"
        return f"{self.user.username} - {self.role}"