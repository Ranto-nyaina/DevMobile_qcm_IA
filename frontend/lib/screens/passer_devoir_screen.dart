import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'resultat_devoir_screen.dart';

class PasserDevoirScreen extends StatefulWidget {
  final int devoirId;

  const PasserDevoirScreen({
    super.key,
    required this.devoirId,
  });

  @override
  State<PasserDevoirScreen> createState() =>
      _PasserDevoirScreenState();
}

class _PasserDevoirScreenState extends State<PasserDevoirScreen> {
  // ==========================================================
  // VARIABLES
  // ==========================================================

  bool chargement = true;
  bool envoi = false;

  String? erreur;

  Map<String, dynamic>? devoir;

  List<dynamic> questions = [];

  int questionActuelle = 0;

  // Réponses conservées localement
  final Map<int, String> reponses = {};

  // Un seul contrôleur
  final TextEditingController reponseController =
      TextEditingController();

  // ==========================================================
  // INITIALISATION
  // ==========================================================

  @override
  void initState() {
    super.initState();

    chargerDevoir();
  }

  // ==========================================================
  // CHARGER LE DEVOIR
  // ==========================================================

  Future<void> chargerDevoir() async {
    try {
      final data = await ApiService.getDevoir(
        widget.devoirId,
      );

      if (!mounted) return;

      final listeQuestions = data["questions"];

      setState(() {
        devoir = data;

        questions = listeQuestions is List
            ? listeQuestions
            : [];

        chargement = false;
        erreur = null;

        questionActuelle = 0;
      });

      chargerReponseActuelle();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        chargement = false;
        erreur = e.toString();
      });
    }
  }

  // ==========================================================
  // QUESTION COURANTE
  // ==========================================================

  dynamic get questionCourante {
    if (questions.isEmpty) {
      return null;
    }

    if (questionActuelle < 0 ||
        questionActuelle >= questions.length) {
      return null;
    }

    return questions[questionActuelle];
  }

  // ==========================================================
  // CHARGER LA REPONSE ACTUELLE
  // ==========================================================

  void chargerReponseActuelle() {
    if (questionCourante == null) {
      reponseController.clear();
      return;
    }

    final int questionId =
        int.tryParse(
              questionCourante["id"].toString(),
            ) ??
            0;

    reponseController.text =
        reponses[questionId] ?? "";

    // Curseur à la fin du texte
    reponseController.selection =
        TextSelection.fromPosition(
      TextPosition(
        offset: reponseController.text.length,
      ),
    );
  }

  // ==========================================================
  // SAUVEGARDER LOCALEMENT
  // ==========================================================

  void sauvegarderReponseLocale() {
    if (questionCourante == null) {
      return;
    }

    final int questionId =
        int.tryParse(
              questionCourante["id"].toString(),
            ) ??
            0;

    reponses[questionId] =
        reponseController.text.trim();
  }

  // ==========================================================
  // ENREGISTRER LA REPONSE DANS DJANGO
  // ==========================================================

  Future<bool> enregistrerReponse() async {
    if (questionCourante == null) {
      return false;
    }

    final String texte =
        reponseController.text.trim();

    if (texte.isEmpty) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Veuillez écrire une réponse.",
          ),
        ),
      );

      return false;
    }

    // Sauvegarde locale
    sauvegarderReponseLocale();

    final int questionId =
        int.tryParse(
              questionCourante["id"].toString(),
            ) ??
            0;

    if (questionId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Identifiant de question invalide.",
          ),
        ),
      );

      return false;
    }

    if (mounted) {
      setState(() {
        envoi = true;
      });
    }

    try {
      await ApiService.repondreDevoir(
        devoirId: widget.devoirId,
        questionId: questionId,
        reponseEtudiant: texte,
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erreur lors de l'enregistrement : $e",
          ),
        ),
      );

      return false;
    } finally {
      if (mounted) {
        setState(() {
          envoi = false;
        });
      }
    }
  }

  // ==========================================================
  // QUESTION SUIVANTE
  // ==========================================================

  Future<void> questionSuivante() async {
    final bool succes =
        await enregistrerReponse();

    if (!succes || !mounted) {
      return;
    }

    // Il reste des questions
    if (questionActuelle <
        questions.length - 1) {
      setState(() {
        questionActuelle++;
      });

      chargerReponseActuelle();

      return;
    }

    // Dernière question
    await terminerDevoir();
  }

  // ==========================================================
  // QUESTION PRECEDENTE
  // ==========================================================

  void questionPrecedente() {
    if (questionActuelle <= 0) {
      return;
    }

    sauvegarderReponseLocale();

    setState(() {
      questionActuelle--;
    });

    chargerReponseActuelle();
  }

  // ==========================================================
  // TERMINER LE DEVOIR
  // ==========================================================

  Future<void> terminerDevoir() async {
    if (!mounted) return;

    setState(() {
      envoi = true;
    });

    try {
      // Finalisation côté Django
      await ApiService.terminerDevoir(
        devoirId: widget.devoirId,
      );

      if (!mounted) return;

      setState(() {
        envoi = false;
      });

      // Ouvrir la page du résultat
      //
      // IMPORTANT :
      // On ne transmet PAS "resultat".
      // ResultatDevoirScreen récupère lui-même
      // le résultat avec getResultatDevoir().
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultatDevoirScreen(
            devoirId: widget.devoirId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        envoi = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erreur lors de la finalisation : $e",
          ),
        ),
      );
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    reponseController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Passer le devoir",
        ),
      ),
      body: construireBody(),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget construireBody() {
    // --------------------------------------------------------
    // CHARGEMENT
    // --------------------------------------------------------

    if (chargement) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // --------------------------------------------------------
    // ERREUR
    // --------------------------------------------------------

    if (erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
              ),

              const SizedBox(height: 20),

              Text(
                erreur!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    chargement = true;
                    erreur = null;
                  });

                  chargerDevoir();
                },
                child: const Text(
                  "Réessayer",
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --------------------------------------------------------
    // DEVOIR INEXISTANT
    // --------------------------------------------------------

    if (devoir == null) {
      return const Center(
        child: Text(
          "Devoir introuvable.",
        ),
      );
    }

    // --------------------------------------------------------
    // AUCUNE QUESTION
    // --------------------------------------------------------

    if (questions.isEmpty) {
      return const Center(
        child: Text(
          "Ce devoir ne contient aucune question.",
        ),
      );
    }

    // --------------------------------------------------------
    // QUESTION COURANTE
    // --------------------------------------------------------

    final question = questionCourante;

    if (question == null) {
      return const Center(
        child: Text(
          "Question introuvable.",
        ),
      );
    }

    final int numero =
        questionActuelle + 1;

    final int total =
        questions.length;

    final String texteQuestion =
        question["question"]?.toString() ?? "";

    final double points =
        double.tryParse(
              question["points"].toString(),
            ) ??
            0;

    final bool derniereQuestion =
        questionActuelle ==
            questions.length - 1;

    // ========================================================
    // INTERFACE
    // ========================================================

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ====================================================
          // TITRE
          // ====================================================

          Text(
            devoir!["titre"]?.toString() ??
                "Devoir",

            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // ====================================================
          // QUESTION / POINTS
          // ====================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [
              Text(
                "Question $numero / $total",

                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                "${points.toStringAsFixed(1)} points",

                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ====================================================
          // PROGRESSION
          // ====================================================

          LinearProgressIndicator(
            value: numero / total,
          ),

          const SizedBox(height: 30),

          // ====================================================
          // QUESTION
          // ====================================================

          const Text(
            "Question",

            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Text(
                texteQuestion,

                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // ====================================================
          // REPONSE
          // ====================================================

          const Text(
            "Votre réponse",

            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: reponseController,

            maxLines: 10,

            textInputAction:
                TextInputAction.newline,

            decoration:
                const InputDecoration(
              hintText:
                  "Écrivez votre réponse ici...",
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 30),

          // ====================================================
          // BOUTONS
          // ====================================================

          Row(
            children: [
              // ------------------------------------------------
              // PRECEDENT
              // ------------------------------------------------

              if (questionActuelle > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        envoi
                            ? null
                            : questionPrecedente,

                    icon: const Icon(
                      Icons.arrow_back,
                    ),

                    label: const Text(
                      "PRÉCÉDENT",
                    ),
                  ),
                ),

              if (questionActuelle > 0)
                const SizedBox(width: 10),

              // ------------------------------------------------
              // SUIVANTE / TERMINER
              // ------------------------------------------------

              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      envoi
                          ? null
                          : questionSuivante,

                  icon: envoi
                      ? const SizedBox(
                          width: 20,
                          height: 20,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          derniereQuestion
                              ? Icons.check
                              : Icons.arrow_forward,
                        ),

                  label: Text(
                    derniereQuestion
                        ? "TERMINER"
                        : "SUIVANTE",
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ====================================================
          // INFORMATION
          // ====================================================

          if (!derniereQuestion)
            const Center(
              child: Text(
                "Votre réponse sera corrigée automatiquement.",
                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}