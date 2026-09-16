import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_metadata.dart';
import '../../../infrastructure/backup/app_backup_import_service.dart';
import '../../../infrastructure/backup/app_backup_service.dart';
import '../../../infrastructure/local_database/app_database_provider.dart';
import '../../../infrastructure/remote/pocketbase_auth_service.dart';
import '../../../infrastructure/remote/pocketbase_client_provider.dart';
import '../../../infrastructure/sync/app_sync_settings.dart';
import '../../../infrastructure/sync/drift_app_sync_settings_repository.dart';
import '../../../infrastructure/sync/sync_coordinator.dart';
import '../../../shared/widgets/greencrew_button.dart';
import '../../../shared/widgets/greencrew_card.dart';
import '../../../shared/widgets/stagecalc_mark.dart';
import '../../catalog/data/drift_catalog_repository.dart';
import '../../clients/data/drift_client_repository.dart';
import '../../locations/data/drift_location_repository.dart';
import '../../power_presets/data/drift_power_preset_repository.dart';
import '../../projects/data/drift_project_repository.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _importPathController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _newPasswordConfirmController = TextEditingController();
  var _isCreatingBackup = false;
  var _isImportingBackup = false;
  var _syncSettings = AppSyncSettings.initial;
  var _isSyncing = false;
  var _isLoggingIn = false;
  var _isChangingPassword = false;
  String? _lastSyncMessage;
  String? _loginError;
  String? _changePasswordError;

  PocketBaseAuthService get _authService =>
      PocketBaseAuthService(PocketBaseClientProvider.instance);

  @override
  void initState() {
    super.initState();
    _loadSyncSettings();
  }

  @override
  void dispose() {
    _importPathController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const GreenCrewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StageCalcMark(size: 48),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppMetadata.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(AppMetadata.description),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GreenCrewCard(
          child: Column(
            children: [
              _InfoRow(label: 'Wersja', value: AppMetadata.version),
              _InfoRow(label: 'Autor', value: AppMetadata.author),
              _InfoRow(label: 'Organizacja', value: AppMetadata.organization),
              _InfoRow(label: 'Strona', value: AppMetadata.website),
              _InfoRow(label: 'Repozytorium', value: AppMetadata.repository),
              _InfoRow(label: 'Licencja', value: AppMetadata.license),
              _InfoRow(label: 'Pakiet', value: AppMetadata.packageId),
              const SizedBox(height: 12),
              GreenCrewButton(
                label: 'Licencje komponentów zewnętrznych',
                icon: Icons.description_outlined,
                secondary: true,
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: AppMetadata.name,
                  applicationVersion: AppMetadata.version,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GreenCrewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Konto', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_authService.isLoggedIn) ...[
                Text('Zalogowano jako: ${_authService.currentUserEmail}'),
                const SizedBox(height: 12),
                GreenCrewButton(
                  label: 'Wyloguj',
                  icon: Icons.logout,
                  secondary: true,
                  onPressed: _logout,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Zmień hasło',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Obecne hasło'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nowe hasło'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPasswordConfirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Powtórz nowe hasło',
                  ),
                  onSubmitted: (_) =>
                      _isChangingPassword ? null : _changePassword(),
                ),
                if (_changePasswordError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _changePasswordError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                GreenCrewButton(
                  label: _isChangingPassword ? 'Zmienianie...' : 'Zmień hasło',
                  icon: Icons.password_outlined,
                  secondary: true,
                  onPressed: _isChangingPassword ? null : _changePassword,
                ),
              ] else ...[
                const Text(
                  'Zaloguj się, aby synchronizować dane z resztą ekipy. '
                  'Praca lokalna działa normalnie bez logowania.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Hasło'),
                  onSubmitted: (_) => _isLoggingIn ? null : _login(),
                ),
                if (_loginError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _loginError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                GreenCrewButton(
                  label: _isLoggingIn ? 'Logowanie...' : 'Zaloguj się',
                  icon: Icons.login,
                  onPressed: _isLoggingIn ? null : _login,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        GreenCrewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Synchronizacja',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Wysyła i pobiera projekty, katalog, klientów, lokacje i '
                'presety z serwera PocketBase w sieci lokalnej. Nowszy zapis '
                '(według czasu ostatniej edycji) zawsze wygrywa.',
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Automatyczna synchronizacja'),
                value: _syncSettings.autoSyncEnabled,
                onChanged: _isSyncing ? null : _toggleAutoSync,
              ),
              if (!_syncSettings.autoSyncEnabled) ...[
                const SizedBox(height: 4),
                GreenCrewButton(
                  label: _isSyncing
                      ? 'Synchronizowanie...'
                      : 'Synchronizuj teraz',
                  icon: Icons.sync,
                  secondary: true,
                  onPressed: _isSyncing ? null : () => _runSync(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _syncStatusText(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GreenCrewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kopia zapasowa',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Eksportuje wszystkie lokalne dane (projekty, katalog, '
                'klientów, lokacje i presety rozdzielnic) do jednego pliku JSON.',
              ),
              const SizedBox(height: 12),
              GreenCrewButton(
                label: _isCreatingBackup
                    ? 'Tworzenie kopii...'
                    : 'Utwórz kopię zapasową (JSON)',
                icon: Icons.save_alt,
                onPressed: _isCreatingBackup ? null : _createBackup,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GreenCrewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Przywracanie z kopii zapasowej',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Wczytuje plik kopii zapasowej JSON. Rekordy o tych samych ID '
                'co już istniejące zostaną nadpisane; nic innego nie zostanie usunięte.',
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _importPathController,
                      decoration: const InputDecoration(
                        labelText: 'Ścieżka do pliku kopii zapasowej',
                        hintText:
                            r'np. C:\Users\...\Documents\StageCalc\backups\stagecalc_backup_...json',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Wybierz plik',
                    icon: const Icon(Icons.folder_open_outlined),
                    onPressed: _isImportingBackup ? null : _pickBackupFile,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GreenCrewButton(
                label: _isImportingBackup
                    ? 'Wczytywanie...'
                    : 'Wczytaj i zwaliduj',
                icon: Icons.file_open_outlined,
                secondary: true,
                onPressed: _isImportingBackup ? null : _startImport,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const GreenCrewCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppMetadata.ecosystem),
              SizedBox(height: 8),
              Text(AppMetadata.copyright),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoggingIn = true;
      _loginError = null;
    });

    try {
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      _passwordController.clear();
      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loginError = 'Nie udało się zalogować: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  void _logout() {
    _authService.logout();
    setState(() {});
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;

    if (newPassword != _newPasswordConfirmController.text) {
      setState(() => _changePasswordError = 'Nowe hasła nie są identyczne.');
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _changePasswordError = null;
    });

    try {
      await _authService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: newPassword,
      );
      if (!mounted) {
        return;
      }
      // PocketBase invalidates the current session's token as soon as the
      // password changes, so the old session can't keep working silently -
      // log out here and let the user log back in with the new password.
      _authService.logout();
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _newPasswordConfirmController.clear();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasło zmienione. Zaloguj się ponownie.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(
        () => _changePasswordError = 'Nie udało się zmienić hasła: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  Future<void> _loadSyncSettings() async {
    final settings = await _syncSettingsRepository().getSettings();
    if (!mounted) {
      return;
    }
    setState(() => _syncSettings = settings);
  }

  Future<void> _toggleAutoSync(bool enabled) async {
    await _syncSettingsRepository().setAutoSyncEnabled(enabled);
    if (!mounted) {
      return;
    }
    setState(
      () => _syncSettings = _syncSettings.copyWith(autoSyncEnabled: enabled),
    );
    if (enabled) {
      await _runSync(showSnackBar: false);
    }
  }

  Future<void> _runSync({bool showSnackBar = true}) async {
    setState(() {
      _isSyncing = true;
      _lastSyncMessage = null;
    });

    try {
      final summary = await SyncCoordinator(
        PocketBaseClientProvider.instance,
        AppDatabaseProvider.instance,
      ).syncAll();
      final settings = await _syncSettingsRepository().getSettings();

      if (!mounted) {
        return;
      }
      setState(() {
        _syncSettings = settings;
        _lastSyncMessage = summary.hasErrors
            ? 'Zsynchronizowano z błędami (${summary.errors.length}). '
                  'Wysłano: ${summary.pushed}, pobrano: ${summary.pulled}.'
            : 'Wysłano: ${summary.pushed}, pobrano: ${summary.pulled}, '
                  'bez zmian: ${summary.unchanged}.';
      });
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_lastSyncMessage!)));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(
        () => _lastSyncMessage = 'Synchronizacja nie powiodła się: $error',
      );
      if (showSnackBar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_lastSyncMessage!)));
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  String _syncStatusText() {
    if (_lastSyncMessage != null) {
      return _lastSyncMessage!;
    }
    final lastSyncedAt = _syncSettings.lastSyncedAt;
    if (lastSyncedAt == null) {
      return 'Jeszcze nie synchronizowano.';
    }
    return 'Ostatnia synchronizacja: $lastSyncedAt';
  }

  DriftAppSyncSettingsRepository _syncSettingsRepository() {
    return DriftAppSyncSettingsRepository(AppDatabaseProvider.instance);
  }

  Future<void> _createBackup() async {
    setState(() => _isCreatingBackup = true);

    try {
      final location = await _backupService().createBackupFile();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kopia zapasowa utworzona'),
          content: SelectableText(location),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się utworzyć kopii: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingBackup = false);
      }
    }
  }

  Future<void> _pickBackupFile() async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      final path = result?.path;
      if (path == null || !mounted) {
        return;
      }
      setState(() => _importPathController.text = path);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się otworzyć wyboru pliku: $error')),
      );
    }
  }

  Future<void> _startImport() async {
    final path = _importPathController.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Podaj ścieżkę do pliku.')));
      return;
    }

    setState(() => _isImportingBackup = true);

    final importService = _importService();

    try {
      final preview = await importService.loadAndValidate(path);

      if (!mounted) {
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Zaimportować kopię zapasową?'),
          content: Text(
            'Plik z wersji aplikacji ${preview.appVersion}'
            '${preview.createdAt == null ? '' : ' (${preview.createdAt})'}.\n\n'
            'Znaleziono:\n'
            '${preview.projects.length} projektów\n'
            '${preview.clients.length} klientów\n'
            '${preview.locations.length} lokacji\n'
            '${preview.catalogDevices.length} pozycji katalogu\n'
            '${preview.powerPresets.length} presetów rozdzielnic\n\n'
            'Rekordy o tych samych ID co już istniejące zostaną nadpisane. '
            'Tej operacji nie można cofnąć.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Importuj'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }

      await importService.import(preview);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zaimportowano ${preview.totalRecords} rekordów.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zaimportować kopii: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isImportingBackup = false);
      }
    }
  }

  AppBackupService _backupService() {
    final database = AppDatabaseProvider.instance;
    return AppBackupService(
      projectRepository: DriftProjectRepository(database),
      clientRepository: DriftClientRepository(database),
      locationRepository: DriftLocationRepository(database),
      catalogRepository: DriftCatalogRepository(database),
      powerPresetRepository: DriftPowerPresetRepository(database),
    );
  }

  AppBackupImportService _importService() {
    final database = AppDatabaseProvider.instance;
    return AppBackupImportService(
      projectRepository: DriftProjectRepository(database),
      clientRepository: DriftClientRepository(database),
      locationRepository: DriftLocationRepository(database),
      catalogRepository: DriftCatalogRepository(database),
      powerPresetRepository: DriftPowerPresetRepository(database),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
