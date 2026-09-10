import 'package:flutter/material.dart';
import '../services/api_service.dart';

const List<String> kNiveaux = ["L1", "L2", "L3", "M1", "M2"];

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() =>
      _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _motDePasseController =
      TextEditingController();

  final TextEditingController _confirmationController =
      TextEditingController();

  String _role = "etudiant";
  String? _niveau;

  bool _chargement = false;
  bool _obscurcirMotDePasse = true;
  bool _obscurcirConfirmation = true;

  String? _erreur;

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _motDePasseController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _inscription() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_role == "etudiant" && _niveau == null) {
      setState(() {
        _erreur = "Veuillez sélectionner votre niveau.";
      });
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      await ApiService.inscrire(
        username: _nomController.text.trim(),
        email: _emailController.text.trim(),
        password: _motDePasseController.text,
        role: _role,
        niveau: _role == "etudiant" ? _niveau : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Inscription réussie. Vous pouvez maintenant vous connecter.",
          ),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        "/login",
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erreur = e
            .toString()
            .replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          _chargement = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inscription"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.person_add, size: 70),
                const SizedBox(height: 20),
                const Text(
                  "Créer un compte",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: "Nom d'utilisateur",
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Veuillez saisir votre nom d'utilisateur.";
                    }
                    if (value.trim().length < 3) {
                      return "Le nom doit contenir au moins 3 caractères.";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    hintText: "exemple@email.com",
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Veuillez saisir votre email.";
                    }
                    if (!value.contains("@")) {
                      return "Email invalide.";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: "Rôle",
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "etudiant",
                      child: Text("Étudiant"),
                    ),
                    DropdownMenuItem(
                      value: "enseignant",
                      child: Text("Enseignant"),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _role = value;
                        if (_role != "etudiant") {
                          _niveau = null;
                        }
                      });
                    }
                  },
                ),

                if (_role == "etudiant") ...[
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    initialValue: _niveau,
                    decoration: const InputDecoration(
                      labelText: "Niveau",
                      prefixIcon: Icon(Icons.grade),
                      hintText: "Sélectionner votre niveau",
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
                        _niveau = value;
                      });
                    },
                    validator: (value) {
                      if (_role == "etudiant" && value == null) {
                        return "Veuillez sélectionner un niveau.";
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 20),

                TextFormField(
                  controller: _motDePasseController,
                  obscureText: _obscurcirMotDePasse,
                  decoration: InputDecoration(
                    labelText: "Mot de passe",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurcirMotDePasse
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurcirMotDePasse = !_obscurcirMotDePasse;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Veuillez saisir un mot de passe.";
                    }
                    if (value.length < 4) {
                      return "Le mot de passe doit contenir au moins 4 caractères.";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _confirmationController,
                  obscureText: _obscurcirConfirmation,
                  decoration: InputDecoration(
                    labelText: "Confirmer le mot de passe",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurcirConfirmation
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurcirConfirmation = !_obscurcirConfirmation;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Veuillez confirmer le mot de passe.";
                    }
                    if (value != _motDePasseController.text) {
                      return "Les mots de passe ne correspondent pas.";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                if (_erreur != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.red.shade50,
                    ),
                    child: Text(
                      _erreur!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _chargement ? null : _inscription,
                    child: _chargement
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Créer mon compte",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: _chargement
                      ? null
                      : () {
                          Navigator.pushReplacementNamed(
                            context,
                            "/login",
                          );
                        },
                  child: const Text("J'ai déjà un compte"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}