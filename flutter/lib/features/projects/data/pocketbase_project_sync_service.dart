import 'package:pocketbase/pocketbase.dart';

import '../../clients/domain/entities/client.dart';
import '../../locations/domain/entities/location.dart';
import '../domain/entities/power_models.dart';
import '../domain/entities/project_models.dart';

/// First real integration with the PocketBase backend (ADR-017): pushes one
/// local [Project] (with its full aggregate of groups, items, distros,
/// outlets, connections and trusses) plus its linked [Client]/[Location] to
/// PocketBase.
///
/// This is a one-way, no-conflict-handling push meant to prove the
/// connection end to end, not a sync engine: re-running it for the same
/// project upserts by `local_id` instead of creating duplicates, but it does
/// not detect or resolve concurrent remote edits, and never reads data back
/// into the local database.
class PocketBaseProjectSyncService {
  const PocketBaseProjectSyncService(this._pb);

  final PocketBase _pb;

  Future<String> pushProject(
    Project project, {
    Client? client,
    Location? location,
  }) async {
    final clientRemoteId = client == null ? null : await _pushClient(client);
    final locationRemoteId = location == null
        ? null
        : await _pushLocation(location);

    final projectRemoteId = await _upsert('projects', project.id, {
      'workspace_id': 'local',
      'name': project.name,
      'phase_id': project.phaseId,
      'client': clientRemoteId,
      'location': locationRemoteId,
      'created_at': _iso(project.createdAt),
      'updated_at': _iso(project.updatedAt),
    });

    final groupRemoteIds = <String, String>{};
    for (final group in project.groups) {
      groupRemoteIds[group.id] = await _pushGroup(
        projectRemoteId,
        group,
        project,
      );
    }

    final distroRemoteIds = <String, String>{};
    final outletRemoteIds = <String, String>{};
    for (final distro in project.distros) {
      final distroRemoteId = await _pushDistro(
        projectRemoteId,
        distro,
        project,
      );
      distroRemoteIds[distro.id] = distroRemoteId;
      for (final outlet in distro.outlets) {
        outletRemoteIds[outlet.id] = await _pushOutlet(
          projectRemoteId,
          distroRemoteId,
          outlet,
          project,
        );
      }
    }

    for (final connection in project.connections) {
      await _pushConnection(
        projectRemoteId,
        connection,
        project,
        sourceDistroRemoteId: distroRemoteIds[connection.sourceDistroId],
        sourceOutletRemoteId: outletRemoteIds[connection.sourceOutletId],
        targetGroupRemoteId: connection.targetGroupId == null
            ? null
            : groupRemoteIds[connection.targetGroupId],
        targetDistroRemoteId: connection.targetDistroId == null
            ? null
            : distroRemoteIds[connection.targetDistroId],
      );
    }

    for (final truss in project.trusses) {
      await _pushTruss(projectRemoteId, truss, project);
    }

    return projectRemoteId;
  }

  Future<String> _pushClient(Client client) {
    return _upsert('clients', client.id, {
      'workspace_id': 'local',
      'name': client.name,
      'contact_person': client.contactPerson,
      'email': client.email,
      'phone': client.phone,
      'address': client.address,
      'nip': client.nip,
      'notes': client.notes,
      'created_at': _iso(client.createdAt),
      'updated_at': _iso(client.updatedAt),
    });
  }

  Future<String> _pushLocation(Location location) async {
    final locationRemoteId = await _upsert('locations', location.id, {
      'workspace_id': 'local',
      'name': location.name,
      'address': location.address,
      'capacity': location.capacity,
      'contact_name': location.contactName,
      'contact_phone': location.contactPhone,
      'contact_email': location.contactEmail,
      'notes': location.notes,
      'created_at': _iso(location.createdAt),
      'updated_at': _iso(location.updatedAt),
    });

    for (final contact in location.contacts) {
      await _upsert('location_contacts', contact.id, {
        'location': locationRemoteId,
        'role': contact.role,
        'name': contact.name,
        'phone': contact.phone,
        'email': contact.email,
        'notes': contact.notes,
        'created_at': _iso(contact.createdAt),
        'updated_at': _iso(contact.updatedAt),
      });
    }

    for (final connector in location.powerConnectors) {
      await _upsert('location_power_connectors', connector.id, {
        'location': locationRemoteId,
        'name': connector.name,
        'connector_type_id': connector.connectorTypeId,
        'quantity': connector.quantity,
        'notes': connector.notes,
        'created_at': _iso(connector.createdAt),
        'updated_at': _iso(connector.updatedAt),
      });
    }

    return locationRemoteId;
  }

