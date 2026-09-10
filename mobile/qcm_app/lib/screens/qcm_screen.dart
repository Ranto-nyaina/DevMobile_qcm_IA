import 'package:flutter/material.dart';
import '../services/api_service.dart';

class QCMScreen extends StatefulWidget {
  final int qcmId;

  const QCMScreen({
    super.key,
    required this.qcmId,
  });

  @override
  State<QCMScreen> createState() => _QCMScreenState();
}

class _QCMScreenState extends State<QCMScreen> {
  late Future<Map<String, dynamic>> qcm;

  int questionActuelle = 0;

  int bonnesReponses = 0;

  bool reponseSelectionnee = false;

  int? propositionSelectionnee;

  bool? derniereReponseCorrecte;

  @override
  void initState() {
    super.initState();

    qcm = ApiService.getQCMDetail(
      widget.qcmId,
    );
  }

  // ==========================================================
  // VERIFIER LA REPONSE
  // ==========================================================

  void verifierReponse(
    bool correcte,
    int propositionIndex,
  ) {
    if (reponseSelectionnee) {
      return;
    }

    setState(() {
      reponseSelectionnee = true;

      propositionSelectionnee =
          propositionIndex;

      derniereReponseCorrecte =
          correcte;

      if (correcte) {
        bonnesReponses++;
      }
    });
  }

  // ==========================================================
  // QUESTION SUIVANTE
  // ==========================================================

  void questionSuivante(
    int nombreQuestions,
  ) {
    if (questionActuelle <
        nombreQuestions - 1) {
      setState(() {
        questionActuelle++;

        reponseSelectionnee = false;

        propositionSelectionnee = null;

        derniereReponseCorrecte = null;
      });
    } else {
      setState(() {
        questionActuelle =
            nombreQuestions;
      });
    }
  }

  // ==========================================================
  // APPRECIATION
  // ==========================================================

