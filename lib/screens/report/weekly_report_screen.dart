import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_pdf_generator/simple_pdf_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:homecare_app/providers/time_provider.dart';
import 'package:homecare_app/providers/report_provider.dart';
import 'package:homecare_app/widgets/custom_button.dart';
import 'package:homecare_app/widgets/loading_widget.dart';
import 'package:homecare_app/core/utils/globals.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  bool _isDownloading = false;
  String? _lastSavedPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
  }

  Future<void> _loadReport() async {
    final timeProvider = Provider.of<TimeProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (timeProvider.currentEntryId != null &&
        timeProvider.currentEntryId! > 0) {
      await reportProvider.getReport(timeProvider.currentEntryId!);
    }
  }

  // Check and request storage permission
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // First check if MANAGE_EXTERNAL_STORAGE is already granted (useful for Android 11+)
      if (await Permission.manageExternalStorage.isGranted) return true;

      // Request Storage Permission
      // Note: On Android 13+ (API 33), Permission.storage always returns denied.
      // However, FilePicker uses SAF (Storage Access Framework) which doesn't always need this.
      final status = await Permission.storage.request();

      if (status.isGranted) return true;

      // If it's Android 13 or newer, Permission.storage is deprecated and might be denied
      // but the FilePicker can still work. We only want to block if it's permanently denied
      // on older versions.
      if (status.isPermanentlyDenied) {
        if (mounted) {
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.security, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Permission Required'),
                ],
              ),
              content: const Text(
                'Storage access is required to save PDF files. '
                'Please enable it from app settings.',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                    openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          return result ?? false;
        }
      }

      // On Android 13+, even if 'storage' is denied, we can try to proceed
      // because FilePicker often works regardless as it uses a system activity.
      return true;
    } catch (e) {
      print('Permission request error: $e');
      return true; // Proceed anyway and let the picker/file write handle errors
    }
  }

  // Show directory picker and save PDF
  Future<void> _downloadReport() async {
    print('🔵 _downloadReport triggered');
    final timeProvider = Provider.of<TimeProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    if (timeProvider.currentEntryId == null ||
        timeProvider.currentEntryId! <= 0) {
      print('🟠 No currentEntryId found');
      Globals.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
              'No valid time entry found! Please finish your shift first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final hasPermission = await _requestStoragePermission();
    print('🔵 Permission status: $hasPermission');
    if (!hasPermission) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      if (reportProvider.report == null) {
        print('🔵 Generating report for ID: ${timeProvider.currentEntryId}');
        final response = await reportProvider.generateReport(
          timeProvider.currentEntryId!,
        );
        if (!response.status) {
          print('🔴 Report generation failed: ${response.message}');
          if (!mounted) return;
          setState(() {
            _isDownloading = false;
          });
          Globals.scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Generation failed: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final report = reportProvider.report!;
      print('✅ Report data ready');

      // Prepare PDF data
      final List<Map<String, dynamic>> tableData = [
        {
          'Field': 'Policyholder',
          'Detail': report.policyholder?['name']?.toString() ?? 'N/A'
        },
        {
          'Field': 'Policy #',
          'Detail': report.policyholder?['policy_number']?.toString() ?? 'N/A'
        },
        {'Field': 'Date', 'Detail': report.dateOfService ?? 'N/A'},
        {'Field': 'Time In', 'Detail': report.timeIn ?? 'N/A'},
        {'Field': 'Time Out', 'Detail': report.timeOut ?? 'N/A'},
        {
          'Field': 'Total Hours',
          'Detail': report.totalHours?.toStringAsFixed(2) ?? '0.00'
        },
        {
          'Field': 'Total Charge',
          'Detail': report.totalCharge?.toStringAsFixed(2) ?? '0.00'
        },
      ];

      // Add ADLs
      if (report.adls != null) {
        report.adls!.forEach((key, value) {
          if (key != 'id' &&
              key != 'time_entry_id' &&
              key != 'date' &&
              key != 'created_at') {
            final label = key
                .split('_')
                .map((e) => e[0].toUpperCase() + e.substring(1))
                .join(' ');
            tableData
                .add({'Field': label, 'Detail': value?.toString() ?? 'N/A'});
          }
        });
      }

      print('🔵 Starting PDF generation');
      final pdfDoc = await SimplePdf.generate(
        header: PdfHeader(
          title: 'Care Certification Report',
          subtitle: 'Generated on ${DateTime.now().toString().split('.')[0]}',
        ),
        tables: [
          PdfTable(
            headers: ['Field', 'Detail'],
            data: tableData,
          ),
        ],
      );

      final bytes = await pdfDoc.save();
      final fileName =
          'Homecare_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      print('✅ PDF document saved to bytes');

      String? selectedDirectory;

      if (Platform.isAndroid) {
        print('🔵 Opening directory picker...');
        try {
          selectedDirectory = await FilePicker.platform.getDirectoryPath(
            dialogTitle: 'Select folder to save PDF',
          );
          print('🔵 Picker result: $selectedDirectory');
        } catch (e) {
          print('🔴 Directory picker error: $e');
        }

        // If user cancelled the picker
        if (selectedDirectory == null) {
          print('🟠 User cancelled directory selection');
          if (mounted) {
            setState(() {
              _isDownloading = false;
            });
          }
          return;
        }
      }

      String finalPath;

      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        finalPath = '$selectedDirectory/$fileName';
      } else {
        // Fallback for non-Android or if picker is unavailable
        final directory = await getApplicationDocumentsDirectory();
        finalPath = '${directory.path}/$fileName';
      }

      print('🔵 Saving file to: $finalPath');
      final File file = File(finalPath);
      await file.writeAsBytes(bytes, flush: true);
      print('✅ File written successfully');

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _lastSavedPath = finalPath;
      });

      _showSuccessDialog(finalPath);
    } catch (e) {
      print('🔴 Download error: $e');
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
      });
      Globals.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Modern Success Dialog
  void _showSuccessDialog(String filePath) {
    final fileName = filePath.split('/').last;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '✅ PDF Saved Successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'File saved to:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                fileName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              filePath.replaceAll(fileName, ''),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openFile(filePath);
                    },
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('Open File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  // Open file with default app
  Future<void> _openFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        Globals.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('No app found to open this file'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Globals.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final timeProvider = Provider.of<TimeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadReport,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download, color: Colors.white),
            onPressed: _isDownloading ? null : _downloadReport,
            tooltip: 'Download Report',
          ),
        ],
      ),
      body: reportProvider.isLoading
          ? const LoadingWidget()
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
              ),
              child: reportProvider.report == null
                  ? _buildNoReportView(timeProvider)
                  : _buildReportContent(reportProvider.report!),
            ),
    );
  }

  Widget _buildNoReportView(TimeProvider timeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.download_for_offline,
              size: 60,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Report Not Downloaded',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please complete a shift to download your report.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            onPressed: timeProvider.hasActiveEntry ? null : _downloadReport,
            text: '📥 Download Report',
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(var report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.file_download,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Care Certification Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Report for ${report.dateOfService ?? ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Policyholder Info
          _buildSectionCard(
            icon: Icons.person,
            title: 'Policyholder Information',
            color: Colors.blue,
            children: [
              _buildInfoRow(
                  'Name', report.policyholder?['name']?.toString() ?? ''),
              _buildInfoRow('Policy #',
                  report.policyholder?['policy_number']?.toString() ?? ''),
              _buildInfoRow(
                  'Phone', report.policyholder?['phone']?.toString() ?? ''),
              _buildInfoRow(
                  'Address', report.policyholder?['address']?.toString() ?? ''),
            ],
          ),
          const SizedBox(height: 14),

          // Service Details
          _buildSectionCard(
            icon: Icons.access_time,
            title: 'Service Details',
            color: Colors.orange,
            children: [
              _buildInfoRow('Date', report.dateOfService ?? ''),
              _buildInfoRow('Time In', report.timeIn ?? ''),
              _buildInfoRow('Time Out', report.timeOut ?? ''),
              _buildInfoRow('Total Hours',
                  report.totalHours?.toStringAsFixed(2) ?? '0.00'),
              _buildInfoRow(
                  'Rate', '${report.rate?.toStringAsFixed(2) ?? '0.00'}'),
              // ✅ Fixed: Removed $ sign from here
              _buildInfoRow('Total Charge',
                  '${report.totalCharge?.toStringAsFixed(2) ?? '0.00'}',
                  isBold: true),
            ],
          ),
          const SizedBox(height: 14),

          // ADLs
          _buildSectionCard(
            icon: Icons.medical_services,
            title: 'Activities of Daily Living (ADLs)',
            color: Colors.blue,
            children: report.adls != null
                ? report.adls!.entries
                    .where((e) =>
                        e.key != 'id' &&
                        e.key != 'time_entry_id' &&
                        e.key != 'date' &&
                        e.key != 'created_at')
                    .map<Widget>((entry) {
                    final label = entry.key
                        .split('_')
                        .map((e) => e[0].toUpperCase() + e.substring(1))
                        .join(' ');
                    final value = entry.value?.toString() ?? 'Not provided';
                    final levelMap = {
                      'I': 'Independent',
                      'S': 'Supervision',
                      'A': 'Stand-by Assistance',
                      'H': 'Hands On Assistance'
                    };
                    final displayValue = levelMap[value] ?? value;
                    return _buildInfoRow(label, displayValue, isBold: true);
                  }).toList()
                : [],
          ),
          const SizedBox(height: 14),

          // IADLs
          _buildSectionCard(
            icon: Icons.house,
            title: 'Instrumental ADLs (IADLs)',
            color: Colors.green,
            children: report.iadls != null
                ? report.iadls!.entries
                    .where((e) =>
                        e.key != 'id' &&
                        e.key != 'time_entry_id' &&
                        e.key != 'date' &&
                        e.key != 'created_at')
                    .map<Widget>((entry) {
                    final label = entry.key
                        .split('_')
                        .map((e) => e[0].toUpperCase() + e.substring(1))
                        .join(' ');
                    final value = entry.value;
                    final bool isProvided =
                        (value == true || value == 1 || value == '1');
                    return _buildInfoRow(
                        label, isProvided ? '✅ Provided' : '❌ Not Provided');
                  }).toList()
                : [],
          ),
          const SizedBox(height: 14),

          // Signatures
          _buildSectionCard(
            icon: Icons.edit,
            title: 'Signatures',
            color: Colors.purple,
            children: [
              _buildSignatureRow(
                'Caregiver',
                report.signatures?['caregiver_signature']?.toString(),
              ),
              const Divider(height: 20),
              _buildSignatureRow(
                'Policyholder',
                report.signatures?['policyholder_signature']?.toString(),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSignatureRow(String label, String? base64Image) {
    final bool isSigned = base64Image != null && base64Image.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              isSigned ? '✅ Signed' : '❌ Not Signed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSigned ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (isSigned) ...[
          const SizedBox(height: 8),
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: _safeSignatureImage(base64Image),
          ),
        ],
      ],
    );
  }

  // Decode a base64 signature safely; never throws on corrupt data.
  Widget _safeSignatureImage(String base64Image) {
    try {
      var raw = base64Image.contains(',')
          ? base64Image.split(',').last
          : base64Image;
      raw = raw.trim();
      // Pad to a multiple of 4 so malformed strings don't throw.
      final mod = raw.length % 4;
      if (mod != 0) raw = raw.padRight(raw.length + (4 - mod), '=');
      return Image.memory(base64.decode(raw), fit: BoxFit.contain);
    } catch (_) {
      return Center(
        child: Text(
          'Signature unavailable',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        ),
      );
    }
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color: isBold ? Colors.black87 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
