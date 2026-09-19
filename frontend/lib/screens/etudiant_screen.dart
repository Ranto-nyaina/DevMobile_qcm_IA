import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'liste_devoirs_screen.dart';
import 'qcm_screen.dart';

// ================================================================
// ECRAN PRINCIPAL ETUDIANT
// ================================================================

class EtudiantScreen extends StatelessWidget {
  const EtudiantScreen({super.key});

  // ==========================================================
  // DECONNEXION
  // ==========================================================

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

  // ==========================================================
  // MODIFICATION PROFIL
  // ==========================================================

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

  // ==========================================================
  // BOUTON GENERIQUE
  // ==========================================================

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

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace étudiant"),
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
            const Icon(Icons.school, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Bienvenue dans votre espace étudiant",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            _bouton(
              context,
              icon: Icons.assignment,
              texte: "Mes devoirs",
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
              icon: Icons.quiz,
              texte: "Faire un QCM",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _QCMListeScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            _bouton(
              context,
              icon: Icons.bar_chart,
              texte: "Mes résultats",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _TableauDeBordScreen(),
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
// LISTE DES QCM DISPONIBLES
// ================================================================

class _QCMListeScreen extends StatefulWidget {
  const _QCMListeScreen();

  @override
  State<_QCMListeScreen> createState() => _QCMListeScreenState();
}

class _QCMListeScreenState extends State<_QCMListeScreen> {
  late Future<List<dynamic>> qcmListe;

  @override
  void initState() {
    super.initState();
    qcmListe = ApiService.getQCM();
  }

  void _recharger() {
    setState(() {
      qcmListe = ApiService.getQCM();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QCM disponibles"),
      ),
      body: FutureBuilder<List<dynamic>>(
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
            return const Center(
              child: Text("Aucun QCM disponible pour le moment."),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _recharger(),
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: qcms.length,
              itemBuilder: (context, index) {
                final qcm = qcms[index] as Map<String, dynamic>;

                final id = qcm["id"];
                final titre = qcm["titre"]?.toString() ?? "QCM sans titre";
                final nombreQuestions =
                  (qcm["questions"] as List?)?.length ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.quiz, size: 36),
                    title: Text(
                      titre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("$nombreQuestions question(s)"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: id == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QCMScreen(
                                  qcmId: int.parse(id.toString()),
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
    );
  }
}

// ================================================================
// TABLEAU DE BORD - RESULTATS DE L'ETUDIANT
// ================================================================

class _TableauDeBordScreen extends StatefulWidget {
  const _TableauDeBordScreen();

  @override
  State<_TableauDeBordScreen> createState() => _TableauDeBordScreenState();
}

class _TableauDeBordScreenState extends State<_TableauDeBordScreen> {
  late Future<_DonneesTableauDeBord> donnees;

  @override
  void initState() {
    super.initState();
    donnees = _chargerDonnees();
  }

  void _recharger() {
    setState(() {
      donnees = _chargerDonnees();
    });
  }

  // ==========================================================
  // CHARGEMENT : devoirs + résultats des devoirs terminés
  //
  // ATTENTION PERFORMANCE :
  // Il n'existe pas d'endpoint backend agrégé pour ce tableau
  // de bord. On récupère donc la liste des devoirs, puis on
  // appelle getResultatDevoir() séparément pour chaque devoir
  // terminé. Avec un grand nombre de devoirs, ça fait beaucoup
  // de requêtes HTTP séquentielles/parallèles. Si ça devient
  // un problème de performance, il faudra créer un endpoint
  // backend dédié qui fait l'agrégation côté serveur.
  // ==========================================================

  Future<_DonneesTableauDeBord> _chargerDonnees() async {
    final devoirs = await ApiService.getDevoirs();

    final devoirsTermines = devoirs
        .cast<Map<String, dynamic>>()
        .where((d) => d["termine"] == true)
        .toList();

    final resultats = await Future.wait(
      devoirsTermines.map((d) async {
        try {
          final resultat = await ApiService.getResultatDevoir(
            devoirId: int.parse(d["id"].toString()),
          );
          return resultat;
        } catch (_) {
          return null;
        }
      }),
    );

    final notesValides = resultats
        .where((r) => r != null)
        .map((r) => double.tryParse(r!["note_finale"].toString()) ?? 0.0)
        .toList();

    final double moyenne = notesValides.isEmpty
        ? 0.0
        : notesValides.reduce((a, b) => a + b) / notesValides.length;

    return _DonneesTableauDeBord(
      devoirs: devoirs.cast<Map<String, dynamic>>(),
      resultatsTermines: resultats.whereType<Map<String, dynamic>>().toList(),
      moyenneGenerale: moyenne,
    );
  }

  String _appreciation(double note) {
    if (note >= 16) return "Très bien";
    if (note >= 14) return "Bien";
    if (note >= 10) return "Passable";
    return "Insuffisant";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes résultats"),
      ),
      body: FutureBuilder<_DonneesTableauDeBord>(
        future: donnees,
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

          final data = snapshot.data;

          if (data == null || data.devoirs.isEmpty) {
            return const Center(
              child: Text("Aucun devoir pour le moment."),
            );
          }

          final total = data.devoirs.length;
          final termines = data.resultatsTermines.length;
          final enCours = total - termines;

          return RefreshIndicator(
            onRefresh: () async => _recharger(),
            child: ListView(
              padding: const EdgeInsets.all(15),
              children: [
                // ==========================================
                // RESUME
                // ==========================================

                Row(
                  children: [
                    Expanded(
                      child: _carteStat(
                        icon: Icons.assignment,
                        titre: "Total",
                        valeur: "$total",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _carteStat(
                        icon: Icons.check_circle,
                        titre: "Terminés",
                        valeur: "$termines",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _carteStat(
                        icon: Icons.hourglass_bottom,
                        titre: "En cours",
                        valeur: "$enCours",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          "Moyenne générale",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          termines == 0
                              ? "—"
                              : "${data.moyenneGenerale.toStringAsFixed(2)} / 20",
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (termines > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            _appreciation(data.moyenneGenerale),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Détail des devoirs",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // ==========================================
                // LISTE DES DEVOIRS
                // ==========================================

                ...data.devoirs.map((devoir) {
                  final termine = devoir["termine"] == true;

                  Map<String, dynamic>? resultat;
                  if (termine) {
                    try {
                      resultat = data.resultatsTermines.firstWhere(
                        (r) => r["devoir_id"].toString() ==
                            devoir["id"].toString(),
                      );
                    } catch (_) {
                      resultat = null;
                    }
                  }

                  final note = resultat != null
                      ? double.tryParse(
                          resultat["note_finale"].toString(),
                        )
                      : null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                        termine ? Icons.check_circle : Icons.pending,
                        color: termine ? Colors.green : Colors.orange,
                      ),
                      title: Text(
                        devoir["titre"]?.toString() ?? "Devoir",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        termine
                            ? (note != null
                                ? "Note : ${note.toStringAsFixed(2)} / 20"
                                : "Terminé")
                            : "En cours",
                      ),
                      trailing: termine
                          ? Text(
                              note != null ? _appreciation(note) : "",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _carteStat({
    required IconData icon,
    required String titre,
    required String valeur,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 6),
            Text(
              valeur,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              titre,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// MODELE DE DONNEES DU TABLEAU DE BORD
// ================================================================

class _DonneesTableauDeBord {
  final List<Map<String, dynamic>> devoirs;
  final List<Map<String, dynamic>> resultatsTermines;
  final double moyenneGenerale;

  _DonneesTableauDeBord({
    required this.devoirs,
    required this.resultatsTermines,
    required this.moyenneGenerale,
  });
}