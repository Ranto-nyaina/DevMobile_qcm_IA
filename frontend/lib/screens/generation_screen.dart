import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'inscription_screen.dart' show kNiveaux;

class GenerationScreen extends StatefulWidget {
  const GenerationScreen({super.key});

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen> {
  final titreController = TextEditingController();
  final texteController = TextEditingController();

  int nombreQuestions = 5;
  String? niveau;
  bool chargement = false;

  bool _verifierNiveau() {
    if (niveau == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner un niveau."),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> genererDepuisPDF() async {
    if (!_verifierNiveau()) return;

    setState(() {
      chargement = true;
    });

    try {
      final resultat = await ApiService.genererQCMPDF(
        titre: titreController.text.trim().isEmpty
            ? "QCM depuis PDF"
            : titreController.text.trim(),
        nombreQuestions: nombreQuestions,
        niveau: niveau!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("QCM généré depuis le PDF !"),
        ),
      );

      Navigator.pop(context, resultat);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          chargement = false;
        });
      }
    }
  }

  Future<void> generer() async {
    if (titreController.text.trim().isEmpty ||
        texteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs."),
        ),
      );
      return;
    }

    if (!_verifierNiveau()) return;

    setState(() {
      chargement = true;
    });

    try {
      final resultat = await ApiService.genererQCM(
        titre: titreController.text.trim(),
        texte: texteController.text.trim(),
        nombreQuestions: nombreQuestions,
        niveau: niveau!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("QCM généré avec succès !"),
        ),
      );

      Navigator.pop(context, resultat);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          chargement = false;
        });
      }
    }
  }

  @override
  void dispose() {
    titreController.dispose();
    texteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Générer un QCM"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Titre du QCM",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titreController,
              decoration: const InputDecoration(
                hintText: "Exemple : Introduction au Big Data",
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Niveau",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: niveau,
              decoration: const InputDecoration(
                hintText: "Sélectionner un niveau",
              ),
              items: kNiveaux
                  .map(
                    (n) => DropdownMenuItem(
                      value: n,
                      child: Text(n),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  niveau = value;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Cours / Texte",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: texteController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: "Collez ici votre cours...",
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Nombre de questions",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            DropdownButton<int>(
              value: nombreQuestions,
              items: [3, 5, 10, 15, 20]
                  .map(
                    (nombre) => DropdownMenuItem(
                      value: nombre,
                      child: Text("$nombre questions"),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    nombreQuestions = value;
                  });
                }
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: chargement ? null : generer,
                child: chargement
                    ? const CircularProgressIndicator()
                    : const Text("GÉNÉRER LE QCM"),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: chargement ? null : genererDepuisPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("IMPORTER UN PDF"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}