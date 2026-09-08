import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/app_colors.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../models/payment.dart';
import '../models/app_user.dart';
import '../models/student.dart';
import '../models/school_class.dart';
import '../service/api_service.dart';
import '../service/export_service.dart';

class Paiements extends StatefulWidget {
  final AppUser currentUser;
  const Paiements({super.key, required this.currentUser});

  @override
  State<Paiements> createState() => _PaiementsState();
}

class _PaiementsState extends State<Paiements> {
  List<Payment> _payments = [];
  bool _isLoading = true;
  double totalEncaisse = 0;
  double totalDepenses = 0;
  int _paymentMode = 0;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getPayments();
      Map<String, dynamic> stats = {};
      try {
        stats = await ApiService.getFinanceStats();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _payments = data;
        totalEncaisse =
            (stats['totalRevenue'] as num?)?.toDouble() ??
            data.fold(0.0, (sum, item) => sum + item.amount);
        totalDepenses = (stats['totalExpenses'] as num?)?.toDouble() ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors du chargement des paiements"),
        ),
      );
    }
  }

  void _showAddDialog({required bool schoolFees}) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController(
      text: schoolFees ? 'Frais de scolarité' : 'Paiement simple',
    );
    Student? selectedStudent;
    List<Student> matches = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: Text(
            schoolFees
                ? "Enregistrer les frais de scolarité"
                : "Enregistrer un paiement simple",
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (schoolFees)
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Rechercher un élève existant",
                      hintText: "Nom ou matricule",
                      prefixIcon: const Icon(Icons.person_search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) async {
                      selectedStudent = null;
                      if (value.trim().length < 2) {
                        dialogSetState(() => matches = []);
                        return;
                      }
                      dialogSetState(() => isSearching = true);
                      try {
                        final students = await ApiService.getStudents(
                          query: value.trim(),
                        );
                        if (context.mounted) {
                          dialogSetState(() => matches = students);
                        }
                      } finally {
                        if (context.mounted) {
                          dialogSetState(() => isSearching = false);
                        }
                      }
                    },
                  )
                else
                  MyTextfield(
                    controller: nameCtrl,
                    hintText: "Nom du payeur / élève",
                    icon: Icons.person,
                  ),
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
                if (matches.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: matches
                          .map(
                            (student) => ListTile(
                              dense: true,
                              title: Text(student.fullName),
                              subtitle: Text(
                                '${student.className} • ${student.id}',
                              ),
                              onTap: () async {
                                nameCtrl.text = student.fullName;
                                dialogSetState(() {
                                  selectedStudent = student;
                                  matches = [];
                                });
                                try {
                                  final classes =
                                      await ApiService.getClassrooms();
                                  SchoolClass? schoolClass;
                                  for (final item in classes) {
                                    if (item.name == student.className) {
                                      schoolClass = item;
                                      break;
                                    }
                                  }
                                  if (schoolClass != null &&
                                      schoolClass.tuitionFee > 0) {
                                    amountCtrl.text = schoolClass.tuitionFee
                                        .toStringAsFixed(0);
                                  }
                                } catch (_) {}
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 12),
                MyTextfield(
                  controller: amountCtrl,
                  hintText: "Montant",
                  icon: Icons.payments,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                MyTextfield(
                  controller: descCtrl,
                  hintText: "Description",
                  icon: Icons.notes,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                final amount = double.tryParse(
                  amountCtrl.text.replaceAll(',', '.'),
                );
                if (nameCtrl.text.trim().isEmpty ||
                    amount == null ||
                    (schoolFees && selectedStudent == null)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        schoolFees
                            ? "Sélectionnez un élève existant et un montant."
                            : "Indiquez le payeur et un montant.",
                      ),
                    ),
                  );
                  return;
                }
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                try {
                  final newPayment = Payment(
                    id: '',
                    studentId: selectedStudent?.id ?? 'SIMPLE',
                    studentName: nameCtrl.text.trim(),
                    amount: amount,
                    date: DateTime.now(),
                    description: descCtrl.text.trim(),
                    recordedById: widget.currentUser.id,
                    recordedByName: widget.currentUser.name,
                  );
                  final savedPayment = await ApiService.savePayment(newPayment);
                  nav.pop();
                  await _fetchPayments();

                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text("Paiement enregistré avec succès"),
                        action: SnackBarAction(
                          label: "TICKET 80mm",
                          onPressed: () => ExportService.generateThermalReceipt(
                            payment: savedPayment,
                          ),
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text("Erreur d'enregistrement")),
                    );
                  }
                }
              },
              child: const Text(
                "Valider",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrintOptionsDialog(Payment p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Impression du reçu — ${p.studentName}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Montant : ${p.amount.toInt()} FCFA • ${p.description}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPale,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    "Imprimer Ticket Thermique (80mm)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    "Format rouleau thermique pour imprimante de caisse / POS",
                  ),
                  trailing: const Icon(Icons.print),
                  onTap: () {
                    Navigator.pop(context);
                    ExportService.generateThermalReceipt(payment: p);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  ),
                  title: const Text(
                    "Générer Reçu PDF Standard (A5)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    "Reçu de paiement au format A5 avec cadre de signature",
                  ),
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    Navigator.pop(context);
                    ExportService.generatePaymentReceipt(p);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            const Text(
              "Frais de Scolarité & Encaissements",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            MyButton(
              icon: Icons.add_card,
              text: _paymentMode == 0
                  ? "Paiement simple"
                  : "Frais de scolarité",
              onTap: () => _showAddDialog(schoolFees: _paymentMode == 1),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DefaultTabController(
          key: ValueKey(_paymentMode),
          length: 2,
          initialIndex: _paymentMode,
          child: TabBar(
            onTap: (index) => setState(() => _paymentMode = index),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(
                icon: Icon(Icons.point_of_sale_outlined),
                text: "Paiement simple",
              ),
              Tab(
                icon: Icon(Icons.school_outlined),
                text: "Frais de scolarité",
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _paymentMode == 0
                ? "Encaissez un paiement libre avec son motif."
                : "Recherchez d'abord l'élève : la pension de sa classe est proposée automatiquement.",
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildFinanceCard(
              "Encaissé",
              "${totalEncaisse.toInt()} F",
              Colors.green,
            ),
            _buildFinanceCard(
              "Dépenses",
              "${totalDepenses.toInt()} F",
              Colors.orange,
            ),
            _buildFinanceCard(
              "Solde",
              "${(totalEncaisse - totalDepenses).toInt()} F",
              Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Text(
          "Derniers Paiements Enregistrés",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_payments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text("Aucun paiement"),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _payments.length,
            itemBuilder: (context, index) {
              final p = _payments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  onTap: () => _showPrintOptionsDialog(p),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                    child: const Icon(Icons.payments, color: Colors.green),
                  ),
                  title: Text(
                    p.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${p.description} • ${DateFormat('dd/MM/yyyy').format(p.date)}",
                      ),
                      if (p.recordedByName != null)
                        Text(
                          "Encaissé par: ${p.recordedByName}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "+${p.amount.toInt()} F",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(
                          Icons.receipt_long,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        onPressed: () =>
                            ExportService.generateThermalReceipt(payment: p),
                        tooltip: "Ticket Thermique (Rouleau 80mm)",
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () =>
                            ExportService.generatePaymentReceipt(p),
                        tooltip: "Reçu PDF Standard (A5)",
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFinanceCard(String title, String value, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
