import '../domain/entities/catalog_device.dart';

class DemoCatalogFactory {
  const DemoCatalogFactory._();

  static List<CatalogDevice> createSeedDevices() {
    final now = DateTime(2026, 7, 5);

    return [
      CatalogDevice(
        id: 'robe_bmfl_spot',
        name: 'BMFL Spot',
        manufacturer: 'Robe',
        category: CatalogDeviceCategory.device,
        powerW: 2000,
        currentA: 8.7,
        weightKg: 36,
        connectorTypeId: 'powercon_true1',
        quantityUnit: CatalogQuantityUnit.pcs,
        createdAt: now,
        updatedAt: now,
      ),
      CatalogDevice(
        id: 'led_par_rgbw',
        name: 'LED Par RGBW',
        manufacturer: 'Generic',
        category: CatalogDeviceCategory.device,
        powerW: 200,
        currentA: 0.9,
        weightKg: 4,
        connectorTypeId: 'powercon',
        quantityUnit: CatalogQuantityUnit.pcs,
        createdAt: now,
        updatedAt: now,
      ),
      CatalogDevice(
        id: 'distro_32a_5p',
        name: 'Rozdzielnia 32 A CEE',
        manufacturer: 'GreenCrew',
        category: CatalogDeviceCategory.distribution,
        powerW: 0,
        currentA: 0,
        weightKg: 18,
        connectorTypeId: 'cee_32a_5p',
        quantityUnit: CatalogQuantityUnit.pcs,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
