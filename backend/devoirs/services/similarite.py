from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


def calculer_similarite(texte1, texte2):
    if not texte1.strip() or not texte2.strip():
        return 0.0

    documents = [texte1, texte2]

    vectorizer = TfidfVectorizer()

    matrice = vectorizer.fit_transform(documents)

    score = cosine_similarity(
        matrice[0:1],
        matrice[1:2]
    )[0][0]

    return round(score * 100, 2)