# QCM AI — Plateforme de génération et gestion de QCM assistée par IA

Application mobile/web permettant à des enseignants de générer automatiquement des QCM à partir de contenus de cours (texte ou PDF), de créer des devoirs par niveau académique, et de détecter le plagiat entre les réponses des étudiants. Les étudiants passent les QCM et devoirs correspondant à leur niveau et consultent leurs résultats.

## Stack technique

**Frontend**
- Flutter (mobile + web)
- `http` pour la communication REST
- `shared_preferences` pour la session locale
- `file_picker` pour l'import de PDF

**Backend**
- Django + Django REST Framework
- SQLite (développement)
- `scikit-learn` (TF-IDF + similarité cosinus) pour la détection de plagiat
- Extraction de texte PDF pour la génération de QCM à partir de documents

## Fonctionnalités

### Espace enseignant
- Génération de QCM à partir d'un texte collé ou d'un fichier PDF, pour un niveau donné
- Création et gestion de questions ouvertes (banque de questions réutilisable)
- Création de devoirs assignés à un niveau académique entier (une copie individuelle est créée automatiquement pour chaque étudiant du niveau, avec suivi de progression et de note indépendant)
- Consultation, filtrage par niveau et suppression des QCM et devoirs créés
- Détection de plagiat entre les devoirs soumis (comparaison deux à deux par similarité TF-IDF)

### Espace étudiant
- Accès aux QCM et devoirs filtrés automatiquement selon son propre niveau (L1 à M2)
- Passage de QCM interactif avec correction immédiate
- Réponse aux devoirs (questions ouvertes) avec correction automatique et notation sur 20
- Tableau de bord personnel : moyenne générale, détail par devoir

### Commun
- Inscription avec choix du rôle (enseignant/étudiant) et, pour un étudiant, du niveau académique
- Modification du profil (nom, email, mot de passe)

## Architecture

Le projet suit une architecture client/serveur classique :

- **`backend/accounts/`** — gestion des utilisateurs, profils (rôle + niveau), inscription, connexion
- **`backend/qcm/`** — logique métier : QCM, devoirs, questions ouvertes, détection de plagiat
- **`mobile/qcm_app/`** — application Flutter, un écran par fonctionnalité, communication via `ApiService`

### Modèle de données — devoirs par niveau

Un devoir assigné à un niveau n'est pas une ligne unique partagée : le backend crée une copie individuelle du devoir pour chaque étudiant du niveau ciblé au moment de la création. Ce choix préserve un suivi de progression et de notation strictement indépendant par étudiant, sans nécessiter de refonte du modèle de réponses existant.

## Installation

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # ou venv\Scripts\activate sous Windows
pip install -r requirements.txt

python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

L'API est disponible sur `http://127.0.0.1:8000/api/`.

### Frontend

```bash
cd mobile/qcm_app
flutter pub get
flutter run -d chrome
```

Par défaut, `lib/services/api_service.dart` pointe vers `http://127.0.0.1:8000/api`. Pour tester depuis un appareil physique sur le même réseau, remplacer par l'adresse IP locale de la machine hébergeant le backend.

## Limites connues

- **Authentification simplifiée** : l'application repose sur la transmission de l'identifiant, du nom d'utilisateur et du rôle par le client à chaque requête, sans mécanisme de token ou de session sécurisée. Ce choix convient à un contexte pédagogique/démonstration, mais nécessiterait une authentification par token (DRF `TokenAuthentication` ou JWT) avant tout déploiement réel.
- **Pas de tests automatisés** à ce jour.
- **Performance du tableau de bord étudiant** : les résultats sont agrégés côté client via plusieurs appels réseau séquentiels ; un endpoint d'agrégation côté serveur serait préférable à grande échelle.

## Pistes d'amélioration

- Authentification par token/JWT
- Tests unitaires et d'intégration (`APITestCase` côté Django, tests de widgets côté Flutter)
- Endpoint d'agrégation pour le tableau de bord étudiant
- Pagination des listes (QCM, devoirs, étudiants) pour les gros volumes

## Auteur

[Ton nom]
Projet réalisé dans le cadre de [contexte — ENI, Dev mobile M1, etc.]
