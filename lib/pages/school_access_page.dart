import 'package:edugest/components/app_colors.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/pages/home_router.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/material.dart';

class SchoolAccessPage extends StatefulWidget {
  final AppUser user;

  const SchoolAccessPage({super.key, required this.user});

  @override
  State<SchoolAccessPage> createState() => _SchoolAccessPageState();
}

class _SchoolAccessPageState extends State<SchoolAccessPage> {
  final _codeController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _schoolCodeController = TextEditingController();
  bool _isSubmitting = false;
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _schoolNameController.dispose();
    _schoolCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinSchool() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showMessage("Veuillez saisir le code de l'école.");
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService.joinSchoolByCode(
        userId: widget.user.id,
        code: code,
        role: _selectedRole,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous avez rejoint cette école.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _showMessage('Impossible de rejoindre cette école: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createSchool() async {
    final name = _schoolNameController.text.trim();
    final code = _schoolCodeController.text.trim();
    if (name.isEmpty || code.isEmpty) {
      _showMessage("Veuillez renseigner le nom et le code de l'école.");
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final schoolId = await ApiService.createSchool(
        userId: widget.user.id,
        name: name,
        code: code,
      );
      if (!mounted) return;
      ApiService.setActiveSchool(schoolId);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeRouter(
            userRole: UserRole.fondateur.name,
            user: widget.user.copyWith(role: UserRole.fondateur),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage('Impossible de créer cette école: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Rejoindre ou créer une école')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Accéder à une école',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Utilisez le code communiqué par votre établissement ou créez votre propre école.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rôle dans cette école',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: const [
                    DropdownMenuItem(value: UserRole.proviseur, child: Text('Proviseur')),
                    DropdownMenuItem(value: UserRole.censeur, child: Text('Censeur')),
                    DropdownMenuItem(value: UserRole.secretaire, child: Text('Secrétaire')),
                    DropdownMenuItem(value: UserRole.comptable, child: Text('Comptable')),
                    DropdownMenuItem(value: UserRole.enseignant, child: Text('Enseignant')),
                    DropdownMenuItem(value: UserRole.parent, child: Text('Parent')),
                    DropdownMenuItem(value: UserRole.fondateur, child: Text('Fondateur')),
                    DropdownMenuItem(value: UserRole.surveillantGeneral, child: Text('Surveillant Général')),
                    DropdownMenuItem(value: UserRole.membre, child: Text('Membre')),
                  ],
                  onChanged: (role) {
                    if (role != null) {
                      setState(() => _selectedRole = role);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: "Code de l'école",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _joinSchool,
                  icon: const Icon(Icons.login),
                  label: const Text('Se connecter par code'),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),
                const Text(
                  'Créer une école',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _schoolNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la nouvelle école',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _schoolCodeController,
                  decoration: const InputDecoration(
                    labelText: "Code privé de l'école",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _createSchool,
                  icon: const Icon(Icons.add_business),
                  label: const Text("Créer l'école"),
                ),
                if (_isSubmitting) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
