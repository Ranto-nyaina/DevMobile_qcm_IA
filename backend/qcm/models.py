from django.db import models
from django.contrib.auth.models import User


NIVEAU_CHOICES = [
    ("L1", "L1"),
    ("L2", "L2"),
    ("L3", "L3"),
    ("M1", "M1"),
    ("M2", "M2"),
]


# ============================================================
# QUESTION OUVERTE
# ============================================================

class QuestionOuverte(models.Model):

    question = models.TextField()

    reponse_correcte = models.TextField()

    points = models.FloatField(
        default=10
    )

    date_creation = models.DateTimeField(
        auto_now_add=True
    )

    def __str__(self):
        return self.question[:50]


# ============================================================
# DEVOIR
# ============================================================

class Devoir(models.Model):

    enseignant = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="devoirs_crees"
    )

    etudiant = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="devoirs_recus"
    )

    titre = models.CharField(
        max_length=255
    )

    contenu = models.TextField(
        blank=True
    )

    date_creation = models.DateTimeField(
        auto_now_add=True
    )

    termine = models.BooleanField(
        default=False
    )

    def __str__(self):
        return (
            f"{self.titre} - "
            f"{self.etudiant.username}"
        )


# ============================================================
# QUESTION D'UN DEVOIR
# ============================================================

class QuestionDevoir(models.Model):

    devoir = models.ForeignKey(
        Devoir,
        on_delete=models.CASCADE,
        related_name="questions_devoir"
    )

    question = models.ForeignKey(
        QuestionOuverte,
        on_delete=models.CASCADE,
        related_name="devoirs"
    )

    ordre = models.PositiveIntegerField(
        default=1
    )

    class Meta:

        ordering = ["ordre"]

        unique_together = (
            "devoir",
            "question"
        )

    def __str__(self):
        return (
            f"{self.devoir.titre} - "
            f"Question {self.ordre}"
        )


# ============================================================
# REPONSE D'UN ETUDIANT
# ============================================================

class ReponseDevoir(models.Model):

    devoir = models.ForeignKey(
        Devoir,
        on_delete=models.CASCADE,
        related_name="reponses"
    )

    question = models.ForeignKey(
        QuestionOuverte,
        on_delete=models.CASCADE,
        related_name="reponses_devoir"
    )

    reponse_etudiant = models.TextField(
        blank=True
    )

    score = models.FloatField(
        default=0
    )

    note = models.FloatField(
        default=0
    )

    resultat = models.CharField(
        max_length=100,
        blank=True
    )

    niveau = models.CharField(
        max_length=100,
        blank=True
    )

    date_reponse = models.DateTimeField(
        auto_now=True
    )

    class Meta:

        unique_together = (
            "devoir",
            "question"
        )

    def __str__(self):
        return (
            f"{self.devoir.titre} - "
            f"{self.question.question[:30]}"
        )


# ============================================================
# QCM
# ============================================================

class QCM(models.Model):

    titre = models.CharField(
        max_length=200
    )

    description = models.TextField(
        blank=True
    )

    cours = models.TextField(
        blank=True
    )

    niveau = models.CharField(
        max_length=5,
        choices=NIVEAU_CHOICES,
        default="L1"
    )

    date_creation = models.DateTimeField(
        auto_now_add=True
    )

    def __str__(self):
        return self.titre


# ============================================================
# QUESTION QCM
# ============================================================

class Question(models.Model):

    qcm = models.ForeignKey(
        QCM,
        on_delete=models.CASCADE,
        related_name="questions"
    )

    texte = models.TextField()

    type_question = models.CharField(
        max_length=20,
        choices=[
            ("qcm", "QCM"),
            ("ouverte", "Question ouverte"),
        ],
        default="qcm"
    )

    reponse_correcte = models.TextField(
        blank=True
    )

    def __str__(self):
        return self.texte[:80]


# ============================================================
# PROPOSITION QCM
# ============================================================

class Proposition(models.Model):

    question = models.ForeignKey(
        Question,
        on_delete=models.CASCADE,
        related_name="propositions"
    )

    texte = models.CharField(
        max_length=500
    )

    est_correcte = models.BooleanField(
        default=False
    )

    def __str__(self):
        return self.texte