  Future<String> _pushGroup(
    String projectRemoteId,
    ProjectGroup group,
    Project project,
  ) async {
    final groupRemoteId = await _upsert('project_groups', group.id, {
      'project': projectRemoteId,
      'name': group.name,
      'power_profile': group.powerProfile.toJson(),
      'created_at': _iso(project.createdAt),
      'updated_at': _iso(project.updatedAt),
    });

    for (final item in group.items) {
      await _upsert('project_items', item.id, {
        'project': projectRemoteId,
        'group': groupRemoteId,
        'name_snapshot': item.nameSnapshot,
        'manufacturer_snapshot': item.manufacturerSnapshot,
        'quantity': item.quantity,
        'power_w_snapshot': item.powerWSnapshot,
        'current_a_snapshot': item.currentASnapshot,
        'weight_kg_snapshot': item.weightKgSnapshot,
        'unit': item.unit.toJson(),
        'created_at': _iso(project.createdAt),
        'updated_at': _iso(project.updatedAt),
      });
    }

    return groupRemoteId;
  }

  Future<String> _pushDistro(
    String projectRemoteId,
    ProjectDistro distro,
    Project project,
  ) {
    return _upsert('project_distros', distro.id, {
      'project': projectRemoteId,
      'phase_id': distro.phaseId,
      'name': distro.name,
      'source_type': distro.sourceType.toJson(),
      'location_connector_group_id': distro.locationConnectorGroupId,
      'input_connector_type_id': distro.inputConnectorTypeId,
      'is_root_power_source': distro.isRootPowerSource,
      'created_at': _iso(project.createdAt),
      'updated_at': _iso(project.updatedAt),
    });
  }

  Future<String> _pushOutlet(
    String projectRemoteId,
    String distroRemoteId,
    ProjectOutlet outlet,
    Project project,
  ) {
    return _upsert('project_outlets', outlet.id, {
      'project': projectRemoteId,
      'distro': distroRemoteId,
      'template_outlet_id': outlet.templateOutletId,
      'name': outlet.name,
      'connector_type_id': outlet.connectorTypeId,
      'phase': outlet.phase.toJson(),
      'max_current_a': outlet.maxCurrentA,
      'created_at': _iso(project.createdAt),
      'updated_at': _iso(project.updatedAt),
    });
  }

  Future<String> _pushConnection(
    String projectRemoteId,
    PowerConnection connection,
    Project project, {
    required String? sourceDistroRemoteId,
    required String? sourceOutletRemoteId,
    required String? targetGroupRemoteId,
    required String? targetDistroRemoteId,
  }) {
    return _upsert('power_connections', connection.id, {
      'project': projectRemoteId,
      'phase_id': connection.phaseId,
      'source_distro': sourceDistroRemoteId,
      'source_outlet': sourceOutletRemoteId,
      'target_type': connection.targetType.toJson(),
      'target_group': targetGroupRemoteId,
      'target_distro': targetDistroRemoteId,
      'selected_phases': connection.selectedPhases
          .map((phase) => phase.toJson())
          .toList(),
      'notes': connection.notes,
      'created_at': _iso(project.createdAt),
      'updated_at': _iso(project.updatedAt),
    });
  }

  Future<String> _pushTruss(
    String projectRemoteId,
    ProjectTruss truss,
    Project project,
  ) {
    return _upsert('project_trusses', truss.id, {
      'project': projectRemoteId,
      'phase_id': truss.phaseId,
      'name': truss.name,
      'truss_system_id': truss.trussSystemId,
      'length_m': truss.lengthM,
      'max_total_load_kg': truss.maxTotalLoadKg,
      'max_distributed_load_kg_per_m': truss.maxDistributedLoadKgPerM,
      'manual_load_kg': truss.manualLoadKg,
      'assigned_group_ids': truss.assignedGroupIds,
      'notes': truss.notes,
      'created_at': _iso(project.createdAt),
      'updated_at': _iso(project.updatedAt),
    });
  }

  Future<String> _upsert(
    String collection,
    String localId,
    Map<String, Object?> fields,
  ) async {
    final existing = await _pb
        .collection(collection)
        .getList(
          perPage: 1,
          filter: _pb.filter('local_id = {:localId}', {'localId': localId}),
        );

    final body = <String, Object?>{'local_id': localId, ...fields};

    if (existing.items.isNotEmpty) {
      final record = await _pb
          .collection(collection)
          .update(existing.items.first.id, body: body);
      return record.id;
    }

    final record = await _pb.collection(collection).create(body: body);
    return record.id;
  }

  String _iso(DateTime value) => value.toUtc().toIso8601String();
}
