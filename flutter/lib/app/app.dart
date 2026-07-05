import 'package:flutter/material.dart';

import '../core/constants/app_metadata.dart';
import '../features/catalog/presentation/catalog_screen.dart';
import '../features/clients/presentation/clients_screen.dart';
import '../features/locations/presentation/locations_screen.dart';
import '../features/projects/presentation/list/projects_screen.dart';
import '../features/settings/presentation/about_screen.dart';
import '../shared/widgets/greencrew_offline_banner.dart';
import '../shared/widgets/stagecalc_mark.dart';
import 'theme/stagecalc_theme.dart';

class StageCalcApp extends StatelessWidget {
  const StageCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppMetadata.name,
      debugShowCheckedModeBanner: false,
      theme: StageCalcTheme.dark(),
      home: const StageCalcShell(),
    );
  }
}

class StageCalcShell extends StatefulWidget {
  const StageCalcShell({super.key});

  @override
  State<StageCalcShell> createState() => _StageCalcShellState();
}

class _StageCalcShellState extends State<StageCalcShell> {
  var _index = 0;

  static const _destinations = <_StageCalcDestination>[
    _StageCalcDestination(
      label: 'Projekty',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      screen: ProjectsScreen(),
    ),
    _StageCalcDestination(
      label: 'Katalog',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      screen: CatalogScreen(),
    ),
    _StageCalcDestination(
      label: 'Lokacje',
      icon: Icons.location_city_outlined,
      selectedIcon: Icons.location_city,
      screen: LocationsScreen(),
    ),
    _StageCalcDestination(
      label: 'Klienci',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
      screen: ClientsScreen(),
    ),
    _StageCalcDestination(
      label: 'Info',
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
      screen: AboutScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final selected = _destinations[_index];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const StageCalcMark(size: 34),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppMetadata.name),
                Text(
                  'Techniczny kalkulator wydarzenia',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const GreenCrewOfflineBanner(),
          Expanded(
            child: Row(
              children: [
                if (isDesktop)
                  NavigationRail(
                    selectedIndex: _index,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: _setIndex,
                    leading: const Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 24),
                      child: StageCalcMark(size: 44),
                    ),
                    destinations: [
                      for (final destination in _destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                Expanded(child: SafeArea(top: false, child: selected.screen)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _setIndex,
              destinations: [
                for (final destination in _destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }

  void _setIndex(int index) {
    setState(() => _index = index);
  }
}

class _StageCalcDestination {
  const _StageCalcDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}
