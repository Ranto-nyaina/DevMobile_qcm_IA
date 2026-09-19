import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PlagiatScreen extends StatefulWidget {
  const PlagiatScreen({super.key});

  @override
  State<PlagiatScreen> createState() => _PlagiatScreenState();
}

class _PlagiatScreenState extends State<PlagiatScreen> {

  late Future<Map<String, dynamic>> resultats;

  @override
  void initState() {
    super.initState();
    resultats = ApiService.getPlagiat();
  }

  Color couleurNiveau(String niveau) {
    if (niveau.contains("très probable")) {
      return Colors.red;
    }

    if (niveau.contains("élevée")) {
      return Colors.orange;
    }

    if (niveau.contains("moyenne")) {
      return Colors.amber;
    }

    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Détection de plagiat"),
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: resultats,

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
              ),
            );
          }

          final data = snapshot.data ?? {};
          final liste = data["resultats"] ?? [];

          if (liste.isEmpty) {
            return const Center(
              child: Text(
                "Aucune comparaison disponible.",
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                resultats = ApiService.getPlagiat();
              });

              await resultats;
            },

            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: liste.length,

              itemBuilder: (context, index) {

                final resultat = liste[index];

                final double similarite =
                    (resultat["similarite"] ?? 0).toDouble();

                final String niveau =
                    resultat["niveau"] ?? "";

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(15),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Row(
                          children: [

                            const Icon(
                              Icons.people,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                "${resultat["etudiant1"]} ↔ "
                                "${resultat["etudiant2"]}",
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
                          "Similarité : "
                          "${similarite.toStringAsFixed(2)} %",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        LinearProgressIndicator(
                          value: similarite / 100,
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),

                          decoration: BoxDecoration(
                            color: couleurNiveau(niveau)
                                .withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),

                          child: Text(
                            niveau,
                            style: TextStyle(
                              color: couleurNiveau(niveau),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}