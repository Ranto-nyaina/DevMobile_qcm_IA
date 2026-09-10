from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


def calculer_similarite(reponse_etudiant, reponse_correcte):

    textes = [
        reponse_etudiant.lower().strip(),
        reponse_correcte.lower().strip()
    ]

    vectorizer = TfidfVectorizer()

    matrice = vectorizer.fit_transform(textes)

    score = cosine_similarity(
        matrice[0:1],
        matrice[1:2]
    )[0][0]

    return round(score * 100, 2)


def corriger_reponse(reponse_etudiant, reponse_correcte):

    score = calculer_similarite(
        reponse_etudiant,
        reponse_correcte
    )

    if score >= 80:
        niveau = "Très bonne réponse"
        resultat = "Correct"

    elif score >= 60:
        niveau = "Bonne réponse"
        resultat = "Partiellement correct"

    elif score >= 40:
        niveau = "Réponse insuffisante"
        resultat = "Partiellement correct"

    else:
        niveau = "Mauvaise réponse"
        resultat = "Incorrect"

    return {
        "score": score,
        "resultat": resultat,
        "niveau": niveau
    }