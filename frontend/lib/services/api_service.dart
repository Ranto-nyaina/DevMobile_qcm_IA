import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ==========================================================
  // URL API
  // ==========================================================

  static const String baseUrl =
      "http://127.0.0.1:8000/api";

  // ==========================================================
  // UTILITAIRE REPONSE
  // ==========================================================

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        "error": response.body,
      };
    } catch (_) {
      return {
        "error": response.body,
      };
    }
  }

  // ==========================================================
  // TOKEN / HEADERS
  // ==========================================================

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// En-têtes pour requêtes authentifiées JSON.
  /// Lève une exception explicite si aucun token n'est stocké,
  /// plutôt que de laisser le serveur renvoyer un 401 opaque.
  static Future<Map<String, String>> _headersAuth() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Token $token",
    };
  }

  /// En-tête d'autorisation seul (pour requêtes multipart,
  /// où Content-Type est géré par http.MultipartRequest).
  static Future<Map<String, String>> _headerAuthSeul() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return {
      "Authorization": "Token $token",
    };
  }

  // ==========================================================
  // SESSION
  // ==========================================================

  static Future<Map<String, dynamic>?>
      getUtilisateurConnecte() async {
    final prefs =
        await SharedPreferences.getInstance();

    final userId = prefs.getInt("user_id");
    final username = prefs.getString("username");
    final email = prefs.getString("email");
    final role = prefs.getString("role");
    final token = prefs.getString("token");

    if (userId == null ||
        username == null ||
        role == null ||
        token == null) {
      return null;
    }

    return {
      "user_id": userId,
      "username": username,
      "email": email ?? "",
      "role": role,
    };
  }

  static Future<bool> estConnecte() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString("token") != null &&
        prefs.getInt("user_id") != null &&
        prefs.getString("username") != null &&
        prefs.getString("role") != null;
  }

  static Future<String?> getRole() async {
    final prefs =
        await SharedPreferences.getInstance();
    return prefs.getString("role");
  }

  static Future<String?> getUsername() async {
    final prefs =
        await SharedPreferences.getInstance();
    return prefs.getString("username");
  }

  static Future<int?> getUserId() async {
    final prefs =
        await SharedPreferences.getInstance();
    return prefs.getInt("user_id");
  }

  static Future<Map<String, String>>
      getInformationsUtilisateur() async {
    final prefs =
        await SharedPreferences.getInstance();

    return {
      "username": prefs.getString("username") ?? "",
      "role": prefs.getString("role") ?? "",
    };
  }

  /// Enregistre la session locale à partir de la réponse
  /// d'inscription ou de connexion (qui contient toujours
  /// un token désormais).
  static Future<void> _enregistrerSession(
    Map<String, dynamic> body,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    if (body["token"] != null) {
      await prefs.setString("token", body["token"].toString());
    }

    if (body["user_id"] != null) {
      await prefs.setInt(
        "user_id",
        int.parse(body["user_id"].toString()),
      );
    }

    if (body["username"] != null) {
      await prefs.setString("username", body["username"].toString());
    }

    if (body["email"] != null) {
      await prefs.setString("email", body["email"].toString());
    }

    if (body["role"] != null) {
      await prefs.setString("role", body["role"].toString());
    }
  }

  // ==========================================================
  // DECONNEXION
  // Révoque le token côté serveur, puis nettoie la session
  // locale dans tous les cas (même si l'appel réseau échoue,
  // pour ne jamais laisser l'utilisateur bloqué connecté
  // localement sans pouvoir agir).
  // ==========================================================

  static Future<void> deconnexion() async {
    try {
      final headers = await _headersAuth();

      await http.post(
        Uri.parse("$baseUrl/accounts/deconnexion/"),
        headers: headers,
      );
    } catch (_) {
      // Token déjà absent/invalide : rien à révoquer côté serveur.
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("token");
    await prefs.remove("user_id");
    await prefs.remove("username");
    await prefs.remove("email");
    await prefs.remove("role");
  }

  // ==========================================================
  // INSCRIPTION
  // ==========================================================

  static Future<Map<String, dynamic>> inscrire({
    required String username,
    required String email,
    required String password,
    required String role,
    String? niveau,
  }) async {
    final Map<String, dynamic> donnees = {
      "username": username,
      "email": email,
      "password": password,
      "role": role,
    };

    if (role == "etudiant" && niveau != null) {
      donnees["niveau"] = niveau;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/accounts/inscription/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(donnees),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      await _enregistrerSession(body);
      return body;
    }

    throw Exception(
      body["error"] ??
          body["detail"] ??
          "Erreur lors de l'inscription.",
    );
  }

  // ==========================================================
  // CONNEXION
  // ==========================================================

  static Future<Map<String, dynamic>> connexion({
    required String email,
    required String motDePasse,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/accounts/connexion/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": motDePasse,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body["error"] ??
            body["detail"] ??
            "Email ou mot de passe incorrect.",
      );
    }

    if (body["token"] == null ||
        body["user_id"] == null ||
        body["username"] == null ||
        body["role"] == null) {
      throw Exception("Réponse de connexion invalide.");
    }

    await _enregistrerSession(body);

    return body;
  }

  // ==========================================================
  // PROFIL
  // Ne dépend plus de user_id : le serveur identifie
  // l'utilisateur via le token.
  // ==========================================================

  static Future<Map<String, dynamic>>
      getProfilUtilisateur() async {
    final headers = await _headersAuth();

    final response = await http.get(
      Uri.parse("$baseUrl/accounts/profil/"),
      headers: headers,
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      await _enregistrerSession(body);
      return body;
    }

    throw Exception(
      body["error"] ??
          body["detail"] ??
          "Impossible de récupérer le profil.",
    );
  }

  // ==========================================================
  // MODIFIER PROFIL
  // ==========================================================

  static Future<Map<String, dynamic>>
      modifierProfil({
    required String username,
    required String email,
    String? ancienMotDePasse,
    String? nouveauMotDePasse,
    String? confirmationMotDePasse,
  }) async {
    final Map<String, dynamic> donnees = {
      "username": username,
      "email": email,
    };

    final changementMotDePasse =
        (ancienMotDePasse != null &&
            ancienMotDePasse.trim().isNotEmpty) ||
        (nouveauMotDePasse != null &&
            nouveauMotDePasse.trim().isNotEmpty) ||
        (confirmationMotDePasse != null &&
            confirmationMotDePasse.trim().isNotEmpty);

    if (changementMotDePasse) {
      if (ancienMotDePasse == null ||
          ancienMotDePasse.trim().isEmpty) {
        throw Exception(
          "Veuillez saisir votre ancien mot de passe.",
        );
      }

      if (nouveauMotDePasse == null ||
          nouveauMotDePasse.trim().isEmpty) {
        throw Exception(
          "Veuillez saisir le nouveau mot de passe.",
        );
      }

      if (confirmationMotDePasse == null ||
          confirmationMotDePasse.trim().isEmpty) {
        throw Exception(
          "Veuillez confirmer le nouveau mot de passe.",
        );
      }

      if (nouveauMotDePasse != confirmationMotDePasse) {
        throw Exception(
          "Les deux nouveaux mots de passe ne correspondent pas.",
        );
      }

      donnees["ancien_mot_de_passe"] = ancienMotDePasse;
      donnees["nouveau_mot_de_passe"] = nouveauMotDePasse;
      donnees["confirmation_mot_de_passe"] = confirmationMotDePasse;
    }

    final headers = await _headersAuth();

    final response = await http.put(
      Uri.parse("$baseUrl/accounts/profil/"),
      headers: headers,
      body: jsonEncode(donnees),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      await _enregistrerSession(body);
      return body;
    }

    throw Exception(
      body["error"] ??
          body["detail"] ??
          "Impossible de modifier le profil.",
    );
  }

  // ==========================================================
  // RECUPERER LES ETUDIANTS
  // ==========================================================

  static Future<List<dynamic>>
      getEtudiants() async {
    final headers = await _headersAuth();

    final response = await http.get(
      Uri.parse("$baseUrl/accounts/etudiants/"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      throw Exception("Format de réponse invalide.");
    }

    final body = _decodeResponse(response);

    throw Exception(
      body["error"] ??
          body["detail"] ??
          "Impossible de récupérer les étudiants.",
    );
  }

  // ==========================================================
  // QUESTIONS OUVERTES
  // ==========================================================

  static Future<List<dynamic>>
      getQuestionsOuvertes() async {
    final headers = await _headersAuth();

    final response = await http.get(
      Uri.parse("$baseUrl/qcm/questions-ouvertes/"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }
    }

    final body = _decodeResponse(response);

    throw Exception(
      body["error"] ?? "Erreur lors du chargement des questions.",
    );
  }

  // ==========================================================
  // CREER QUESTION OUVERTE
  // ==========================================================

  static Future<Map<String, dynamic>>
      creerQuestionOuverte({
    required String question,
    required String reponseCorrecte,
    required double points,
  }) async {
    final headers = await _headersAuth();

    final response = await http.post(
      Uri.parse("$baseUrl/qcm/questions-ouvertes/creer/"),
      headers: headers,
      body: jsonEncode({
        "question": question,
        "reponse_correcte": reponseCorrecte,
        "points": points,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return body;
    }

    throw Exception(
      body["error"] ?? "Erreur lors de la création de la question.",
    );
  }

  // ==========================================================
  // SUPPRIMER QUESTION OUVERTE
  // ==========================================================

  static Future<Map<String, dynamic>>
      supprimerQuestionOuverte(int id) async {
    final headers = await _headersAuth();

    final response = await http.delete(
      Uri.parse("$baseUrl/qcm/questions-ouvertes/$id/supprimer/"),
      headers: headers,
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(
      body["error"] ?? "Impossible de supprimer la question.",
    );
  }

  // ==========================================================
  // DEVOIRS : LISTE
  // ==========================================================

  static Future<List<dynamic>>
      getDevoirs({String? niveau}) async {
    final headers = await _headersAuth();

    String uri = "$baseUrl/qcm/devoirs/";

    if (niveau != null && niveau.isNotEmpty) {
      uri += "?niveau=${Uri.encodeComponent(niveau)}";
    }

    final response = await http.get(Uri.parse(uri), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      throw Exception("Format de réponse invalide.");
    }

    final body = _decodeResponse(response);

    throw Exception(
      body["error"] ?? "Erreur lors du chargement des devoirs.",
    );
  }

  // ==========================================================
  // CREER DEVOIR PAR NIVEAU
  // ==========================================================

  static Future<Map<String, dynamic>>
      enregistrerDevoir({
    required String niveau,
    required String titre,
    required String contenu,
    required List<int> questions,
  }) async {
    final headers = await _headersAuth();

    final response = await http.post(
      Uri.parse("$baseUrl/qcm/devoirs/creer/"),
      headers: headers,
      body: jsonEncode({
        "niveau": niveau,
        "titre": titre,
        "contenu": contenu,
        "questions": questions,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return body;
    }

    throw Exception(
      body["error"] ?? "Erreur lors de la création du devoir.",
    );
  }

  // ==========================================================
  // SUPPRIMER DEVOIR
  // ==========================================================

  static Future<Map<String, dynamic>>
      supprimerDevoir(int id) async {
    final headers = await _headersAuth();

    final response = await http.delete(
      Uri.parse("$baseUrl/qcm/devoirs/$id/supprimer/"),
      headers: headers,
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(
      body["error"] ?? "Impossible de supprimer le devoir.",
    );
  }

  // ==========================================================
  // DETAIL DEVOIR
  // ==========================================================

  static Future<Map<String, dynamic>>
      getDevoir(int devoirId) async {
    final headers = await _headersAuth();

    final response = await http.get(
      Uri.parse("$baseUrl/qcm/devoirs/$devoirId/"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = _decodeResponse(response);

    throw Exception(
      body["error"] ?? "Devoir introuvable.",
    );
  }

  // ==========================================================
  // REPONDRE A UN DEVOIR
  // ==========================================================

  static Future<Map<String, dynamic>>
      repondreDevoir({
    required int devoirId,
    required int questionId,
    required String reponseEtudiant,
  }) async {
    final headers = await _headersAuth();

    final response = await http.post(
      Uri.parse("$baseUrl/qcm/devoirs/$devoirId/repondre/"),
      headers: headers,
      body: jsonEncode({
        "question_id": questionId,
        "reponse_etudiant": reponseEtudiant,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(
      body["error"] ?? "Erreur lors de l'enregistrement.",
    );
  }

  // ==========================================================
  // TERMINER DEVOIR
  // ==========================================================

  static Future<Map<String, dynamic>>
      terminerDevoir({required int devoirId}) async {
    final headers = await _headersAuth();

    final response = await http.post(
      Uri.parse("$baseUrl/qcm/devoirs/$devoirId/terminer/"),
      headers: headers,
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(
      body["error"] ?? "Erreur lors de la finalisation.",
    );
  }

  // ==========================================================
  // RESULTAT DEVOIR
  // ==========================================================

  static Future<Map<String, dynamic>>
      getResultatDevoir({required int devoirId}) async {
    final headers = await _headersAuth();

    final response = await http.get(
      Uri.parse("$baseUrl/qcm/devoirs/$devoirId/resultat/"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = _decodeResponse(response);

    throw Exception(
      body["error"] ?? "Erreur lors du chargement du résultat.",
    );
  }

  // ==========================================================
  // CORRIGER QUESTION OUVERTE
  // ==========================================================

  static Future<Map<String, dynamic>>
      corrigerQuestionOuverte({
    required int questionId,
    required String reponse,
  }) async {
    final headers = await _headersAuth();

    final response = await http.post(
      Uri.parse("$baseUrl/qcm/question-ouverte/corriger/"),
      headers: headers,
      body: jsonEncode({
        "question_id": questionId,
        "reponse_etudiant": reponse,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(
      body["error"] ?? "Erreur lors de la correction.",
    );
  }

  // ==========================================================
  // PLAGIAT : TOUS LES DEVOIRS
  // ==========================================================

  static Future<Map<String, dynamic>>
      getPlagiat() async {
    final headers = await _headersAuth();

    final response = await http.get(
      Uri.parse("$baseUrl/qcm/plagiat/tous/"),
      headers: headers,
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(
      body["error"] ?? "Erreur lors du chargement du plagiat.",
    );
  }

  // ==========================================================
  // ANALYSER PLAGIAT
  // ==========================================================

  static Future<Map<String, dynamic>>
      analyserPlagiat({
    required String texte1,
    required String texte2,
  }) async {
    final headers = await _headersAuth();

    final response = await http.post(
      Uri.parse("$baseUrl/qcm/plagiat/"),
      headers: headers,
      body: jsonEncode({
        "texte1": texte1,
        "texte2": texte2,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(
      body["error"] ?? "Erreur d'analyse du plagiat.",
    );
  }

  // ==========================================================
  // SOUMETTRE DEVOIR PLAGIAT
  // ==========================================================

  static Future<Map<String, dynamic>>
      soumettreDevoirPlagiat({
    required String etudiant,
    required String titre,
    required String contenu,
  }) async {
    final headers = await _headersAuth();

    final response = await http.post(
      Uri.parse("$baseUrl/qcm/devoirs/plagiat/"),
      headers: headers,
      body: jsonEncode({
        "etudiant": etudiant,
        "titre": titre,
        "contenu": contenu,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return body;
    }

    throw Exception(
      body["error"] ?? "Erreur lors de la soumission.",
    );
  }

  // ==========================================================
  // GENERER QCM DEPUIS TEXTE
  // ==========================================================

  static Future<Map<String, dynamic>>
      genererQCM({
    required String titre,
    required String texte,
    required int nombreQuestions,
    required String niveau,
  }) async {
    final headers = await _headersAuth();

    final response = await http.post(
      Uri.parse("$baseUrl/qcm/generer/"),
      headers: headers,
      body: jsonEncode({
        "titre": titre,
        "texte": texte,
        "niveau": niveau,
        "nombre_questions": nombreQuestions,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 201 ||
        response.statusCode == 200) {
      return body;
    }

    throw Exception(
      body["error"] ??
          body["detail"] ??
          "Erreur lors de la génération du QCM.",
    );
  }

  // ==========================================================
  // GENERER QCM PDF
  // ==========================================================

  static Future<Map<String, dynamic>>
      genererQCMPDF({
    required String titre,
    required int nombreQuestions,
    required String niveau,
  }) async {
    final headerAuth = await _headerAuthSeul();

    final resultat = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf"],
      withData: true,
    );

    if (resultat == null) {
      throw Exception("Aucun fichier sélectionné.");
    }

    final fichier = resultat.files.single;

    if (fichier.name.isEmpty) {
      throw Exception("Nom du fichier invalide.");
    }

    if (!fichier.name.toLowerCase().endsWith(".pdf")) {
      throw Exception("Le fichier sélectionné doit être un PDF.");
    }

    if (fichier.bytes == null) {
      throw Exception("Impossible de lire les données du fichier PDF.");
    }

    if (fichier.bytes!.isEmpty) {
      throw Exception("Le fichier PDF est vide.");
    }

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/qcm/generer-pdf/"),
    );

    request.headers.addAll(headerAuth);

    request.fields["titre"] = titre;
    request.fields["niveau"] = niveau;
    request.fields["nombre_questions"] = nombreQuestions.toString();

    request.files.add(
      http.MultipartFile.fromBytes(
        "fichier",
        fichier.bytes!,
        filename: fichier.name,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final body = _decodeResponse(response);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return body;
    }

    throw Exception(
      body["error"] ??
          body["detail"] ??
          "Erreur lors de la génération du QCM PDF.",
    );
  }

  // ==========================================================
  // LISTE QCM
  // ==========================================================

  static Future<List<dynamic>>
      getQCM({String? niveau}) async {
    final headers = await _headersAuth();

    String uri = "$baseUrl/qcm/";

    if (niveau != null && niveau.isNotEmpty) {
      uri += "?niveau=${Uri.encodeComponent(niveau)}";
    }

    final response = await http.get(Uri.parse(uri), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      throw Exception("Format de réponse invalide.");
    }

    final body = _decodeResponse(response);

    throw Exception(
      body["error"] ?? "Erreur lors du chargement des QCM.",
    );
  }

  // ==========================================================
  // DETAIL QCM
  // ==========================================================

  static Future<Map<String, dynamic>>
      getQCMDetail(int id) async {
    final headers = await _headersAuth();

    final response = await http.get(
      Uri.parse("$baseUrl/qcm/$id/"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = _decodeResponse(response);

    throw Exception(
      body["error"] ?? "QCM introuvable.",
    );
  }

  // ==========================================================
  // SUPPRIMER QCM
  // ==========================================================

  static Future<Map<String, dynamic>>
      supprimerQCM(int id) async {
    final headers = await _headersAuth();

    final response = await http.delete(
      Uri.parse("$baseUrl/qcm/$id/supprimer/"),
      headers: headers,
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(
      body["error"] ?? "Impossible de supprimer le QCM.",
    );
  }

  // ==========================================================
  // CORRECTION QCM
  // ==========================================================

  static Future<Map<String, dynamic>>
      corrigerQuestionQCM({
    required int questionId,
    required String reponse,
  }) async {
    final headers = await _headersAuth();

    final response = await http.post(
      Uri.parse("$baseUrl/qcm/question-qcm/corriger/"),
      headers: headers,
      body: jsonEncode({
        "question_id": questionId,
        "reponse": reponse,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(
      body["error"] ?? "Erreur lors de la correction du QCM.",
    );
  }
}