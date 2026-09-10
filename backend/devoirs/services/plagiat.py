from .similarite import calculer_similarite


SEUIL_PLAGIAT = 70


def detecter_plagiat(texte1, texte2):

    score = calculer_similarite(
        texte1,
        texte2
    )

    plagiat = score >= SEUIL_PLAGIAT

    if score >= 85:
        niveau = "Très élevé"
    elif score >= 70:
        niveau = "Élevé"
    elif score >= 50:
        niveau = "Moyen"
    else:
        niveau = "Faible"

    return {
        "similarite": score,
        "plagiat": plagiat,
        "niveau": niveau
    }