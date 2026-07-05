import '../domain/entities/catalog_device.dart';

abstract interface class CatalogRepository {
  Future<List<CatalogDevice>> getDevices();

  Future<void> saveDevice(CatalogDevice device);

  Future<void> deleteDevice(String id);

  Future<void> ensureSeedData();
}
