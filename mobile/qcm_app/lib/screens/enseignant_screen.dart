import 'package:flutter/material.dart';

import 'generation_screen.dart';
import 'creer_question_ouverte_screen.dart';
import 'liste_devoirs_screen.dart';
import 'plagiat_screen.dart';
import 'inscription_screen.dart' show kNiveaux;

import '../services/api_service.dart';

class EnseignantScreen extends StatelessWidget {
  const EnseignantScreen({super.key});

  Future<void> _deconnexion(BuildContext context) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Déconnexion"),
          content: const Text(
            "Voulez-vous vraiment vous déconnecter ?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Déconnexion"),
            ),
          ],
        );
      },
    );

    if (confirmation != true) return;

    await ApiService.deconnexion();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login",
      (route) => false,
    );
  }

  Future<void> _modifierProfil(BuildContext context) async {
    final profil = await ApiService.getProfilUtilisateur();

    if (!context.mounted) return;

    final usernameController = TextEditingController(
      text: profil["username"]?.toString() ?? "",
    );
    final emailController = TextEditingController(
      text: profil["email"]?.toString() ?? "",
    );
    final ancienMotDePasseController = TextEditingController();
    final nouveauMotDePasseController = TextEditingController();
    final confirmationMotDePasseController = TextEditingController();

    bool modifierMotDePasse = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Modifier mon profil"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: "Nom d'utilisateur",
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 15),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: modifierMotDePasse,
                      onChanged: (value) {
                        setState(() {
                          modifierMotDePasse = value ?? false;
                        });
                      },
                      title: const Text("Modifier le mot de passe"),
                    ),
                    if (modifierMotDePasse) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: ancienMotDePasseController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Ancien mot de passe",
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: nouveauMotDePasseController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Nouveau mot de passe",
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: confirmationMotDePasseController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Confirmer le nouveau mot de passe",
                          prefixIcon: Icon(Icons.lock_reset),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final username = usernameController.text.trim();
                    final email = emailController.text.trim();

                    if (username.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Le nom d'utilisateur est obligatoire.",
                          ),
                        ),
                      );
                      return;
                    }

                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("L'email est obligatoire."),
                        ),
                      );
                      return;
                    }

                    try {
                      await ApiService.modifierProfil(
                        username: username,
                        email: email,
                        ancienMotDePasse: modifierMotDePasse
                            ? ancienMotDePasseController.text
                            : null,
                        nouveauMotDePasse: modifierMotDePasse
                            ? nouveauMotDePasseController.text
                            : null,
                        confirmationMotDePasse: modifierMotDePasse
                            ? confirmationMotDePasseController.text
                            : null,
                      );

                      if (!context.mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profil modifié avec succès."),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst("Exception: ", ""),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text("Enregistrer"),
                ),
              ],
            );
          },
        );
      },
    );

    usernameController.dispose();
    emailController.dispose();
    ancienMotDePasseController.dispose();
    nouveauMotDePasseController.dispose();
    confirmationMotDePasseController.dispose();
  }

  Widget _bouton(
    BuildContext context, {
    required IconData icon,
    required String texte,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(texte),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace enseignant"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: "Mon profil",
            onPressed: () => _modifierProfil(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _deconnexion(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.person, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Espace enseignant",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            _bouton(
              context,
              icon: Icons.quiz,
              texte: "Gérer les QCM",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _GererQCMScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            _bouton(
              context,
              icon: Icons.add_comment,
              texte: "Gérer les questions ouvertes",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _GererQuestionsOuvertesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            _bouton(
              context,
              icon: Icons.assignment,
              texte: "Gérer les devoirs",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ListeDevoirsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            _bouton(
              context,
              icon: Icons.find_in_page,
              texte: "Détection de plagiat",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlagiatScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// GERER LES QCM
// ================================================================

class _GererQCMScreen extends StatefulWidget {
  const _GererQCMScreen();

  @override
  State<_GererQCMScreen> createState() => _GererQCMScreenState();
}

class _GererQCMScreenState extends State<_GererQCMScreen> {
  late Future<List<dynamic>> qcmListe;
  String? niveauFiltre;

  @override
  void initState() {
    super.initState();
    qcmListe = ApiService.getQCM();
  }

  void _recharger() {
    setState(() {
      qcmListe = ApiService.getQCM(niveau: niveauFiltre);
    });
  }

  Future<void> _supprimer(int id, String titre) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer le QCM"),
          content: Text(
            "Voulez-vous vraiment supprimer \"$titre\" ? "
            "Cette action est irréversible.",
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
      await ApiService.supprimerQCM(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QCM supprimé.")),
      );

      _recharger();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gérer les QCM"),
      ),
      body: Column(
        children: [
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
                });
                _recharger();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: qcmListe,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60),
                          const SizedBox(height: 15),
                          Text(
                            "Erreur : ${snapshot.error}",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _recharger,
                            child: const Text("Réessayer"),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final qcms = snapshot.data ?? [];

                if (qcms.isEmpty) {
                  return const Center(child: Text("Aucun QCM trouvé."));
                }

                return RefreshIndicator(
                  onRefresh: () async => _recharger(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: qcms.length,
                    itemBuilder: (context, index) {
                      final qcm = qcms[index] as Map<String, dynamic>;
                      final id = int.parse(qcm["id"].toString());
                      final titre = qcm["titre"]?.toString() ?? "QCM sans titre";
                      final niveau = qcm["niveau"]?.toString() ?? "";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.quiz),
                          title: Text(titre),
                          subtitle: niveau.isNotEmpty
                              ? Text("Niveau : $niveau")
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _supprimer(id, titre),
                          ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GenerationScreen(),
            ),
          );

          if (!mounted) return;

          _recharger();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ================================================================
// GERER LES QUESTIONS OUVERTES
// ================================================================

class _GererQuestionsOuvertesScreen extends StatefulWidget {
  const _GererQuestionsOuvertesScreen();

  @override
  State<_GererQuestionsOuvertesScreen> createState() =>
      _GererQuestionsOuvertesScreenState();
}

class _GererQuestionsOuvertesScreenState
    extends State<_GererQuestionsOuvertesScreen> {
  late Future<List<dynamic>> questionsListe;

  @override
  void initState() {
    super.initState();
    questionsListe = ApiService.getQuestionsOuvertes();
  }

  void _recharger() {
    setState(() {
      questionsListe = ApiService.getQuestionsOuvertes();
    });
  }

  Future<void> _supprimer(int id) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer la question"),
          content: const Text(
            "Voulez-vous vraiment supprimer cette question ? "
            "Cette action est irréversible.",
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
      await ApiService.supprimerQuestionOuverte(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Question supprimée.")),
      );

      _recharger();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gérer les questions ouvertes"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: questionsListe,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60),
                    const SizedBox(height: 15),
                    Text(
                      "Erreur : ${snapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _recharger,
                      child: const Text("Réessayer"),
                    ),
                  ],
                ),
              ),
            );
          }

          final questions = snapshot.data ?? [];

          if (questions.isEmpty) {
            return const Center(
              child: Text("Aucune question ouverte créée."),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _recharger(),
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index] as Map<String, dynamic>;
                final id = int.parse(question["id"].toString());
                final texte = question["question"]?.toString() ?? "";
                final points = question["points"]?.toString() ?? "0";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text(
                      texte,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text("$points point(s)"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _supprimer(id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreerQuestionOuverteScreen(),
            ),
          );

          if (!mounted) return;

          _recharger();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}