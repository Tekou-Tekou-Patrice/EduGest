import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
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
  RecapAnnees({super.key, required this.currentUser});

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
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          SizedBox(height: 20),
          if (!_isLoading && _recaps.isNotEmpty) ...[
            _buildGlobalKpis(isMobile, isTablet),
            SizedBox(height: 25),
          ],
          _buildSearchBar(),
          SizedBox(height: 20),
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_filteredRecaps.isEmpty)
            _buildEmptyState()
          else
            _buildRecapsList(isMobile),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.history_edu, color: AppColors.primary, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('pastYearsRecap'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  context.tr('founderRecapDescription'),
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
            tooltip: context.tr('refreshArchives'),
            icon: Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalKpis(bool isMobile, bool isTablet) {
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: isMobile ? 2.8 : 1.6,
      children: [
        _kpiCard(
          title: context.tr('archivedYears'),
          value: "${_recaps.length}",
          icon: Icons.inventory_2_outlined,
          color: Colors.indigo,
          subtitle: context.tr('closedSchoolYears'),
        ),
        _kpiCard(
          title: context.tr('cumulativeRevenue'),
          value: "${_totalHistoricalRevenue.round()} FCFA",
          icon: Icons.monetization_on_outlined,
          color: Colors.green,
          subtitle: context.tr('archivedCollections'),
        ),
        _kpiCard(
          title: context.tr('historicalNetBalance'),
          value: "${_totalHistoricalBalance.round()} FCFA",
          icon: Icons.account_balance_wallet_outlined,
          color: _totalHistoricalBalance >= 0 ? Colors.teal : Colors.deepOrange,
          subtitle: context.tr('consolidatedProfit'),
        ),
        _kpiCard(
          title: context.tr('enrolledStudents'),
          value: "$_totalHistoricalStudents",
          icon: Icons.school_outlined,
          color: Colors.blue,
          subtitle: context.tr('cumulativeEnrollments'),
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
      padding: EdgeInsets.all(16),
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
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
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
          SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
          hintText: context.tr('searchArchivedSchools'),
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.archive_outlined,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          SizedBox(height: 20),
          Text(
            context.tr('noArchivedYears'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 10),
          Text(
            context.tr('noArchivedYearsDescription'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapsList(bool isMobile) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _filteredRecaps.length,
      separatorBuilder: (_, _) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        final recap = _filteredRecaps[index];
        return _buildRecapCard(recap, isMobile);
      },
    );
  }

  Widget _buildRecapCard(AcademicYearRecap recap, bool isMobile) {
    final schoolName =
        recap.schoolName ?? _schoolInfo?.name ?? context.tr('mySchool');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "${context.tr('session')} ${recap.label}",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    context.tr('archived'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Text(
                  "${context.tr('closedOn')} ${recap.formattedClosedAt}",
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              schoolName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            Text(
              "${context.tr('officialPeriod')} : du ${recap.formattedStartDate} au ${recap.formattedEndDate}",
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            SizedBox(height: 18),
            Divider(height: 1),
            SizedBox(height: 18),

            // Statistics Grid inside Card
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _metricItem(
                  icon: Icons.payments,
                  label: context.tr('realizedRevenue'),
                  value: recap.formattedRevenue,
                  color: Colors.green,
                ),
                _metricItem(
                  icon: Icons.money_off,
                  label: context.tr('incurredExpenses'),
                  value: recap.formattedExpenses,
                  color: Colors.redAccent,
                ),
                _metricItem(
                  icon: Icons.savings,
                  label: context.tr('finalNetBalance'),
                  value: recap.formattedBalance,
                  color: recap.balance >= 0 ? Colors.teal : Colors.deepOrange,
                  isBold: true,
                ),
                _metricItem(
                  icon: Icons.school,
                  label: context.tr('studentCount'),
                  value:
                      "${recap.studentCount} ${context.tr('students').toLowerCase()}",
                  color: Colors.blue,
                ),
                _metricItem(
                  icon: Icons.person_outline,
                  label: context.tr('teachingStaff'),
                  value: "${recap.teacherCount} profs",
                  color: Colors.purple,
                ),
                _metricItem(
                  icon: Icons.menu_book,
                  label: context.tr('lessonsTaught'),
                  value:
                      "${recap.lessonCount} ${context.tr('courses').toLowerCase()}",
                  color: Colors.indigo,
                ),
                _metricItem(
                  icon: Icons.assignment_turned_in,
                  label: context.tr('evaluationsExams'),
                  value:
                      "${recap.examCount} ${context.tr('exams').toLowerCase()}",
                  color: Colors.orange,
                ),
                _metricItem(
                  icon: Icons.gavel,
                  label: context.tr('absencesSanctions'),
                  value:
                      "${recap.absenceCount} abs. / ${recap.sanctionCount} sanc.",
                  color: Colors.blueGrey,
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(height: 1),
            SizedBox(height: 16),

            // Actions
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDetailedDialog(recap),
                  icon: Icon(Icons.info_outline, size: 16),
                  label: Text(context.tr('viewDetails')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ExportService.generateYearRecapPdf(
                      yearRecap: recap,
                      schoolInfo: _schoolInfo,
                    );
                  },
                  icon: Icon(
                    Icons.picture_as_pdf,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    context.tr('downloadPdfReport'),
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 10),
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
                SizedBox(height: 2),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.assessment, color: AppColors.primary),
              SizedBox(width: 10),
              Text("${context.tr('annualReview')} — ${recap.label}"),
            ],
          ),
          content: SizedBox(
            width: (MediaQuery.sizeOf(context).width - 80).clamp(280.0, 500.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${context.tr('schoolLabel')} : $schoolName",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${context.tr('periodLabel')} : du ${recap.formattedStartDate} au ${recap.formattedEndDate}",
                  ),
                  Text(
                    "${context.tr('savedAndClosedOn')} ${recap.formattedClosedAt}",
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 10),
                  Text(
                    context.tr('financialSection'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 8),
                  _detailRow(
                    context.tr('totalRevenue'),
                    recap.formattedRevenue,
                  ),
                  _detailRow(
                    context.tr('totalExpenses'),
                    recap.formattedExpenses,
                  ),
                  _detailRow(
                    context.tr('netBalance'),
                    recap.formattedBalance,
                    isBold: true,
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 10),
                  Text(
                    context.tr('academicSection'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 8),
                  _detailRow(
                    context.tr('enrolledStudentsLabel'),
                    "${recap.studentCount}",
                  ),
                  _detailRow(
                    context.tr('activeTeachersLabel'),
                    "${recap.teacherCount}",
                  ),
                  _detailRow(
                    context.tr('lessonsLabel'),
                    "${recap.lessonCount}",
                  ),
                  _detailRow(
                    context.tr('organizedExamsLabel'),
                    "${recap.examCount}",
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 10),
                  Text(
                    context.tr('disciplineSection'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 8),
                  _detailRow(
                    context.tr('totalAbsences'),
                    "${recap.absenceCount}",
                  ),
                  _detailRow(
                    context.tr('totalSanctions'),
                    "${recap.sanctionCount}",
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('close')),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await ExportService.generateYearRecapPdf(
                  yearRecap: recap,
                  schoolInfo: _schoolInfo,
                );
              },
              icon: Icon(Icons.print, size: 16, color: Colors.white),
              label: Text(
                context.tr('printPdf'),
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
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
