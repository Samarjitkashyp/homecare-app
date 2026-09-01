import 'package:flutter/material.dart';

class ReportPreviewScreen extends StatelessWidget {
  final Map<String, dynamic>? reportData;

  const ReportPreviewScreen({super.key, this.reportData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Report Preview',
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
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF generation coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
      body: reportData == null
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No report data available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Weekly Care Certification',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Week: ${reportData?['week_start'] ?? ''} to ${reportData?['week_end'] ?? ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Policyholder Info
              _buildSection(
                title: 'Policyholder Information',
                icon: Icons.person,
                color: Colors.blue,
                children: [
                  _buildRow('Name', reportData?['policyholder']?['name'] ?? ''),
                  _buildRow('Policy Number', reportData?['policyholder']?['policy_number'] ?? ''),
                  _buildRow('Phone', reportData?['policyholder']?['phone'] ?? ''),
                  _buildRow('Address', reportData?['policyholder']?['address'] ?? ''),
                ],
              ),
              const SizedBox(height: 14),

              // Service Details
              _buildSection(
                title: 'Service Details',
                icon: Icons.access_time,
                color: Colors.orange,
                children: [
                  _buildRow('Date', reportData?['time_entry']?['date'] ?? ''),
                  _buildRow('Time In', reportData?['time_entry']?['time_in'] ?? ''),
                  _buildRow('Time Out', reportData?['time_entry']?['time_out'] ?? ''),
                  _buildRow('Total Hours', reportData?['time_entry']?['total_hours']?.toStringAsFixed(2) ?? ''),
                  _buildRow('Rate', '\$${reportData?['time_entry']?['rate']?.toStringAsFixed(2) ?? '0.00'}'),
                  _buildRow('Total Charge', '\$${reportData?['time_entry']?['total_charge']?.toStringAsFixed(2) ?? '0.00'}'),
                ],
              ),
              const SizedBox(height: 14),

              // ADLs
              _buildSection(
                title: 'Activities of Daily Living (ADLs)',
                icon: Icons.medical_services,
                color: Colors.blue,
                children: [
                  _buildRow('Bathing', _getADLValue(reportData?['adls']?['bathing'])),
                  _buildRow('Mobility', _getADLValue(reportData?['adls']?['mobility'])),
                  _buildRow('Bed/Chair', _getADLValue(reportData?['adls']?['bed_chair'])),
                  _buildRow('Continence', _getADLValue(reportData?['adls']?['continence'])),
                  _buildRow('Eating', _getADLValue(reportData?['adls']?['eating'])),
                  _buildRow('Toileting', _getADLValue(reportData?['adls']?['toileting'])),
                  _buildRow('Dressing', _getADLValue(reportData?['adls']?['dressing'])),
                  _buildRow('Medication', _getADLValue(reportData?['adls']?['medication'])),
                ],
              ),
              const SizedBox(height: 14),

              // IADLs
              _buildSection(
                title: 'Instrumental ADLs (IADLs)',
                icon: Icons.house,
                color: Colors.green,
                children: [
                  _buildRow('Housekeeping', _getIADLValue(reportData?['iadls']?['housekeeping'])),
                  _buildRow('Meal Preparation', _getIADLValue(reportData?['iadls']?['meal_prep'])),
                  _buildRow('Shopping', _getIADLValue(reportData?['iadls']?['shopping'])),
                  _buildRow('Transportation', _getIADLValue(reportData?['iadls']?['transportation'])),
                  _buildRow('Managing Medicines', _getIADLValue(reportData?['iadls']?['managing_medicines'])),
                  _buildRow('Laundry', _getIADLValue(reportData?['iadls']?['laundry'])),
                ],
              ),
              const SizedBox(height: 14),

              // Signatures
              _buildSection(
                title: 'Signatures',
                icon: Icons.edit,
                color: Colors.purple,
                children: [
                  _buildRow('Caregiver', reportData?['signatures']?['caregiver'] != null ? '✅ Signed' : '❌ Not Signed'),
                  _buildRow('Policyholder', reportData?['signatures']?['policyholder'] != null ? '✅ Signed' : '❌ Not Signed'),
                ],
              ),
              const SizedBox(height: 14),

              // Certification
              Container(
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.gavel,
                            color: Colors.orange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Certification',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reportData?['certification'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
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

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getADLValue(dynamic value) {
    final map = {
      'I': 'Independent',
      'S': 'Supervision',
      'A': 'Stand-by Assistance',
      'H': 'Hands On Assistance'
    };
    return map[value] ?? value ?? 'Not provided';
  }

  String _getIADLValue(dynamic value) {
    if (value == true || value == 1) {
      return '✅ Provided';
    }
    return '❌ Not Provided';
  }
}