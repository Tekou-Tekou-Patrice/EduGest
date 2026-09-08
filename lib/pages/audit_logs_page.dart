import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/app_colors.dart';
import '../models/app_user.dart';
import '../models/audit_log.dart';
import '../service/api_service.dart';

class AuditLogsPage extends StatefulWidget {
  final AppUser currentUser;
  const AuditLogsPage({super.key, required this.currentUser});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  List<AuditLog> _logs = [];
  bool _isLoading = true;
  String _selectedEntityType = 'TOUS';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'key': 'TOUS', 'label': 'Toutes les actions'},
    {'key': 'NOTE', 'label': 'Notes'},
    {'key': 'CAHIER_TEXTE', 'label': 'Cahier de texte'},
    {'key': 'PAIEMENT', 'label': 'Paiements'},
    {'key': 'BULLETIN', 'label': 'Bulletins'},
    {'key': 'EVALUATION', 'label': 'Évaluations'},
    {'key': 'DEPENSE', 'label': 'Dépenses'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAuditLogs(
        entityType: _selectedEntityType == 'TOUS' ? null : _selectedEntityType,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _logs = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement journal d\'audit: $e')),
      );
    }
  }

  Color _actionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Colors.green;
      case 'UPDATE':
        return Colors.blue;
      case 'DELETE':
        return Colors.red;
      case 'PUBLISH':
        return Colors.purple;
      case 'UNPUBLISH':
        return Colors.orange;
      case 'EXPORT':
      case 'IMPORT':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  IconData _actionIcon(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Icons.add_circle_outline;
      case 'UPDATE':
        return Icons.edit_outlined;
      case 'DELETE':
        return Icons.delete_outline;
      case 'PUBLISH':
        return Icons.verified_outlined;
      case 'UNPUBLISH':
        return Icons.unpublished_outlined;
      case 'EXPORT':
        return Icons.download_outlined;
      case 'IMPORT':
        return Icons.upload_outlined;
      default:
        return Icons.history;
    }
  }

  String _actionLabel(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return 'Création';
      case 'UPDATE':
        return 'Modification';
      case 'DELETE':
        return 'Suppression';
      case 'PUBLISH':
        return 'Publication';
      case 'UNPUBLISH':
        return 'Retrait';
      case 'EXPORT':
        return 'Exportation';
      case 'IMPORT':
        return 'Restauration';
      default:
        return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Journal d'Audit & Historique des Actions",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Traçabilité complète des créations, modifications et suppressions",
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
            IconButton.filledTonal(
              onPressed: _fetchLogs,
              icon: const Icon(Icons.refresh),
              tooltip: "Rafraîchir",
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Barre de recherche et filtres de catégorie
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText:
                      "Rechercher par auteur, description, élève, matière...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _fetchLogs();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _fetchLogs(),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedEntityType == cat['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat['label']!),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedEntityType = cat['key']!);
                            _fetchLogs();
                          }
                        },
                        selectedColor: AppColors.primaryPale,
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color:
                              isSelected ? AppColors.primary : AppColors.text,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Liste des logs
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_logs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text(
                    "Aucune action enregistrée pour ces critères.",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Les opérations de saisie de notes, cahiers de texte, paiements et publications apparaîtront ici.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = _logs[index];
              final color = _actionColor(log.action);
              final icon = _actionIcon(log.action);
              final hasComparison = (log.oldValue != null &&
                      log.oldValue!.trim().isNotEmpty) ||
                  (log.newValue != null && log.newValue!.trim().isNotEmpty);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête : Badge Action, Date et Auteur
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, color: color, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  _actionLabel(log.action),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.entityType,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('dd/MM/yyyy à HH:mm:ss')
                                .format(log.timestamp),
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description de l'action
                      Text(
                        log.description,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Auteur et rôle
                      Row(
                        children: [
                          const Icon(Icons.person_pin,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            "Effectué par : ${log.performedBy}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (log.performedByRole.isNotEmpty) ...[
                            Text(
                              " • ${log.performedByRole}",
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Comparaison ancienne/nouvelle valeur
                      if (hasComparison) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (log.oldValue != null &&
                                  log.oldValue!.trim().isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Ancienne valeur : ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        log.oldValue!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade900,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                              if (log.newValue != null &&
                                  log.newValue!.trim().isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Nouvelle valeur : ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        log.newValue!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
