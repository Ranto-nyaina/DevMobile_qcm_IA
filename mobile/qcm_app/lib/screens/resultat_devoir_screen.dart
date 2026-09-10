import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResultatDevoirScreen extends StatefulWidget {
  final int devoirId;

  const ResultatDevoirScreen({
    super.key,
    required this.devoirId,
  });

  @override
  State<ResultatDevoirScreen> createState() =>
      _ResultatDevoirScreenState();
}

class _ResultatDevoirScreenState
    extends State<ResultatDevoirScreen> {

  bool chargement = true;

  String? erreur;

  Map<String, dynamic>? resultat;

  @override
  void initState() {
    super.initState();

    chargerResultat();
  }

  // ==========================================================
  // CHARGER LE RESULTAT
  // ==========================================================

  Future<void> chargerResultat() async {

    try {

      final data =
          await ApiService.getResultatDevoir(
        devoirId: widget.devoirId,
      );

      if (!mounted) return;

      setState(() {
        resultat = data;
        chargement = false;
        erreur = null;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {
        chargement = false;
        erreur = e.toString();
      });
    }
  }

  // ==========================================================
  // APPRECIATION
  // ==========================================================

  String obtenirAppreciation(double note) {

    if (note >= 16) {
      return "Très bien";
    }

    if (note >= 14) {
      return "Bien";
    }

    if (note >= 10) {
      return "Passable";
    }

    return "Insuffisant";
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Résultat du devoir",
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

                  chargerResultat();
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
    // AUCUN RESULTAT
    // --------------------------------------------------------

    if (resultat == null) {

      return const Center(
        child: Text(
          "Aucun résultat disponible.",
        ),
      );
    }

    // ========================================================
    // RECUPERATION DES DONNEES
    // ========================================================

    final double note =
        double.tryParse(
              resultat!["note_finale"]
                  .toString(),
            ) ??
            0;

    final double pointsObtenus =
        double.tryParse(
              resultat!["points_obtenus"]
                  .toString(),
            ) ??
            0;

    final double pointsTotal =
        double.tryParse(
              resultat!["points_total"]
                  .toString(),
            ) ??
            0;

    final int nombreQuestions =
        int.tryParse(
              resultat!["nombre_questions"]
                  .toString(),
            ) ??
            0;

    final int questionsRepondues =
        int.tryParse(
              resultat!["questions_repondues"]
                  .toString(),
            ) ??
            0;

    final String titre =
        resultat!["titre"]?.toString() ??
            "Devoir";

    final String appreciation =
        obtenirAppreciation(note);

    // ========================================================
    // AFFICHAGE
    // ========================================================

    return SingleChildScrollView(

      padding: const EdgeInsets.all(20),

      child: Column(

        children: [

          const SizedBox(height: 20),

          const Icon(
            Icons.school,
            size: 80,
          ),

          const SizedBox(height: 20),

          Text(
            titre,

            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Résultat final",

            style: TextStyle(
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 30),

          // ==================================================
          // NOTE
          // ==================================================

          Card(

            child: Padding(

              padding:
                  const EdgeInsets.all(25),

              child: Column(

                children: [

                  const Text(
                    "Note finale",

                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "${note.toStringAsFixed(2)} / 20",

                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    appreciation,

                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ==================================================
          // POINTS
          // ==================================================

          Card(

            child: Padding(

              padding:
                  const EdgeInsets.all(20),

              child: Column(

                children: [

                  const Text(
                    "Points obtenus",

                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "${pointsObtenus.toStringAsFixed(2)} / "
                    "${pointsTotal.toStringAsFixed(2)}",

                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ==================================================
          // QUESTIONS
          // ==================================================

          Card(

            child: Padding(

              padding:
                  const EdgeInsets.all(20),

              child: Row(

                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,

                children: [

                  Column(

                    children: [

                      const Text(
                        "Questions",
                      ),

                      const SizedBox(height: 5),

                      Text(
                        nombreQuestions.toString(),

                        style:
                            const TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  Column(

                    children: [

                      const Text(
                        "Répondues",
                      ),

                      const SizedBox(height: 5),

                      Text(
                        questionsRepondues
                            .toString(),

                        style:
                            const TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 35),

          // ==================================================
          // RETOUR ACCUEIL
          // ==================================================

          SizedBox(

            width: double.infinity,

            height: 50,

            child: ElevatedButton(

              onPressed: () {

                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                );
              },

              child: const Text(
                "RETOUR À L'ACCUEIL",
              ),
            ),
          ),
        ],
      ),
    );
  }
}