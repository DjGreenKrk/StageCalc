import '../../../catalog/domain/entities/catalog_device.dart';
import 'gremium_pack_list.dart';

/// Best-effort guess of an existing `CatalogDeviceCategory` from Gremium's
/// free-text category/name (ADR-034) - never invents a new taxonomy of its
/// own, only picks among the same categories already used everywhere else
/// in the catalog. Always overridable by the user in the review panel and
/// re-categorizable later on the Catalog screen, exactly like any other
/// device.
CatalogDeviceCategory guessGremiumCategory(GremiumItem item) {
  final category = (item.category ?? '').toLowerCase();
  final name = '${item.name} ${item.projectLabel ?? ''}'.toLowerCase();

  bool nameHas(String needle) => name.contains(needle);
  bool categoryIs(String needle) => category.contains(needle);

  if (categoryIs('kabel') ||
      categoryIs('xlr') ||
      nameHas('kabel') ||
      nameHas('cable') ||
      nameHas('przewód') ||
      nameHas('multicore') ||
      nameHas('przedłużacz') ||
      nameHas('xlr')) {
    return CatalogDeviceCategory.cable;
  }
  if (categoryIs('rigging') ||
      nameHas('trawers') ||
      nameHas('hak') ||
      nameHas('kratownic')) {
    return CatalogDeviceCategory.rigging;
  }
  if (categoryIs('zasilanie') || categoryIs('dystrybu')) {
    return CatalogDeviceCategory.distribution;
  }
  if (categoryIs('audio') ||
      categoryIs('nagłośnienie') ||
      categoryIs('dźwięk') ||
      categoryIs('mikrofon')) {
    return CatalogDeviceCategory.sound;
  }
  if (categoryIs('multimedia') || categoryIs('wideo') || categoryIs('projek')) {
    return CatalogDeviceCategory.multimedia;
  }
  if (categoryIs('oświetlenie') || categoryIs('lighting') || nameHas('lampa')) {
    return CatalogDeviceCategory.lighting;
  }
  return CatalogDeviceCategory.other;
}
