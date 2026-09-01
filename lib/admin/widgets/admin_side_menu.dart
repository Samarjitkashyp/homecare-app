import 'package:flutter/material.dart';

class AdminSideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSideMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280, // ✅ Full width drawer
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F2A54),
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: Column(
          children: [
            // ✅ Header - Full Width
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Absolute Choice Homecare',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'v2.0.0',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ✅ Menu Items - Full Width
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: ListView(
                  children: [
                    _buildMenuItem(
                      index: 0,
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard,
                      title: 'Dashboard',
                      color: Colors.blue.shade200,
                    ),
                    const SizedBox(height: 2),
                    _buildMenuItem(
                      index: 1,
                      icon: Icons.people_outline,
                      activeIcon: Icons.people,
                      title: 'Caregivers',
                      color: Colors.cyan.shade200,
                    ),
                    const SizedBox(height: 2),
                    _buildMenuItem(
                      index: 2,
                      icon: Icons.person_add_alt_1,
                      activeIcon: Icons.person_add,
                      title: 'Policyholders',
                      color: Colors.green.shade200,
                    ),
                    const SizedBox(height: 2),
                    _buildMenuItem(
                      index: 3,
                      icon: Icons.access_time_outlined,
                      activeIcon: Icons.access_time,
                      title: 'Shifts',
                      color: Colors.orange.shade200,
                    ),
                    const SizedBox(height: 2),
                    _buildMenuItem(
                      index: 4,
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      title: 'Profile',
                      color: Colors.purple.shade200,
                    ),
                  ],
                ),
              ),
            ),
            // ✅ Footer - Full Width
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.copyright,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '2026 Absolute Choice Homecare',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required Color color,
  }) {
    final isSelected = selectedIndex == index;

    return Container(
      width: double.infinity, // ✅ Full width
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isSelected
            ? LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.05),
          ],
        )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? Colors.white : color,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: isSelected
            ? Container(
          width: 6,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
        )
            : null,
        onTap: () => onItemSelected(index),
        dense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        ),
      ),
    );
  }
}