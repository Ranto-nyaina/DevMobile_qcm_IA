import 'package:flutter/material.dart';
import '../services/api_service.dart';

class QuestionOuverteScreen extends StatefulWidget {
  const QuestionOuverteScreen({super.key});

  @override
  State<QuestionOuverteScreen> createState() =>
      _QuestionOuverteScreenState();
}

class _QuestionOuverteScreenState
    extends State<QuestionOuverteScreen> {

  bool chargement = true;
  String? erreur;
  List<dynamic> questions = [];
  int indexQuestion = 0;

  final TextEditingController reponseController =
      TextEditingController();

  bool correctionEnCours = false;
  Map<String, dynamic>? resultat;

  @override
  void initState() {
    super.initState();
    chargerQuestions();
  }

  Future<void> chargerQuestions() async {
    try {
      final data = await ApiService.getQuestionsOuvertes();

      if (!mounted) return;

      setState(() {
        questions = data;
        chargement = false;
        erreur = null;
        indexQuestion = 0;
        resultat = null;
        reponseController.clear();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        chargement = false;
        erreur = e.toString();
      });
    }
  }

  dynamic get questionActuelle {
    if (questions.isEmpty) {
      return null;
    }
    return questions[indexQuestion];
  }

  Future<void> corriger() async {
    if (questionActuelle == null) {
      return;
    }

    final String reponse = reponseController.text.trim();

    if (reponse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez écrire une réponse."),
        ),
      );
      return;
    }

    setState(() {
      correctionEnCours = true;
      resultat = null;
    });

    try {
      final int questionId =
          int.parse(questionActuelle["id"].toString());

      final data = await ApiService.corrigerQuestionOuverte(
        questionId: questionId,
        reponse: reponse,
      );

      if (!mounted) return;

      setState(() {
        resultat = data;
        correctionEnCours = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        correctionEnCours = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  void questionSuivante() {
    if (indexQuestion >= questions.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Vous êtes arrivé à la dernière question.",
          ),
        ),
      );
      return;
    }

    setState(() {
      indexQuestion++;
      reponseController.clear();
      resultat = null;
    });
  }

  void questionPrecedente() {
    if (indexQuestion <= 0) {
      return;
    }

    setState(() {
      indexQuestion--;
      reponseController.clear();
      resultat = null;
    });
  }

  String obtenirAppreciation(double score) {
    if (score >= 80) {
      return "Très bonne réponse";
    }
    if (score >= 60) {
      return "Bonne réponse";
    }
    if (score >= 40) {
      return "Réponse insuffisante";
    }
    return "Mauvaise réponse";
  }

  @override
  void dispose() {
    reponseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Questions ouvertes"),
      ),
      body: _construireBody(),
    );
  }

  Widget _construireBody() {
    if (chargement) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60),
              const SizedBox(height: 20),
              Text(erreur!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    chargement = true;
                    erreur = null;
                  });
                  chargerQuestions();
                },
                child: const Text("Réessayer"),
              ),
            ],
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return const Center(
        child: Text("Aucune question ouverte disponible."),
      );
    }

    final question = questionActuelle;
    final int numero = indexQuestion + 1;
    final int total = questions.length;

    final double points = double.tryParse(
          question["points"].toString(),
        ) ??
        0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Question $numero / $total",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          LinearProgressIndicator(value: numero / total),

          const SizedBox(height: 25),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Question",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    question["question"]?.toString() ?? "",
                    style: const TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "Points : ${points.toStringAsFixed(1)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Votre réponse",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: reponseController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: "Écrivez votre réponse ici...",
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: correctionEnCours ? null : corriger,
              child: correctionEnCours
                  ? const SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(),
                    )
                  : const Text("CORRIGER"),
            ),
          ),

          const SizedBox(height: 20),

          if (resultat != null) _construireResultat(),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed:
                    indexQuestion > 0 ? questionPrecedente : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text("Précédente"),
              ),
              ElevatedButton.icon(
                onPressed: indexQuestion < questions.length - 1
                    ? questionSuivante
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Suivante"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construireResultat() {
    final double score = double.tryParse(
          resultat!["score"].toString(),
        ) ??
        0;

    final double note = double.tryParse(
          resultat!["note"].toString(),
        ) ??
        0;

    final String resultatTexte =
        resultat!["resultat"]?.toString() ?? "";

    final String niveau = resultat!["niveau"]?.toString() ??
        obtenirAppreciation(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Résultat",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              "Score : ${score.toStringAsFixed(2)} %",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 8),

            Text(
              "Note : ${note.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text("Résultat : $resultatTexte"),

            const SizedBox(height: 8),

            Text("Niveau : $niveau"),
          ],
        ),
      ),
    );
  }
}