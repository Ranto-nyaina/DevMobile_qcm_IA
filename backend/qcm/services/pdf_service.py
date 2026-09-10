import io

from pypdf import PdfReader


def extraire_texte_pdf(fichier):

    if fichier is None:
        raise ValueError(
            "Aucun fichier PDF reçu."
        )

    # Lire le fichier Django entièrement
    contenu = fichier.read()

    if not contenu:
        raise ValueError(
            "Le fichier PDF reçu est vide."
        )

    # Revenir au début du fichier
    fichier.seek(0)

    try:
        reader = PdfReader(
            io.BytesIO(contenu)
        )

    except Exception as e:
        raise ValueError(
            f"Impossible de lire le PDF : {str(e)}"
        )

    texte = ""

    for page in reader.pages:

        try:
            contenu_page = page.extract_text()

            if contenu_page:
                texte += contenu_page + "\n"

        except Exception:
            continue

    texte = texte.strip()

    if not texte:
        raise ValueError(
            "Le PDF ne contient aucun texte extractible."
        )

    return texte