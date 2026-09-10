from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

from qcm.models import Question
from .services.correction import corriger_reponse
from .services.plagiat import detecter_plagiat

@api_view(["POST"])
def analyser_plagiat(request):

    texte1 = request.data.get("texte1")
    texte2 = request.data.get("texte2")

    if not texte1 or not texte2:
        return Response(
            {
                "error": "texte1 et texte2 sont obligatoires."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    resultat = detecter_plagiat(
        texte1,
        texte2
    )

    return Response(resultat)

@api_view(["POST"])
def corriger_question(request):

    question_id = request.data.get("question_id")
    reponse = request.data.get("reponse")

    if not question_id or not reponse:
        return Response(
            {
                "error": "question_id et reponse sont obligatoires."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        question = Question.objects.get(id=question_id)
    except Question.DoesNotExist:
        return Response(
            {"error": "Question introuvable."},
            status=status.HTTP_404_NOT_FOUND
        )

    note, commentaire = corriger_reponse(
        reponse,
        question.reponse_correcte
    )

    return Response({
        "question_id": question.id,
        "reponse": reponse,
        "reponse_correcte": question.reponse_correcte,
        "note": note,
        "commentaire": commentaire
    })