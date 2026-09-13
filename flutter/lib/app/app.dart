import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_metadata.dart';
import '../features/catalog/presentation/catalog_screen.dart';
import '../features/clients/presentation/clients_screen.dart';
import '../features/locations/presentation/locations_screen.dart';
import '../features/projects/presentation/list/projects_screen.dart';
import '../features/settings/presentation/about_screen.dart';
import '../infrastructure/local_database/app_database_provider.dart';
import '../infrastructure/remote/pocketbase_client_provider.dart';
import '../infrastructure/sync/drift_app_sync_settings_repository.dart';
import '../infrastructure/sync/sync_coordinator.dart';
import '../shared/widgets/greencrew_offline_banner.dart';
import '../shared/widgets/stagecalc_mark.dart';
import 'theme/stagecalc_theme.dart';

/// How often the app checks whether automatic sync (ADR-026) is enabled and,
/// if so, runs it - deliberately not configurable yet, this is a LAN tool
/// syncing small amounts of data, not a high-frequency service.
const _autoSyncCheckInterval = Duration(minutes: 15);

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
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_maybeAutoSync());
    _autoSyncTimer = Timer.periodic(
      _autoSyncCheckInterval,
      (_) => _maybeAutoSync(),
    );
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  /// Re-reads the auto-sync setting fresh on every tick instead of caching
  /// it, so toggling it in "O aplikacji" takes effect on the next tick
  /// without this widget needing to know about that screen at all.
  Future<void> _maybeAutoSync() async {
    final database = AppDatabaseProvider.instance;
    final settings = await DriftAppSyncSettingsRepository(
      database,
    ).getSettings();
    if (!settings.autoSyncEnabled) {
      return;
    }

    try {
      await SyncCoordinator(
        PocketBaseClientProvider.instance,
        database,
      ).syncAll();
    } catch (_) {
      // Background sync failures are silent by design (offline-first: a
      // failed sync is a normal, expected state, not an error to interrupt
      // the user with). The "O aplikacji" screen shows the last successful
      // sync time for anyone who wants to check.
    }
  }

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
