import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'inscription_screen.dart' show kNiveaux;

import 'devoir_screen.dart';
import 'devoir_detail_screen.dart';

class ListeDevoirsScreen extends StatefulWidget {
  const ListeDevoirsScreen({super.key});

  @override
  State<ListeDevoirsScreen> createState() => _ListeDevoirsScreenState();
}

class _ListeDevoirsScreenState extends State<ListeDevoirsScreen> {
  late Future<List<dynamic>> devoirs;

  String? role;
  String? niveauFiltre;

  @override
  void initState() {
    super.initState();

    devoirs = ApiService.getDevoirs();

    _chargerRole();
  }

  Future<void> _chargerRole() async {
    final r = await ApiService.getRole();

    if (!mounted) return;

    setState(() {
      role = r;
    });
  }

  Future<void> _actualiser() async {
    setState(() {
      devoirs = ApiService.getDevoirs(niveau: niveauFiltre);
    });

    await devoirs;
  }

  Future<void> _supprimer(int id, String titre) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer le devoir"),
          content: Text(
            "Voulez-vous vraiment supprimer \"$titre\" ? "
            "Les réponses des étudiants seront aussi supprimées.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );

    if (confirmation != true) return;

    try {
      await ApiService.supprimerDevoir(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Devoir supprimé.")),
      );

      _actualiser();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enseignant = role == "enseignant";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          enseignant ? "Gestion des devoirs" : "Mes devoirs",
        ),
      ),
      body: Column(
        children: [
          if (enseignant)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
              child: DropdownButtonFormField<String?>(
                initialValue: niveauFiltre,
                decoration: const InputDecoration(
                  labelText: "Filtrer par niveau",
                  prefixIcon: Icon(Icons.filter_list),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text("Tous les niveaux"),
                  ),
                  ...kNiveaux.map(
                    (n) => DropdownMenuItem<String?>(
                      value: n,
                      child: Text(n),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    niveauFiltre = value;
                    devoirs = ApiService.getDevoirs(niveau: niveauFiltre);
                  });
                },
              ),
            ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: devoirs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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

                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _actualiser,
                    child: ListView(
                      children: const [
                        SizedBox(height: 250),
                        Center(child: Text("Aucun devoir disponible.")),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _actualiser,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final devoir = data[index];
                      final int id = int.parse(devoir["id"].toString());
                      final String titre = devoir["titre"]?.toString() ?? "";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              enseignant
                                  ? Icons.assignment
                                  : Icons.assignment_outlined,
                            ),
                          ),
                          title: Text(
                            titre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text("Étudiant : ${devoir["etudiant"] ?? ""}"),
                              Text(
                                "${devoir["nombre_questions"] ?? 0} question(s)",
                              ),
                              if (devoir["date_creation"] != null)
                                Text(
                                  "Créé le : ${devoir["date_creation"]}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: enseignant
                              ? IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _supprimer(id, titre),
                                )
                              : const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DevoirDetailScreen(
                                  devoirId: id,
                                  enseignant: enseignant,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: enseignant
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DevoirScreen(),
                  ),
                );

                if (!mounted) return;

                _actualiser();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}