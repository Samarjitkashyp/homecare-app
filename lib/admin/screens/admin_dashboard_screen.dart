import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homecare_app/admin/providers/admin_auth_provider.dart';
import 'package:homecare_app/admin/providers/admin_data_provider.dart';
import 'package:homecare_app/admin/widgets/admin_stat_card.dart';
import 'package:homecare_app/admin/widgets/admin_side_menu.dart';
import 'package:homecare_app/admin/screens/caregivers_screen.dart';
import 'package:homecare_app/admin/screens/policyholders_screen.dart';
import 'package:homecare_app/admin/screens/shifts_screen.dart';
import 'package:homecare_app/admin/screens/admin_profile_screen.dart';
import 'package:homecare_app/admin/screens/admin_login_screen.dart';
import 'package:homecare_app/core/theme/app_style.dart';
import 'package:homecare_app/core/utils/responsive.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final dataProvider = Provider.of<AdminDataProvider>(context, listen: false);
    await dataProvider.loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AdminAuthProvider>(context);
    final dataProvider = Provider.of<AdminDataProvider>(context);

    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: AdminSideMenu(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context);
        },
      ),
      body: _buildBody(dataProvider),
    );
  }

  Widget _buildBody(AdminDataProvider dataProvider) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard(dataProvider);
      case 1:
        return CaregiversScreen(scaffoldKey: _scaffoldKey);
      case 2:
        return PolicyholdersScreen(scaffoldKey: _scaffoldKey);
      case 3:
        return ShiftsScreen(scaffoldKey: _scaffoldKey);
      case 4:
        return AdminProfileScreen(scaffoldKey: _scaffoldKey);
      default:
        return _buildDashboard(dataProvider);
    }
  }

  Widget _buildDashboard(AdminDataProvider dataProvider) {
    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = dataProvider.dashboardStats;
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF0F2A54),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 14, color: Colors.blue),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 84),
                  child: Text(
                    authProvider.adminUser?.name ?? 'Admin',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authProvider.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppStyle.canvasTop, AppStyle.canvasBottom],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ResponsiveCenter(
            maxWidth: 760,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👋 Welcome back, Admin!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here\'s what\'s happening with your business today.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: context.isTablet ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  AdminStatCard(
                    title: 'Total Caregivers',
                    value: stats?.totalCaregivers.toString() ?? '0',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  AdminStatCard(
                    title: 'Policyholders',
                    value: stats?.totalPolicyholders.toString() ?? '0',
                    icon: Icons.person_add,
                    color: Colors.green,
                  ),
                  AdminStatCard(
                    title: 'Total Shifts',
                    value: stats?.totalShifts.toString() ?? '0',
                    icon: Icons.access_time,
                    color: Colors.orange,
                  ),
                  AdminStatCard(
                    title: 'Revenue',
                    value:
                        '\$${stats?.totalRevenue.toStringAsFixed(2) ?? '0.00'}',
                    icon: Icons.attach_money,
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recent Activity
              _buildRecentActivityCard(stats?.recentShifts ?? []),
              const SizedBox(height: 16),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(List<dynamic> recentShifts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.history, color: Colors.blue.shade600, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentShifts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No recent shifts',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...recentShifts.take(4).map((shift) {
              final status = shift['status'] ?? 'pending';
              final isCompleted = status == 'completed';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isCompleted
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        child: Icon(
                          isCompleted ? Icons.check : Icons.pending,
                          size: 12,
                          color: isCompleted ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shift['caregiver_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              shift['date'] ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
