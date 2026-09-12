  import 'package:flutter/material.dart';

  import '../services/api_service.dart';

  import 'qcm_screen.dart';
  import 'generation_screen.dart';
  import 'question_ouverte_screen.dart';
  import 'creer_question_ouverte_screen.dart';
  import 'plagiat_screen.dart';
  import 'devoir_screen.dart';
  import 'liste_devoirs_screen.dart';

  class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});

    @override
    State<HomeScreen> createState() => _HomeScreenState();
  }

  class _HomeScreenState extends State<HomeScreen> {

    late Future<List<dynamic>> qcms;

    @override
    void initState() {
      super.initState();

      qcms = ApiService.getQCM();
    }

    // ============================================================
    // ACTUALISER LA LISTE DES QCM
    // ============================================================

    void actualiserQCM() {
      setState(() {
        qcms = ApiService.getQCM();
      });
    }

    @override
    Widget build(BuildContext context) {

      return Scaffold(

        // ========================================================
        // APP BAR
        // ========================================================

        appBar: AppBar(
          title: const Text("QCM AI"),
        ),

        // ========================================================
        // LISTE DES QCM
        // ========================================================

        body: FutureBuilder<List<dynamic>>(
          future: qcms,

          builder: (context, snapshot) {

            if (snapshot.connectionState ==
                ConnectionState.waiting) {

              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {

              return Center(
                child: Text(
                  "Erreur : ${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              );
            }

            final data = snapshot.data ?? [];

            if (data.isEmpty) {

              return const Center(
                child: Text(
                  "Aucun QCM disponible",
                ),
              );
            }

            return ListView.builder(

              itemCount: data.length,

              itemBuilder: (context, index) {

                final qcm = data[index];

                final int qcmId =
                    int.parse(qcm["id"].toString());

                return Card(

                  margin: const EdgeInsets.all(10),

                  child: ListTile(

                    title: Text(
                      qcm["titre"]?.toString() ?? "",
                    ),

                    subtitle: Text(
                      qcm["description"]?.toString() ?? "",
                    ),

                    trailing: const Icon(
                      Icons.arrow_forward,
                    ),

                    onTap: () {

                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => QCMScreen(
                            qcmId: qcmId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),

        // ========================================================
        // BOUTONS FLOTTANTS
        // ========================================================

        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,

          children: [

            // ======================================================
            // PLAGIAT
            // ======================================================

            FloatingActionButton(
              heroTag: "plagiat",

              onPressed: () {

                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) =>
                        const PlagiatScreen(),
                  ),
                );
              },

              child: const Icon(
                Icons.find_in_page,
              ),
            ),

            const SizedBox(height: 15),

            // ======================================================
            // QUESTIONS OUVERTES
            // ======================================================

            FloatingActionButton(
              heroTag: "question_ouverte",

              onPressed: () {

                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) =>
                        const QuestionOuverteScreen(),
                  ),
                );
              },

              child: const Icon(
                Icons.edit_note,
              ),
            ),

            const SizedBox(height: 15),

            // ======================================================
            // DEVOIR
            // ======================================================

            FloatingActionButton(
              heroTag: "devoir",

              onPressed: () {

                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) =>
                        const DevoirScreen(),
                  ),
                );
              },

              child: const Icon(
                Icons.assignment,
              ),
            ),

            const SizedBox(height: 15),

            // ======================================================
            // PASSER UN DEVOIR
            // ======================================================

            FloatingActionButton(
              heroTag: "liste_devoirs",

              onPressed: () {

                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) =>
                        const ListeDevoirsScreen(),
                  ),
                );
              },

              child: const Icon(
                Icons.play_arrow,
              ),
            ),

            const SizedBox(height: 15),


            // ======================================================
            // CRÉER QUESTION OUVERTE
            // ======================================================

            FloatingActionButton(
              heroTag: "creer_question_ouverte",

              onPressed: () async {

                await Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) =>
                        const CreerQuestionOuverteScreen(),
                  ),
                );

                // On recharge les données lorsque
                // l'utilisateur revient sur HomeScreen.
                setState(() {});
              },

              child: const Icon(
                Icons.add_comment,
              ),
            ),

            const SizedBox(height: 15),

            // ======================================================
            // GÉNÉRER UN QCM
            // ======================================================

            FloatingActionButton(
              heroTag: "generer_qcm",

              onPressed: () async {

                await Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) =>
                        const GenerationScreen(),
                  ),
                );

                actualiserQCM();
              },

              child: const Icon(
                Icons.add,
              ),
            ),
          ],
        ),
      );
    }
  }