import re

from qcm.models import QCM, Question, Proposition


def generer_qcm(titre, texte, nombre_questions=5):

    phrases = re.split(r"[.!?]+", texte)

    phrases = [
        phrase.strip()
        for phrase in phrases
        if len(phrase.strip()) > 30
    ]

    phrases = phrases[:nombre_questions]

    qcm = QCM.objects.create(
        titre=titre,
        description="QCM généré automatiquement",
        cours=texte
    )

    for phrase in phrases:

        mots = phrase.split()

        if len(mots) < 5:
            continue

        bonne_reponse = mots[-1].strip(",;:")

        question = Question.objects.create(
            qcm=qcm,
            texte=f"Quel élément est mentionné dans cette phrase : {phrase} ?",
            type_question="qcm",
            reponse_correcte=bonne_reponse
        )

        Proposition.objects.create(
            question=question,
            texte=bonne_reponse,
            est_correcte=True
        )

        mauvaises_reponses = [
            "Aucune réponse",
            "Information inconnue",
            "Toutes les réponses",
        ]

        for reponse in mauvaises_reponses:
            Proposition.objects.create(
                question=question,
                texte=reponse,
                est_correcte=False
            )

    return qcm