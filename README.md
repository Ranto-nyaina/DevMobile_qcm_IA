🎓 QCM AI — Plateforme de génération et gestion de QCM assistée par IA

Application mobile/web permettant à des enseignants de générer automatiquement des QCM à partir de contenus de cours (texte ou PDF), de créer des devoirs par niveau académique, et de détecter le plagiat entre les réponses des étudiants. Les étudiants passent les QCM et devoirs correspondant à leur niveau et consultent leurs résultats.


---

🎯 Objectif du projet

La correction manuelle de QCM et de devoirs, et la détection de copies suspectes entre étudiants, représentent une charge de travail importante pour un enseignant, en particulier lorsque le nombre d'étudiants augmente.

Ce projet propose donc une solution qui :

génère automatiquement des QCM à partir d'un texte ou d'un PDF de cours ;

assigne des devoirs à un niveau académique entier, avec suivi individuel ;

corrige automatiquement les réponses et calcule une note sur 20 ;

détecte le plagiat entre les devoirs soumis par similarité de texte ;

filtre automatiquement le contenu vu par chaque étudiant selon son niveau.



---

📌 Problématique

Comment automatiser la génération de QCM à partir de contenus de cours, la correction des devoirs, et la détection de plagiat entre étudiants, tout en conservant un suivi individuel de progression par niveau académique ?


---

🏗️ Architecture du projet

Le projet suit une architecture client/serveur classique :

┌─────────────────────────┐  
                    │   Contenu de cours       │  
                    │   (texte collé ou PDF)   │  
                    └────────────┬─────────────┘  
                                 │  
                                 ▼  
                    ┌─────────────────────────┐  
                    │  Extraction de texte PDF │  
                    │  + génération de QCM     │  
                    │  (backend Django)        │  
                    └────────────┬─────────────┘  
                                 │  
                 ┌───────────────┴───────────────┐  
                 ▼                                ▼  
      ┌─────────────────────┐          ┌─────────────────────┐  
      │  Devoirs assignés    │          │   Détection de       │  
      │  par niveau          │          │   plagiat             │  
      │  (copie individuelle │          │   (TF-IDF + cosinus,  │  
      │   par étudiant)      │          │    scikit-learn)      │  
      └──────────┬───────────┘          └──────────┬───────────┘  
                 │                                  │  
                 └────────────────┬─────────────────┘  
                                  ▼  
                    ┌─────────────────────────┐  
                    │   Django REST Framework  │  
                    │   API REST + SQLite      │  
                    └────────────┬─────────────┘  
                                 │  
                                 ▼  
                    ┌─────────────────────────┐  
                    │   Application Flutter    │  
                    │   (mobile + web)          │  
                    │   Espace enseignant /     │  
                    │   Espace étudiant         │  
                    └─────────────────────────┘


---

🛠️ Technologies utilisées

Frontend

Flutter (mobile + web)

http pour la communication REST

shared_preferences pour la session locale

file_picker pour l'import de PDF


Backend

Django + Django REST Framework

SQLite (développement)

scikit-learn (TF-IDF + similarité cosinus) pour la détection de plagiat

Extraction de texte PDF pour la génération de QCM à partir de documents



---

📁 Structure du projet

qcm-ai/  
│  
├── backend/  
│   ├── accounts/      # gestion des utilisateurs, profils (rôle + niveau), inscription, connexion  
│   ├── qcm/           # logique métier : QCM, devoirs, questions ouvertes, détection de plagiat  
│   ├── manage.py  
│   └── requirements.txt  
│  
└── mobile/  
    └── qcm_app/       # application Flutter, un écran par fonctionnalité  
        └── lib/  
            └── services/  
                └── api_service.dart


---

🔄 Fonctionnalités

👩‍🏫 Espace enseignant

Génération de QCM à partir d'un texte collé ou d'un fichier PDF, pour un niveau donné

Création et gestion de questions ouvertes (banque de questions réutilisable)

Création de devoirs assignés à un niveau académique entier — une copie individuelle est créée automatiquement pour chaque étudiant du niveau, avec suivi de progression et de note indépendant

Consultation, filtrage par niveau et suppression des QCM et devoirs créés

Détection de plagiat entre les devoirs soumis (comparaison deux à deux par similarité TF-IDF)


👨‍🎓 Espace étudiant

Accès aux QCM et devoirs filtrés automatiquement selon son propre niveau (L1 à M2)

Passage de QCM interactif avec correction immédiate