  String obtenirAppreciation(
    double note,
  ) {
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
  // MESSAGE RESULTAT
  // ==========================================================

  String obtenirMessage(
    double note,
  ) {
    if (note >= 16) {
      return "Excellent travail !";
    }

    if (note >= 14) {
      return "Très bon travail !";
    }

    if (note >= 10) {
      return "Résultat satisfaisant.";
    }

    return "Il faut encore travailler.";
  }

  // ==========================================================
  // RESULTAT FINAL
  // ==========================================================

  Widget construireResultat(
    int nombreQuestions,
  ) {
    final double pourcentage =
        nombreQuestions > 0
            ? (bonnesReponses /
                    nombreQuestions) *
                100
            : 0;

    final double note =
        (pourcentage / 100) * 20;

    final String appreciation =
        obtenirAppreciation(note);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.emoji_events,
              size: 90,
            ),

            const SizedBox(height: 20),

            const Text(
              "QCM terminé",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
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

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      "${note.toStringAsFixed(2)} / 20",
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      appreciation,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // SCORE
            // ==================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Score",
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      "$bonnesReponses / "
                      "$nombreQuestions",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      "${pourcentage.toStringAsFixed(1)} %",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              obtenirMessage(note),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // RETOUR
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "RETOUR",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // AFFICHER UNE PROPOSITION
  // ==========================================================

  Widget construireProposition({
    required Map<String, dynamic>
        proposition,
    required int index,
  }) {
    final bool correcte =
        proposition["est_correcte"] ==
            true;

    final bool selectionnee =
        propositionSelectionnee ==
            index;

    Color? couleur;

    if (reponseSelectionnee) {
      if (correcte) {
        couleur = Colors.green;
      } else if (selectionnee) {
        couleur = Colors.red;
      }
    }

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 15,
          ),

          backgroundColor:
              couleur,

          foregroundColor:
              couleur != null
                  ? Colors.white
                  : null,
        ),

        onPressed:
            reponseSelectionnee
                ? null
                : () {
                    verifierReponse(
                      correcte,
                      index,
                    );
                  },

        child: Row(
          children: [
            Expanded(
              child: Text(
                proposition["texte"]
                        ?.toString() ??
                    "",
                textAlign:
                    TextAlign.left,
                style:
                    const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),

            if (reponseSelectionnee &&
                correcte)
              const Icon(
                Icons.check,
              ),

            if (reponseSelectionnee &&
                selectionnee &&
                !correcte)
              const Icon(
                Icons.close,
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QCM"),
      ),

      body:
          FutureBuilder<
              Map<String, dynamic>>(
        future: qcm,

        builder: (
          context,
          snapshot,
        ) {
          // ==================================================
          // CHARGEMENT
          // ==================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          // ==================================================
          // ERREUR
          // ==================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    Text(
                      "Erreur : "
                      "${snapshot.error}",
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          qcm = ApiService
                              .getQCMDetail(
                            widget.qcmId,
                          );
                        });
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

          // ==================================================
          // DONNEES
          // ==================================================

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                "Aucune donnée disponible.",
              ),
            );
          }

          final data =
              snapshot.data!;

          final List questions =
              data["questions"] ?? [];

          // ==================================================
          // AUCUNE QUESTION
          // ==================================================

          if (questions.isEmpty) {
            return const Center(
              child: Text(
                "Ce QCM ne contient "
                "aucune question.",
              ),
            );
          }

          // ==================================================
          // QCM TERMINE
          // ==================================================

          if (questionActuelle >=
              questions.length) {
            return construireResultat(
              questions.length,
            );
          }

          // ==================================================
          // QUESTION ACTUELLE
          // ==================================================

          final question =
              questions[
                  questionActuelle];

          final List propositions =
              question["propositions"] ??
                  [];

          final double progression =
              (questionActuelle + 1) /
                  questions.length;

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // TITRE
                // ==================================================

                Text(
                  data["titre"]
                          ?.toString() ??
                      "QCM",
                  style:
                      const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // PROGRESSION
                // ==================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Text(
                      "Question "
                      "${questionActuelle + 1}"
                      " / "
                      "${questions.length}",
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    Text(
                      "${(progression * 100).toStringAsFixed(0)} %",
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                LinearProgressIndicator(
                  value: progression,
                ),

                const SizedBox(
                  height: 30,
                ),

                // ==================================================
                // QUESTION
                // ==================================================

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(20),

                    child: Text(
                      question["texte"]
                              ?.toString() ??
                          "",
                      style:
                          const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                const Text(
                  "Choisissez une réponse :",
                  style:
                      TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                // ==================================================
                // PROPOSITIONS
                // ==================================================

                ...List.generate(
                  propositions.length,
                  (index) {
                    final proposition =
                        propositions[index]
                            as Map<String,
                                dynamic>;

                    return construireProposition(
                      proposition:
                          proposition,
                      index: index,
                    );
                  },
                ),

                // ==================================================
                // RESULTAT REPONSE
                // ==================================================

                if (reponseSelectionnee) ...[
                  const SizedBox(
                    height: 15,
                  ),

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(15),

                      child: Row(
                        children: [
                          Icon(
                            derniereReponseCorrecte ==
                                    true
                                ? Icons
                                    .check_circle
                                : Icons
                                    .cancel,
                            size: 30,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child: Text(
                              derniereReponseCorrecte ==
                                      true
                                  ? "Bonne réponse !"
                                  : "Mauvaise réponse.",
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // BOUTON SUIVANT
                  // ==================================================

                  SizedBox(
                    width:
                        double.infinity,
                    height: 50,

                    child:
                        ElevatedButton(
                      onPressed: () {
                        questionSuivante(
                          questions.length,
                        );
                      },

                      child: Text(
                        questionActuelle ==
                                questions.length -
                                    1
                            ? "VOIR LE RÉSULTAT"
                            : "QUESTION SUIVANTE",
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}