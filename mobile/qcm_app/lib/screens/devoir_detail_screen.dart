import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DevoirDetailScreen extends StatefulWidget {
  final int devoirId;
  final bool enseignant;

  const DevoirDetailScreen({
    super.key,
    required this.devoirId,
    required this.enseignant,
  });

  @override
  State<DevoirDetailScreen> createState() =>
      _DevoirDetailScreenState();
}

class _DevoirDetailScreenState
    extends State<DevoirDetailScreen> {

  late Future<Map<String, dynamic>> devoir;

  final Map<int, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    devoir = ApiService.getDevoir(widget.devoirId);
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(int questionId) {
    if (!controllers.containsKey(questionId)) {
      controllers[questionId] = TextEditingController();
    }
    return controllers[questionId]!;
  }

  Future<void> _envoyerReponse(int questionId) async {
    final controller = _getController(questionId);
    final reponse = controller.text.trim();

    if (reponse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez saisir une réponse."),
        ),
      );
      return;
    }

    try {
      final resultat = await ApiService.repondreDevoir(
        devoirId: widget.devoirId,
        questionId: questionId,
        reponseEtudiant: reponse,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Correction"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Score : ${resultat["score"]} %"),
              const SizedBox(height: 8),
              Text(
                "Note : ${resultat["note"]} / "
                "${resultat["points"]}",
              ),
              const SizedBox(height: 8),
              Text(resultat["resultat"]?.toString() ?? ""),
              const SizedBox(height: 8),
              Text(resultat["niveau"]?.toString() ?? ""),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  Future<void> _terminerDevoir() async {
    try {
      final resultat = await ApiService.terminerDevoir(
        devoirId: widget.devoirId,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultatDevoirScreen(
            resultat: resultat,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.enseignant
              ? "Détail du devoir"
              : "Faire le devoir",
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: devoir,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Erreur : ${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final questions = data["questions"] as List? ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                data["titre"]?.toString() ?? "",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text("Étudiant : ${data["etudiant"] ?? ""}"),

              const SizedBox(height: 20),

              ...questions.map(
                (question) {
                  final int questionId =
                      int.parse(question["id"].toString());

                  final points = question["points"];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Question ${question["ordre"] ?? ""}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            question["question"]?.toString() ?? "",
                            style: const TextStyle(fontSize: 16),
                          ),

                          const SizedBox(height: 8),

                          Text("Points : $points"),

                          if (!widget.enseignant) ...[
                            const SizedBox(height: 15),

                            TextField(
                              controller: _getController(questionId),
                              maxLines: 5,
                              decoration: const InputDecoration(
                                hintText: "Votre réponse...",
                              ),
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _envoyerReponse(questionId),
                                icon: const Icon(Icons.send),
                                label: const Text(
                                  "Envoyer la réponse",
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              if (!widget.enseignant && questions.isNotEmpty) ...[
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _terminerDevoir,
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Terminer le devoir"),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ],
          );
        },
      ),
    );
  }
}


// ==========================================================
// RESULTAT DU DEVOIR
// ==========================================================

class ResultatDevoirScreen extends StatelessWidget {
  final Map<String, dynamic> resultat;

  const ResultatDevoirScreen({
    super.key,
    required this.resultat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Résultat"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.emoji_events, size: 80),

          const SizedBox(height: 20),

          Text(
            resultat["titre"]?.toString() ?? "",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 25),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "Note finale",
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "${resultat["note_finale"]} / 20",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Points obtenus : "
                    "${resultat["points_obtenus"]} / "
                    "${resultat["points_total"]}",
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Questions répondues : "
                    "${resultat["questions_repondues"]} / "
                    "${resultat["nombre_questions"]}",
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Retour"),
          ),
        ],
      ),
    );
  }
}