import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A responsive shell that adapts to mobile and desktop layouts.
class ResponsiveAppShell extends StatelessWidget {
  final Widget child;
  final Widget sidebar;
  final Widget? mobileBottomBar;
  final Widget? mobileAppBar;

  const ResponsiveAppShell({
    super.key,
    required this.child,
    required this.sidebar,
    this.mobileBottomBar,
    this.mobileAppBar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F13),
            appBar: mobileAppBar != null
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: mobileAppBar!,
                  )
                : null,
            body: child,
            bottomNavigationBar: mobileBottomBar,
          );
        }

        // Desktop layout
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F13),
          body: Row(
            children: [
              sidebar,
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

/// A standard mobile bottom navigation bar for the app.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF16161D),
        selectedItemColor: const Color(0xFF8B5CF6),
        unselectedItemColor: Colors.white54,
        currentIndex: currentIndex,
        onTap: onTabSelected,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_rounded),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}

/// The mobile app bar with just the logo.
class AppMobileHeader extends StatelessWidget {
  const AppMobileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF16161D),
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.architecture, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Mandap',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5)),
        ],
      ),
    );
  }
}
