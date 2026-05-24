import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/widgets/brand_mark.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int get _selectedIndex {
    return switch (location) {
      AppRoutes.sell => 1,
      AppRoutes.chat => 2,
      AppRoutes.account => 3,
      _ => 0,
    };
  }

  void _go(BuildContext context, int index) {
    final route = switch (index) {
      1 => AppRoutes.sell,
      2 => AppRoutes.chat,
      3 => AppRoutes.account,
      _ => AppRoutes.buy,
    };
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    extended: constraints.maxWidth >= 1080,
                    minExtendedWidth: 190,
                    backgroundColor: Colors.white,
                    onDestinationSelected: (index) => _go(context, index),
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: BrandMark(size: 52),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.storefront_outlined),
                        selectedIcon: Icon(Icons.storefront),
                        label: Text('Buy'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.add_a_photo_outlined),
                        selectedIcon: Icon(Icons.add_a_photo),
                        label: Text('Sell'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.chat_bubble_outline),
                        selectedIcon: Icon(Icons.chat_bubble),
                        label: Text('Chat'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: Text('Account'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: child),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(child: child),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => _go(context, index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Buy',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_a_photo_outlined),
                selectedIcon: Icon(Icons.add_a_photo),
                label: 'Sell',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        );
      },
    );
  }
}
