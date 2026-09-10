from rest_framework import serializers
from .models import QCM, Question, Proposition


class PropositionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Proposition
        fields = ["id", "texte", "est_correcte"]


class QuestionSerializer(serializers.ModelSerializer):
    propositions = PropositionSerializer(many=True, read_only=True)

    class Meta:
        model = Question
        fields = [
            "id",
            "texte",
            "type_question",
            "reponse_correcte",
            "propositions",
        ]


class QCMSerializer(serializers.ModelSerializer):
    questions = QuestionSerializer(many=True, read_only=True)

    class Meta:
        model = QCM
        fields = [
            "id",
            "titre",
            "description",
            "cours",
            "niveau",
            "date_creation",
            "questions",
        ]