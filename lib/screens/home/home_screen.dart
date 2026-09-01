import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homecare_app/providers/auth_provider.dart';
import 'package:homecare_app/providers/time_provider.dart';
import 'package:homecare_app/providers/signature_provider.dart';
import 'package:homecare_app/providers/progress_provider.dart';
import 'package:homecare_app/screens/time/time_in_screen.dart';
import 'package:homecare_app/screens/time/time_out_screen.dart';
import 'package:homecare_app/screens/progress/daily_progress_screen.dart';
import 'package:homecare_app/screens/report/weekly_report_screen.dart';
import 'package:homecare_app/screens/signature/signature_screen.dart';
import 'package:homecare_app/widgets/home_action_card.dart';
import 'package:homecare_app/core/utils/date_formatter.dart';
import 'package:homecare_app/core/utils/app_logger.dart';
import 'package:homecare_app/core/theme/app_style.dart';
import 'package:homecare_app/core/utils/responsive.dart';
import 'package:homecare_app/screens/auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  bool _signaturesExist = false;
  bool _progressCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllData());
  }

  Future<void> _loadAllData() async {
    try {
      final timeProvider = Provider.of<TimeProvider>(context, listen: false);
      final signatureProvider =
          Provider.of<SignatureProvider>(context, listen: false);
      final progressProvider =
          Provider.of<ProgressProvider>(context, listen: false);

      final date = DateFormatter.getCurrentDate();
      await timeProvider.getTodayLog(date);

      if (timeProvider.currentEntryId != null) {
        final entryId = timeProvider.currentEntryId!;
        await Future.wait([
          signatureProvider.getSignature(entryId),
          progressProvider.getProgress(entryId),
        ]);
      }

      if (mounted) {
        setState(() {
          _signaturesExist = signatureProvider.signature != null;
          _progressCompleted = progressProvider.dailyProgress != null;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      AppLogger.e('HomeScreen: load data failed', e, s);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    final timeProvider = Provider.of<TimeProvider>(context);

    return Scaffold(
      body: _buildBody(timeProvider),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppStyle.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppStyle.primaryDark,
          unselectedItemColor: AppStyle.inkSoft,
          selectedFontSize: 11.5,
          unselectedFontSize: 11.5,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time_outlined),
              activeIcon: Icon(Icons.access_time_filled_rounded),
              label: 'Time',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_outlined),
              activeIcon: Icon(Icons.checklist_rounded),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description_rounded),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.draw_outlined),
              activeIcon: Icon(Icons.draw_rounded),
              label: 'Sign',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TimeProvider timeProvider) {
    switch (_selectedIndex) {
      case 1:
        return _buildTimeSection(timeProvider);
      case 2:
        return const DailyProgressScreen();
      case 3:
        return const WeeklyReportScreen();
      case 4:
        return const SignatureScreen();
      default:
        return _buildHomeContent(timeProvider);
    }
  }

  PreferredSizeWidget _appBar(String title, {List<Widget>? actions}) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: AppStyle.primaryDark,
      elevation: 0,
      centerTitle: false,
      actions: actions,
    );
  }

  Widget _buildHomeContent(TimeProvider timeProvider) {
    final user = Provider.of<AuthProvider>(context).user;
    final isActive = timeProvider.hasActiveEntry;
    final isCompleted = timeProvider.timeOutValue != null;

    return Scaffold(
      appBar: _appBar(
        'Absolute Choice Homecare',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Log out',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: AppStyle.pageGradient,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppStyle.primary,
          child: ListView(
            padding: const EdgeInsets.all(AppStyle.lg),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ResponsiveCenter(
                maxWidth: 680,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _welcomeCard(user?.name, isActive, isCompleted),
                    const SizedBox(height: AppStyle.xl),
                    _sectionTitle("Today's Summary"),
                    const SizedBox(height: AppStyle.md),
                    _summaryGrid(timeProvider, isActive, isCompleted),
                    const SizedBox(height: AppStyle.xl),
                    _sectionTitle('Quick Actions'),
                    const SizedBox(height: AppStyle.md),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      _quickActions(isActive, isCompleted),
                    const SizedBox(height: AppStyle.md),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyle.rMd)),
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppStyle.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    Provider.of<TimeProvider>(context, listen: false).reset();
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        color: AppStyle.ink,
      ),
    );
  }

  Widget _welcomeCard(String? name, bool isActive, bool isCompleted) {
    final initial =
        (name != null && name.isNotEmpty) ? name[0].toUpperCase() : 'C';
    final statusText =
        isActive ? 'Active' : (isCompleted ? 'Done' : 'Not started');
    final statusColor =
        isActive ? AppStyle.success : (isCompleted ? AppStyle.inkSoft : AppStyle.warning);

    return Container(
      padding: const EdgeInsets.all(AppStyle.lg),
      decoration: BoxDecoration(
        gradient: AppStyle.brandGradient,
        borderRadius: BorderRadius.circular(AppStyle.rLg),
        boxShadow: AppStyle.brandShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppStyle.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${name ?? 'Caregiver'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.getCurrentDate(),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: statusColor == AppStyle.inkSoft
                        ? Colors.white
                        : statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid(TimeProvider tp, bool isActive, bool isCompleted) {
    final statusValue =
        isActive ? 'Active' : (isCompleted ? 'Done' : 'Pending');
    final statusColor = isActive
        ? AppStyle.success
        : (isCompleted ? AppStyle.inkSoft : AppStyle.warning);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard('Time In', tp.timeInValue ?? '--:--',
                  Icons.login_rounded, AppStyle.primaryDark),
            ),
            const SizedBox(width: AppStyle.md),
            Expanded(
              child: _statCard('Time Out', tp.timeOutValue ?? '--:--',
                  Icons.logout_rounded, AppStyle.warning),
            ),
          ],
        ),
        const SizedBox(height: AppStyle.md),
        Row(
          children: [
            Expanded(
              child: _statCard('Hours', tp.totalHours?.toStringAsFixed(1) ?? '0.0',
                  Icons.timer_outlined, AppStyle.success),
            ),
            const SizedBox(width: AppStyle.md),
            Expanded(
              child: _statCard(
                  'Status', statusValue, Icons.info_outline_rounded, statusColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppStyle.md),
      decoration: AppStyle.card(radius: AppStyle.rMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppStyle.inkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(bool isActive, bool isCompleted) {
    if (!isActive && !isCompleted) {
      return HomeActionCard(
        icon: Icons.play_arrow_rounded,
        title: 'Start Shift',
        subtitle: 'Begin your shift',
        color: AppStyle.success,
        onTap: () => setState(() => _selectedIndex = 1),
      );
    }

    if (isActive && !isCompleted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_progressCompleted)
            _statusCard('Daily Progress Completed', 'ADLs & IADLs recorded',
                Icons.assignment_turned_in_rounded)
          else
            HomeActionCard(
              icon: Icons.checklist_rounded,
              title: 'Daily Progress',
              subtitle: 'Record ADLs & IADLs',
              color: AppStyle.warning,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
          const SizedBox(height: AppStyle.sm),
          HomeActionCard(
            icon: Icons.stop_rounded,
            title: 'End Shift',
            subtitle: 'Complete your shift',
            color: AppStyle.danger,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
        ],
      );
    }

    // Completed
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _statusCard('Shift Completed', 'Data recorded successfully',
            Icons.check_circle_rounded),
        const SizedBox(height: AppStyle.sm),
        if (_progressCompleted)
          _statusCard('Daily Progress Completed', 'ADLs & IADLs recorded',
              Icons.assignment_turned_in_rounded)
        else
          HomeActionCard(
            icon: Icons.checklist_rounded,
            title: 'Daily Progress',
            subtitle: 'Record ADLs & IADLs',
            color: AppStyle.warning,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
        const SizedBox(height: AppStyle.sm),
        if (_signaturesExist)
          _statusCard('Signature Completed', 'Both parties signed',
              Icons.verified_rounded)
        else
          HomeActionCard(
            icon: Icons.draw_rounded,
            title: 'Add Signatures',
            subtitle: 'Caregiver & Policyholder',
            color: AppStyle.primaryDark,
            onTap: () => setState(() => _selectedIndex = 4),
          ),
        if (_progressCompleted && _signaturesExist) ...[
          const SizedBox(height: AppStyle.sm),
          HomeActionCard(
            icon: Icons.description_rounded,
            title: 'View Report',
            subtitle: 'See certification details',
            color: const Color(0xFF7C3AED),
            onTap: () => setState(() => _selectedIndex = 3),
          ),
        ],
        const SizedBox(height: AppStyle.sm),
        HomeActionCard(
          icon: Icons.add_circle_outline_rounded,
          title: 'Start New Shift',
          subtitle: 'Begin another shift',
          color: const Color(0xFF0D9488),
          onTap: _startNewShift,
        ),
      ],
    );
  }

  void _startNewShift() {
    Provider.of<TimeProvider>(context, listen: false).reset();
    Provider.of<ProgressProvider>(context, listen: false).reset();
    Provider.of<SignatureProvider>(context, listen: false).reset();
    setState(() {
      _progressCompleted = false;
      _signaturesExist = false;
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ready for a new shift. Tap "Start Shift" to begin.'),
        backgroundColor: const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyle.rSm)),
      ),
    );
  }

  Widget _statusCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppStyle.md),
      decoration: BoxDecoration(
        color: AppStyle.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppStyle.rMd),
        border: Border.all(color: AppStyle.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppStyle.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppStyle.success, size: 20),
          ),
          const SizedBox(width: AppStyle.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF16A34A)),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppStyle.success, size: 20),
        ],
      ),
    );
  }

  Widget _buildTimeSection(TimeProvider timeProvider) {
    if (!timeProvider.hasActiveEntry && timeProvider.timeOutValue == null) {
      return const TimeInScreen();
    } else if (timeProvider.hasActiveEntry) {
      return const TimeOutScreen();
    }

    return Scaffold(
      appBar: _appBar('Shift Summary'),
      body: DecoratedBox(
        decoration: AppStyle.pageGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyle.xl),
          child: ResponsiveCenter(
            maxWidth: 560,
            child: Column(
              children: [
                const SizedBox(height: AppStyle.xl),
                Container(
                  padding: const EdgeInsets.all(AppStyle.xl),
                  decoration: BoxDecoration(
                    color: AppStyle.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppStyle.success.withValues(alpha: 0.2), width: 8),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 72, color: AppStyle.success),
                ),
                const SizedBox(height: AppStyle.xl),
                const Text(
                  'Shift Completed',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppStyle.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your shift data has been recorded.',
                  style: TextStyle(fontSize: 14, color: AppStyle.inkSoft),
                ),
                const SizedBox(height: AppStyle.xl),
                Container(
                  padding: const EdgeInsets.all(AppStyle.lg),
                  decoration: AppStyle.card(),
                  child: Column(
                    children: [
                      _detailRow(Icons.login_rounded, 'Time In',
                          timeProvider.timeInValue ?? '--:--', AppStyle.primaryDark),
                      const Divider(height: 24),
                      _detailRow(Icons.logout_rounded, 'Time Out',
                          timeProvider.timeOutValue ?? '--:--', AppStyle.warning),
                      const Divider(height: 24),
                      _detailRow(
                          Icons.timer_outlined,
                          'Total Duration',
                          '${timeProvider.totalHours?.toStringAsFixed(2) ?? '0.00'} hrs',
                          AppStyle.success),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyle.xl),
                _infoBanner(
                    'Don\'t forget to add your signatures in the "Sign" tab.'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: AppStyle.lg),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppStyle.inkSoft,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppStyle.ink,
          ),
        ),
      ],
    );
  }

  Widget _infoBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyle.lg, vertical: AppStyle.md),
      decoration: BoxDecoration(
        color: AppStyle.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppStyle.rMd),
        border: Border.all(color: AppStyle.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: AppStyle.primaryDark),
          const SizedBox(width: AppStyle.md),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
