import '../domain/entities/location.dart';

abstract interface class LocationRepository {
  Future<List<Location>> getLocations();

  Future<void> saveLocation(Location location);

  Future<void> deleteLocation(String id);
}
