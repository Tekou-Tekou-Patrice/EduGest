import 'package:flutter/material.dart';
import '../components/app_colors.dart';
import '../components/responsive_layout.dart';
import '../models/academic_year_recap.dart';
import '../models/app_user.dart';
import '../models/school_info.dart';
import '../service/api_service.dart';
import '../service/export_service.dart';
import '../service/school_notifier.dart';

class RecapAnnees extends StatefulWidget {
  final AppUser currentUser;
  const RecapAnnees({super.key, required this.currentUser});

  @override
  State<RecapAnnees> createState() => _RecapAnneesState();
}

class _RecapAnneesState extends State<RecapAnnees> {
  bool _isLoading = true;
  List<AcademicYearRecap> _recaps = [];
  String _searchQuery = '';
  SchoolInfo? _schoolInfo;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final recaps = await ApiService.getPastYearRecaps();
      final school = await ApiService.getSchoolInfo();
      if (mounted) {
        setState(() {
          _recaps = recaps;
          _schoolInfo = school;
          if (school != null) {
            currentSchoolNotifier.setSchoolInfo(school);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur récupération récaps: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AcademicYearRecap> get _filteredRecaps {
    if (_searchQuery.trim().isEmpty) return _recaps;
    final q = _searchQuery.toLowerCase().trim();
    return _recaps.where((r) {
      return r.label.toLowerCase().contains(q) ||
          (r.schoolName?.toLowerCase().contains(q) ?? false) ||
          r.formattedClosedAt.toLowerCase().contains(q);
    }).toList();
  }

  double get _totalHistoricalRevenue =>
      _recaps.fold(0.0, (sum, r) => sum + r.totalRevenue);

  double get _totalHistoricalBalance =>
      _recaps.fold(0.0, (sum, r) => sum + r.balance);

  int get _totalHistoricalStudents =>
      _recaps.fold(0, (sum, r) => sum + r.studentCount);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 20),
          if (!_isLoading && _recaps.isNotEmpty) ...[
            _buildGlobalKpis(isMobile, isTablet),
            const SizedBox(height: 25),
          ],
          _buildSearchBar(),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_filteredRecaps.isEmpty)
            _buildEmptyState()
          else
            _buildRecapsList(isMobile),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.history_edu, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Récapitulatif des Années Passées",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Espace Fondatrice — Bilan consolidé, statistiques et archives des sessions antérieures",
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: isMobile ? 12 : 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _fetchData,
            tooltip: "Actualiser les archives",
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalKpis(bool isMobile, bool isTablet) {
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: isMobile ? 2.8 : 1.6,
      children: [
        _kpiCard(
          title: "Années Archivées",
          value: "${_recaps.length}",
          icon: Icons.inventory_2_outlined,
          color: Colors.indigo,
          subtitle: "Sessions scolaires clôturées",
        ),
        _kpiCard(
          title: "Recettes Cumulées",
          value: "${_totalHistoricalRevenue.round()} FCFA",
          icon: Icons.monetization_on_outlined,
          color: Colors.green,
          subtitle: "Total des encaissements archivés",
        ),
        _kpiCard(
          title: "Solde Net Historique",
          value: "${_totalHistoricalBalance.round()} FCFA",
          icon: Icons.account_balance_wallet_outlined,
          color: _totalHistoricalBalance >= 0 ? Colors.teal : Colors.deepOrange,
          subtitle: "Bénéfice global consolidé",
        ),
        _kpiCard(
          title: "Élèves Accueillis",
          value: "$_totalHistoricalStudents",
          icon: Icons.school_outlined,
          color: Colors.blue,
          subtitle: "Total inscriptions cumulées",
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
          hintText: "Rechercher par année (ex: 2023-2024) ou nom d'établissement...",
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.archive_outlined, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            "Aucune année scolaire archivée",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 10),
          const Text(
            "Les récapitulatifs apparaîtront automatiquement ici dès qu'une année scolaire sera sauvegardée et clôturée dans les Paramètres.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapsList(bool isMobile) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredRecaps.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final recap = _filteredRecaps[index];
        return _buildRecapCard(recap, isMobile);
      },
    );
  }

  Widget _buildRecapCard(AcademicYearRecap recap, bool isMobile) {
    final schoolName = recap.schoolName ?? _schoolInfo?.name ?? "Mon École";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "Session ${recap.label}",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    "ARCHIVÉE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "Clôturée le ${recap.formattedClosedAt}",
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              schoolName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            Text(
              "Période officielle : du ${recap.formattedStartDate} au ${recap.formattedEndDate}",
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 18),

            // Statistics Grid inside Card
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _metricItem(
                  icon: Icons.payments,
                  label: "Recettes Réalisées",
                  value: recap.formattedRevenue,
                  color: Colors.green,
                ),
                _metricItem(
                  icon: Icons.money_off,
                  label: "Dépenses Engagées",
                  value: recap.formattedExpenses,
                  color: Colors.redAccent,
                ),
                _metricItem(
                  icon: Icons.savings,
                  label: "Solde Net Final",
                  value: recap.formattedBalance,
                  color: recap.balance >= 0 ? Colors.teal : Colors.deepOrange,
                  isBold: true,
                ),
                _metricItem(
                  icon: Icons.school,
                  label: "Effectif Élèves",
                  value: "${recap.studentCount} élèves",
                  color: Colors.blue,
                ),
                _metricItem(
                  icon: Icons.person_outline,
                  label: "Corps Enseignant",
                  value: "${recap.teacherCount} profs",
                  color: Colors.purple,
                ),
                _metricItem(
                  icon: Icons.menu_book,
                  label: "Leçons Dispensées",
                  value: "${recap.lessonCount} cours",
                  color: Colors.indigo,
                ),
                _metricItem(
                  icon: Icons.assignment_turned_in,
                  label: "Évaluations / Examens",
                  value: "${recap.examCount} examens",
                  color: Colors.orange,
                ),
                _metricItem(
                  icon: Icons.gavel,
                  label: "Absences / Sanctions",
                  value: "${recap.absenceCount} abs. / ${recap.sanctionCount} sanc.",
                  color: Colors.blueGrey,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDetailedDialog(recap),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text("Voir Détails"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ExportService.generateYearRecapPdf(
                      yearRecap: recap,
                      schoolInfo: _schoolInfo,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                  label: const Text("Télécharger Rapport PDF", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    color: AppColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedDialog(AcademicYearRecap recap) {
    showDialog(
      context: context,
      builder: (context) {
        final schoolName = recap.schoolName ?? _schoolInfo?.name ?? "EduGest";
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.assessment, color: AppColors.primary),
              const SizedBox(width: 10),
              Text("Bilan Annuel — ${recap.label}"),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Établissement : $schoolName", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Période : du ${recap.formattedStartDate} au ${recap.formattedEndDate}"),
                  Text("Sauvegardé et clôturé le : ${recap.formattedClosedAt}"),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text("1. Volet Financier", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  _detailRow("Recettes Totales :", recap.formattedRevenue),
                  _detailRow("Dépenses Totales :", recap.formattedExpenses),
                  _detailRow("Solde Net d'Exercice :", recap.formattedBalance, isBold: true),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text("2. Volet Pédagogique", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  _detailRow("Élèves Inscrits :", "${recap.studentCount}"),
                  _detailRow("Enseignants Actifs :", "${recap.teacherCount}"),
                  _detailRow("Séances de Cours :", "${recap.lessonCount}"),
                  _detailRow("Examens Organisés :", "${recap.examCount}"),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text("3. Volet Discipline", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  _detailRow("Total Absences :", "${recap.absenceCount}"),
                  _detailRow("Total Sanctions :", "${recap.sanctionCount}"),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await ExportService.generateYearRecapPdf(
                  yearRecap: recap,
                  schoolInfo: _schoolInfo,
                );
              },
              icon: const Icon(Icons.print, size: 16, color: Colors.white),
              label: const Text("Imprimer PDF", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
