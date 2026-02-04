import 'package:flutter/material.dart';

import '../../app/state_container.dart';
import '../../app/routes.dart';
import '../../features/settings/settings_screen.dart';

/// Profile in top-right: avatar + username (from login). Tap to open menu.
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = AppStateScope.of(context).auth;
    final username = authState.currentUsername ?? 'Guest';

    return PopupMenuButton<String>(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'G',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              username,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
      onSelected: (value) {
        if (value == 'settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        } else if (value == 'logout') {
          authState.logout();
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
        if (authState.isLoggedIn)
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout),
                SizedBox(width: 12),
                Text('Logout'),
              ],
            ),
          ),
      ],
    );
  }
}
