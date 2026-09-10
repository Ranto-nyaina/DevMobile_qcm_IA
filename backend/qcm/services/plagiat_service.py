from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

def comparer_devoirs(devoirs):
    resultats = []

    for i in range(len(devoirs)):

        for j in range(i + 1, len(devoirs)):

            devoir1 = devoirs[i]
            devoir2 = devoirs[j]

            analyse = analyser_plagiat(
                devoir1.contenu,
                devoir2.contenu
            )

            resultats.append({
                "devoir1_id": devoir1.id,
                "etudiant1": devoir1.etudiant.username,

                "devoir2_id": devoir2.id,
                "etudiant2": devoir2.etudiant.username,

                "similarite": analyse["similarite"],
                "niveau": analyse["niveau"]
            })

    return resultats

def calculer_plagiat(texte1, texte2):

    texte1 = texte1.strip().lower()
    texte2 = texte2.strip().lower()

    if not texte1 or not texte2:
        return 0.0

    textes = [texte1, texte2]

    vectorizer = TfidfVectorizer()

    matrice = vectorizer.fit_transform(textes)

    score = cosine_similarity(
        matrice[0:1],
        matrice[1:2]
    )[0][0]

    return round(score * 100, 2)


def analyser_plagiat(texte1, texte2):

    score = calculer_plagiat(texte1, texte2)

    if score >= 80:
        niveau = "Plagiat très probable"

    elif score >= 60:
        niveau = "Similarité élevée"

    elif score >= 40:
        niveau = "Similarité moyenne"

    else:
        niveau = "Faible similarité"

    return {
        "similarite": score,
        "niveau": niveau
    }