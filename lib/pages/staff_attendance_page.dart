import 'package:edugest/localization/app_localizations.dart';
import 'package:edugest/models/app_user.dart';
import 'package:edugest/service/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StaffAttendancePage extends StatefulWidget {
  final AppUser currentUser;

  const StaffAttendancePage({super.key, required this.currentUser});

  @override
  State<StaffAttendancePage> createState() => _StaffAttendancePageState();
}

class _StaffAttendancePageState extends State<StaffAttendancePage> {
  late final bool _canShowQr;
  late final bool _canViewReport;
  late int _selectedTab;
  DateTime _month = DateTime.now();
  Map<String, dynamic>? _qr;
  List<Map<String, dynamic>> _records = [];
  bool _qrLoading = false;
  bool _reportLoading = false;
  bool _processingScan = false;
  bool _scanComplete = false;
  String? _qrError;
  String? _scanMessage;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final role = widget.currentUser.role;
    _canShowQr = {
      UserRole.fondateur,
      UserRole.proviseur,
      UserRole.secretaire,
      UserRole.surveillantGeneral,
    }.contains(role);
    _canViewReport = {
      UserRole.fondateur,
      UserRole.proviseur,
      UserRole.secretaire,
      UserRole.surveillantGeneral,
      UserRole.censeur,
    }.contains(role);
    _selectedTab = _canShowQr ? 0 : 1;
    if (_canShowQr) _loadQr();
    if (_canViewReport) _loadReport();
  }

  Future<void> _loadQr() async {
    setState(() {
      _qrLoading = true;
      _qrError = null;
    });
    try {
      final qr = await ApiService.getStaffAttendanceQr();
      if (!mounted) return;
      setState(() {
        _qr = qr;
        _qrLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _qrError = ApiService.friendlyErrorMessage(error);
        _qrLoading = false;
      });
    }
  }

  Future<void> _loadReport() async {
    setState(() => _reportLoading = true);
    try {
      final records = await ApiService.getStaffAttendanceReport(_month);
      if (!mounted) return;
      setState(() {
        _records = records;
        _reportLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _reportLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.tr('staffAttendanceLoadError')}: '
            '${ApiService.friendlyErrorMessage(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _selectMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: context.tr('staffAttendanceMonth'),
    );
    if (selected == null || !mounted) return;
    setState(() => _month = DateTime(selected.year, selected.month));
    await _loadReport();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processingScan || _scanComplete) return;
    final token = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (token.isEmpty) return;

    setState(() => _processingScan = true);
    try {
      final result = await ApiService.scanStaffAttendanceQr(token);
      if (!mounted) return;
      final key = result['action'] == 'ARRIVAL'
          ? 'staffAttendancePointArrival'
          : 'staffAttendancePointDeparture';
      final monthlyMinutes = (result['monthlyTotalMinutes'] as num?)?.toInt();
      final durationMinutes = (result['durationMinutes'] as num?)?.toInt();
      await _scannerController.stop();
      if (!mounted) return;
      setState(() {
        _scanComplete = true;
        final details = <String>[];
        if (monthlyMinutes != null) {
          details.add(
            '${context.tr('staffAttendanceMonthlyTotal')}: '
            '${_formatDuration(monthlyMinutes)}',
          );
        }
        if (durationMinutes != null) {
          details.add(
            '${context.tr('staffAttendanceTodayTime')}: '
            '${_formatDuration(durationMinutes)}',
          );
        }
        _scanMessage = [context.tr(key), ...details].join('\n');
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_scanMessage ?? context.tr(key))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.friendlyErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _processingScan = false);
    }
  }

  Future<void> _scanAgain() async {
    try {
      await _scannerController.stop();
      await _scannerController.start();
      if (!mounted) return;
      setState(() {
        _scanComplete = false;
        _scanMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.friendlyErrorMessage(error))),
      );
    }
  }

  String _cameraErrorMessage(
    BuildContext context,
    MobileScannerException error,
  ) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => context.tr(
        'staffAttendanceCameraDenied',
      ),
      MobileScannerErrorCode.unsupported => context.tr(
        'staffAttendanceCameraUnsupported',
      ),
      MobileScannerErrorCode.controllerInitializing => context.tr(
        'staffAttendanceCameraStarting',
      ),
      _ => context.tr('staffAttendanceCameraError'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      if (_canShowQr) _tabButton(context, context.tr('staffAttendanceQr'), 0),
      _tabButton(context, context.tr('staffAttendanceScan'), 1),
      if (_canViewReport)
        _tabButton(context, context.tr('staffAttendanceReport'), 2),
    ];
    final selectedContent = _selectedTab == 0 && _canShowQr
        ? _buildQrTab(context)
        : _selectedTab == 2 && _canViewReport
        ? _buildReportTab(context)
        : _buildScannerTab(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(spacing: 8, runSpacing: 8, children: tabs),
        ),
        Expanded(child: selectedContent),
      ],
    );
  }

  Widget _tabButton(BuildContext context, String title, int index) {
    final selected = _selectedTab == index;
    return OutlinedButton.icon(
      onPressed: () {
        setState(() => _selectedTab = index);
        if (index == 0 && _qr == null && !_qrLoading) _loadQr();
        if (index == 2 && !_reportLoading) _loadReport();
      },
      icon: Icon(
        index == 0
            ? Icons.qr_code_2
            : index == 1
            ? Icons.qr_code_scanner
            : Icons.calendar_month,
      ),
      label: Text(title),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
      ),
    );
  }

  Widget _buildQrTab(BuildContext context) {
    if (_qrLoading) return const Center(child: CircularProgressIndicator());
    if (_qrError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${context.tr('staffAttendanceQrLoadError')}: $_qrError',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadQr,
                icon: const Icon(Icons.refresh),
                label: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      );
    }
    final token = _qr?['token']?.toString() ?? '';
    if (token.isEmpty) return const SizedBox.shrink();
    final date = DateTime.tryParse(_qr?['date']?.toString() ?? '');
    final formattedDate = date == null
        ? (_qr?['date']?.toString() ?? '')
        : _formatDate(context, date);
    final qrSize = (MediaQuery.sizeOf(context).width - 88)
        .clamp(180.0, 300.0)
        .toDouble();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('staffAttendanceSchool'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  _qr?['schoolName']?.toString() ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('${context.tr('staffAttendanceQrDate')} $formattedDate'),
                const SizedBox(height: 20),
                QrImageView(
                  data: token,
                  version: QrVersions.auto,
                  size: qrSize,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
                const SizedBox(height: 12),
                Text(context.tr('staffAttendanceAvailableAtSix')),
                const SizedBox(height: 12),
                IconButton(
                  tooltip: context.tr('refresh'),
                  onPressed: _loadQr,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerTab(BuildContext context) {
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.tr('staffAttendanceMobileScannerOnly'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            context.tr('staffAttendanceScanInstructions'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                        errorBuilder: (context, error) => ColoredBox(
                          color: Colors.black87,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.no_photography_outlined,
                                    color: Colors.white70,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _cameraErrorMessage(context, error),
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _scanAgain,
                                    icon: const Icon(Icons.refresh),
                                    label: Text(context.tr('retry')),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_processingScan)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        ),
                      if (_scanComplete)
                        Container(
                          color: Colors.black87,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.greenAccent,
                                size: 56,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _scanMessage ?? '',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: _scanAgain,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: Text(
                                  context.tr('staffAttendanceScanAgain'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('staffAttendanceCameraPermission'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportTab(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final record in _records) {
      final id = record['userId']?.toString() ?? '';
      grouped.putIfAbsent(id, () => []).add(record);
    }
    final people = grouped.values.toList()
      ..sort(
        (a, b) => (a.first['fullName'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo((b.first['fullName'] ?? '').toString().toLowerCase()),
      );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: OutlinedButton.icon(
            onPressed: _selectMonth,
            icon: const Icon(Icons.calendar_month),
            label: Text(
              '${context.tr('staffAttendanceMonth')}: '
              '${_monthName(context, _month.month)} ${_month.year}',
            ),
          ),
        ),
        if (_reportLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (people.isEmpty)
          Expanded(
            child: Center(child: Text(context.tr('staffAttendanceNoRecords'))),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: people.length,
              itemBuilder: (context, index) {
                final records = people[index];
                final first = records.first;
                final totalMinutes = records.fold<int>(
                  0,
                  (total, record) =>
                      total +
                      ((record['durationMinutes'] as num?)?.toInt() ?? 0),
                );
                return Card(
                  child: ExpansionTile(
                    title: Text(first['fullName']?.toString() ?? ''),
                    subtitle: Text(
                      '${first['role'] ?? ''} · '
                      '${context.tr('staffAttendanceTotalTime')}: '
                      '${_formatDuration(totalMinutes)}',
                    ),
                    children: records.map((record) {
                      final date = DateTime.tryParse(
                        record['date']?.toString() ?? '',
                      );
                      final checkIn = DateTime.tryParse(
                        record['checkInAt']?.toString() ?? '',
                      );
                      final checkOut = DateTime.tryParse(
                        record['checkOutAt']?.toString() ?? '',
                      );
                      return ListTile(
                        dense: true,
                        title: Text(
                          date == null
                              ? record['date']?.toString() ?? ''
                              : _formatDate(context, date),
                        ),
                        subtitle: Text(
                          '${context.tr('staffAttendanceArrivalTime')}: '
                          '${_formatTime(checkIn)}  ·  '
                          '${context.tr('staffAttendanceDepartureTime')}: '
                          '${checkOut == null ? context.tr('staffAttendanceNoExit') : _formatTime(checkOut)}',
                        ),
                        trailing: Text(
                          record['durationMinutes'] == null
                              ? '—'
                              : _formatDuration(
                                  (record['durationMinutes'] as num).toInt(),
                                ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime? value) =>
      value == null ? '—' : DateFormat.Hm().format(value.toLocal());

  String _formatDate(BuildContext context, DateTime date) {
    final month = _monthName(context, date.month);
    if (Localizations.localeOf(context).languageCode == 'en') {
      return '$month ${date.day}, ${date.year}';
    }
    return '${date.day} $month ${date.year}';
  }

  String _monthName(BuildContext context, int month) {
    const monthKeys = [
      'monthJanuary',
      'monthFebruary',
      'monthMarch',
      'monthApril',
      'monthMay',
      'monthJune',
      'monthJuly',
      'monthAugust',
      'monthSeptember',
      'monthOctober',
      'monthNovember',
      'monthDecember',
    ];
    return context.tr(monthKeys[month - 1]);
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes.toString().padLeft(2, '0')}min';
  }
}
