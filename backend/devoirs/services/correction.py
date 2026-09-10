import re


def nettoyer_texte(texte):
    texte = texte.lower()
    texte = re.sub(r"[^\w\s]", "", texte)
    return set(texte.split())


def corriger_reponse(reponse_etudiant, reponse_correcte):
    mots_etudiant = nettoyer_texte(reponse_etudiant)
    mots_corrects = nettoyer_texte(reponse_correcte)

    if not mots_corrects:
        return 0, "Aucune réponse correcte définie."

    mots_communs = mots_etudiant.intersection(mots_corrects)

    score = len(mots_communs) / len(mots_corrects)
    note = round(score * 20, 2)

    if note >= 16:
        commentaire = "Très bonne réponse."
    elif note >= 12:
        commentaire = "Bonne réponse."
    elif note >= 10:
        commentaire = "Réponse acceptable."
    elif note >= 5:
        commentaire = "Réponse partiellement correcte."
    else:
        commentaire = "Réponse insuffisante."

    return note, commentaire