Réponse aux devoirs (questions ouvertes) avec correction automatique et notation sur 20

Tableau de bord personnel : moyenne générale, détail par devoir


🔧 Commun

Inscription avec choix du rôle (enseignant/étudiant) et, pour un étudiant, du niveau académique

Modification du profil (nom, email, mot de passe)



---

🧠 Modèle de données — devoirs par niveau

Un devoir assigné à un niveau n'est pas une ligne unique partagée : le backend crée une copie individuelle du devoir pour chaque étudiant du niveau ciblé, au moment de la création.

Ce choix préserve un suivi de progression et de notation strictement indépendant par étudiant, sans nécessiter de refonte du modèle de réponses existant. C'est un compromis assumé : plus simple à implémenter qu'un modèle relationnel partagé, mais qui duplique la donnée du devoir autant de fois qu'il y a d'étudiants dans le niveau — un point à surveiller si les niveaux comptent plusieurs centaines d'étudiants.


---

🤖 Détection de plagiat

La détection repose sur :

une vectorisation TF-IDF des devoirs soumis ;

un calcul de similarité cosinus entre chaque paire de devoirs (scikit-learn).


Cette approche détecte les similarités textuelles directes (copier-coller, reformulation légère), mais ne détecte pas le plagiat paraphrasé en profondeur ou traduit depuis une autre langue.


---

🚀 Installation

Backend

cd backend  
python -m venv venv  
source venv/bin/activate  # ou venv\Scripts\activate sous Windows  
pip install -r requirements.txt  
  
python manage.py migrate  
python manage.py createsuperuser  
python manage.py runserver

L'API est disponible sur :

http://127.0.0.1:8000/api/

Frontend

cd mobile/qcm_app  
flutter pub get  
flutter run -d chrome

Par défaut, lib/services/api_service.dart pointe vers http://127.0.0.1:8000/api. Pour tester depuis un appareil physique sur le même réseau, remplacer par l'adresse IP locale de la machine hébergeant le backend.


---

⚠️ Limites du projet

Authentification simplifiée : l'application repose sur la transmission de l'identifiant, du nom d'utilisateur et du rôle par le client à chaque requête, sans mécanisme de token ou de session sécurisée. Ce choix convient à un contexte pédagogique/démonstration, mais nécessiterait une authentification par token (DRF TokenAuthentication ou JWT) avant tout déploiement réel — c'est une faille de sécurité, pas un simple détail à corriger plus tard si le projet doit sortir du cadre démonstratif ;

Pas de tests automatisés à ce jour ;

Performance du tableau de bord étudiant : les résultats sont agrégés côté client via plusieurs appels réseau séquentiels ; un endpoint d'agrégation côté serveur serait préférable à grande échelle ;

Détection de plagiat limitée : la similarité TF-IDF ne capture pas la paraphrase profonde ni la traduction ;

Duplication des devoirs par niveau : le modèle de copie individuelle par étudiant simplifie le suivi mais multiplie la donnée stockée.



---

🚀 Perspectives d'amélioration

Sécurité

authentification par token/JWT ;

validation des permissions côté serveur indépendamment des données envoyées par le client.


Qualité

tests unitaires et d'intégration (APITestCase côté Django, tests de widgets côté Flutter) ;

endpoint d'agrégation pour le tableau de bord étudiant ;

pagination des listes (QCM, devoirs, étudiants) pour les gros volumes.


Détection de plagiat

explorer des embeddings sémantiques (au-delà du TF-IDF) pour détecter la paraphrase.



---

📚 Compétences mises en œuvre

Développement mobile/web (Flutter)

Développement backend (Django, Django REST Framework)

Conception d'API REST

Traitement de texte (extraction PDF, TF-IDF, similarité cosinus)

Conception de modèle de données (compromis simplicité / duplication)

Git / GitHub



---

👨‍🎓 Contexte académique

Projet : QCM AI — génération et correction de QCM assistées par IA
Auteur : FANOMEZANTSOA Rantoniaina Harlivah 
Cadre :  ENI, Dev mobile Flutter M1


---

📌 Conclusion

Ce projet propose une chaîne complète Contenu de cours → Génération de QCM → Devoirs par niveau → Correction automatique → Détection de plagiat, avec un espace enseignant et un espace étudiant distincts.

Sa principale limite n'est pas fonctionnelle mais sécuritaire : l'authentification simplifiée est un choix assumé pour un contexte de démonstration, à corriger avant tout déploiement réel.
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
