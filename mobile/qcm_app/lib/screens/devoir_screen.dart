import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'inscription_screen.dart' show kNiveaux;

class DevoirScreen extends StatefulWidget {
  const DevoirScreen({super.key});

  @override
  State<DevoirScreen> createState() => _DevoirScreenState();
}

class _DevoirScreenState extends State<DevoirScreen> {
  final TextEditingController titreController = TextEditingController();

  bool chargementQuestions = true;
  bool chargementCreation = false;

  String? erreurQuestions;

  List<dynamic> questions = [];

  String? niveauSelectionne;

  final Set<int> questionsSelectionnees = {};

  @override
  void initState() {
    super.initState();
    chargerQuestions();
  }

  Future<void> chargerQuestions() async {
    if (!mounted) return;

    setState(() {
      chargementQuestions = true;
      erreurQuestions = null;
    });

    try {
      final data = await ApiService.getQuestionsOuvertes();

      if (!mounted) return;

      setState(() {
        questions = data;
        chargementQuestions = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        chargementQuestions = false;
        erreurQuestions = e.toString();
      });
    }
  }

  void changerSelection(int questionId, bool selectionnee) {
    setState(() {
      if (selectionnee) {
        questionsSelectionnees.add(questionId);
      } else {
        questionsSelectionnees.remove(questionId);
      }
    });
  }

  Future<void> creerDevoir() async {
    final String? niveau = niveauSelectionne;
    final String titre = titreController.text.trim();

    if (niveau == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner un niveau."),
        ),
      );
      return;
    }

    if (titre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez saisir le titre du devoir."),
        ),
      );
      return;
    }

    if (questionsSelectionnees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Veuillez sélectionner au moins une question.",
          ),
        ),
      );
      return;
    }

    setState(() {
      chargementCreation = true;
    });

    try {
      final resultat = await ApiService.enregistrerDevoir(
        niveau: niveau,
        titre: titre,
        contenu: "",
        questions: questionsSelectionnees.toList(),
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Devoir créé"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Le devoir a été créé avec succès.",
                ),
                const SizedBox(height: 15),
                Text("Niveau : $niveau"),
                const SizedBox(height: 8),
                Text(
                  "Nombre d'étudiants concernés : "
                  "${resultat["nombre_etudiants"]}",
                ),
                const SizedBox(height: 8),
                Text(
                  "Questions : ${resultat["nombre_questions"]}",
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );

      titreController.clear();

      setState(() {
        niveauSelectionne = null;
        questionsSelectionnees.clear();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la création : $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          chargementCreation = false;
        });
      }
    }
  }

  Widget construireQuestions() {
    if (chargementQuestions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (erreurQuestions != null) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 50),
            const SizedBox(height: 10),
            Text(erreurQuestions!, textAlign: TextAlign.center),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: chargerQuestions,
              child: const Text("Réessayer"),
            ),
          ],
        ),
      );
    }

    if (questions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              "Aucune question ouverte disponible.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];

        final int id = int.tryParse(question["id"].toString()) ?? 0;
        final String texte = question["question"]?.toString() ?? "";
        final double points =
            double.tryParse(question["points"].toString()) ?? 0;

        final bool selectionnee = questionsSelectionnees.contains(id);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: CheckboxListTile(
            value: selectionnee,
            onChanged: chargementCreation
                ? null
                : (value) {
                    changerSelection(id, value ?? false);
                  },
            title: Text(
              texte,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text("Points : ${points.toStringAsFixed(1)}"),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    titreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un devoir"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Niveau",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: niveauSelectionne,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Niveau concerné",
                hintText: "Sélectionner un niveau",
                prefixIcon: Icon(Icons.grade),
              ),
              items: kNiveaux
                  .map(
                    (n) => DropdownMenuItem(
                      value: n,
                      child: Text(n),
                    ),
                  )
                  .toList(),
              onChanged: chargementCreation
                  ? null
                  : (value) {
                      setState(() {
                        niveauSelectionne = value;
                      });
                    },
            ),

            const SizedBox(height: 20),

            const Text(
              "Titre du devoir",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: titreController,
              enabled: !chargementCreation,
              decoration: const InputDecoration(
                hintText: "Exemple : Devoir Big Data",
                prefixIcon: Icon(Icons.title),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Questions ouvertes",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (!chargementQuestions)
                  Text(
                    "${questionsSelectionnees.length} sélectionnée(s)",
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),

            const SizedBox(height: 15),

            construireQuestions(),

            const SizedBox(height: 30),

            if (questionsSelectionnees.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${questionsSelectionnees.length}"
                          " question(s) sélectionnée(s)",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: chargementCreation ? null : creerDevoir,
                child: chargementCreation
                    ? const SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "CRÉER LE DEVOIR",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}