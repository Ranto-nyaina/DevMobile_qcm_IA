import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreerQuestionOuverteScreen extends StatefulWidget {
  const CreerQuestionOuverteScreen({super.key});

  @override
  State<CreerQuestionOuverteScreen> createState() =>
      _CreerQuestionOuverteScreenState();
}

class _CreerQuestionOuverteScreenState
    extends State<CreerQuestionOuverteScreen> {

  final TextEditingController questionController =
      TextEditingController();

  final TextEditingController reponseController =
      TextEditingController();

  final TextEditingController pointsController =
      TextEditingController(text: "5");

  bool chargement = false;

  Future<void> creerQuestion() async {
    final String question =
        questionController.text.trim();

    final String reponseCorrecte =
        reponseController.text.trim();

    final String pointsTexte =
        pointsController.text.trim();

    if (question.isEmpty) {
      afficherMessage(
        "Veuillez saisir la question.",
      );
      return;
    }

    if (reponseCorrecte.isEmpty) {
      afficherMessage(
        "Veuillez saisir la réponse correcte.",
      );
      return;
    }

    if (pointsTexte.isEmpty) {
      afficherMessage(
        "Veuillez sélectionner le nombre de points.",
      );
      return;
    }

    final double? points =
        double.tryParse(pointsTexte);

    if (points == null || points <= 0) {
      afficherMessage(
        "Le nombre de points est invalide.",
      );
      return;
    }

    setState(() {
      chargement = true;
    });

    try {
      final resultat =
          await ApiService.creerQuestionOuverte(
        question: question,
        reponseCorrecte: reponseCorrecte,
        points: points,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Question ouverte créée avec succès.",
          ),
        ),
      );

      questionController.clear();
      reponseController.clear();
      pointsController.text = "5";

      Navigator.pop(
        context,
        resultat,
      );
    } catch (e) {
      if (!mounted) return;

      afficherMessage(
        "Erreur lors de la création : $e",
      );
    } finally {
      if (mounted) {
        setState(() {
          chargement = false;
        });
      }
    }
  }

  void afficherMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    questionController.dispose();
    reponseController.dispose();
    pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Créer une question ouverte",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Question",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: questionController,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText:
                    "Exemple : Qu'est-ce que le Big Data ?",
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Réponse correcte",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: reponseController,
              maxLines: 7,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText:
                    "Saisissez la réponse attendue...",
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Points",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<double>(
              initialValue:
                  double.tryParse(
                    pointsController.text,
                  ) ??
                  5,
              decoration: const InputDecoration(
                labelText: "Nombre de points",
              ),
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text("1 point"),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text("2 points"),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text("3 points"),
                ),
                DropdownMenuItem(
                  value: 4,
                  child: Text("4 points"),
                ),
                DropdownMenuItem(
                  value: 5,
                  child: Text("5 points"),
                ),
                DropdownMenuItem(
                  value: 10,
                  child: Text("10 points"),
                ),
                DropdownMenuItem(
                  value: 15,
                  child: Text("15 points"),
                ),
                DropdownMenuItem(
                  value: 20,
                  child: Text("20 points"),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  pointsController.text = value.toString();
                }
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: chargement ? null : creerQuestion,
                icon: chargement
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  chargement
                      ? "CRÉATION..."
                      : "CRÉER LA QUESTION",
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "La réponse correcte sera utilisée "
                        "par le système pour corriger "
                        "automatiquement les réponses "
                        "des étudiants.",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}