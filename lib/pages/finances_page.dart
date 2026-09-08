import 'package:edugest/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:edugest/components/app_colors.dart';
import 'package:edugest/pages/paiements.dart';
import 'package:edugest/pages/depenses.dart';
import 'package:edugest/service/api_service.dart';

class FinancesPage extends StatefulWidget {
  final AppUser currentUser;
  const FinancesPage({super.key, required this.currentUser});

  @override
  State<FinancesPage> createState() => _FinancesPageState();
}

class _FinancesPageState extends State<FinancesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getFinanceStats();
      if (mounted) {
        setState(() {
          _stats = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Gestion Financière",
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: "Vue d'ensemble"),
            Tab(icon: Icon(Icons.payments_outlined), text: "Paiements"),
            Tab(
              icon: Icon(Icons.account_balance_wallet_outlined),
              text: "Dépenses",
            ),
          ],
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Paiements(currentUser: widget.currentUser),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Depenses(currentUser: widget.currentUser),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalRecettes = _stats['totalRevenue'] ?? _stats['totalIncomes'] ?? 0;
    final totalDepenses = _stats['totalExpenses'] ?? 0;
    final solde = (totalRecettes is num && totalDepenses is num)
        ? (totalRecettes - totalDepenses)
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Indicateurs Financiers Globales",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildFinanceCard(
                "Total Encaissé",
                "$totalRecettes FCFA",
                Icons.arrow_downward,
                Colors.green,
              ),
              _buildFinanceCard(
                "Total Dépenses",
                "$totalDepenses FCFA",
                Icons.arrow_upward,
                Colors.red,
              ),
              _buildFinanceCard(
                "Solde Net",
                "$solde FCFA",
                Icons.account_balance,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Accès Rapide",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchStats,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryPale,
                    child: Icon(Icons.payments, color: AppColors.primary),
                  ),
                  title: const Text("Gérer les frais de scolarité"),
                  subtitle: const Text(
                    "Consulter et enregistrer les paiements d'élèves",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _tabController.animateTo(1),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryPale,
                    child: Icon(Icons.shopping_cart, color: AppColors.primary),
                  ),
                  title: const Text("Gérer les dépenses & factures"),
                  subtitle: const Text(
                    "Saisir et consulter les sorties de caisse",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _tabController.animateTo(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 64).clamp(220.0, 260.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
