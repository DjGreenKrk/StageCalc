import '../../../catalog/domain/entities/catalog_device.dart';
import 'gremium_pack_list.dart';

/// What kind of device a Gremium item is, chosen by the user (or guessed) in
/// the import review panel (ADR-034) - decides which fields count as
/// "missing" after import and which `CatalogDeviceCategory` a newly created
/// device gets.
enum GremiumDeviceType {
  singlePhase,
  threePhase,
  passive,
  cable,
  rigging;

  String get label => switch (this) {
    GremiumDeviceType.singlePhase => 'Odbiornik jednofazowy',
    GremiumDeviceType.threePhase => 'Odbiornik trójfazowy',
    GremiumDeviceType.passive => 'Urządzenie pasywne',
    GremiumDeviceType.cable => 'Kabel',
    GremiumDeviceType.rigging => 'Element riggingowy',
  };

  bool get requiresElectricalData =>
      this == GremiumDeviceType.singlePhase ||
      this == GremiumDeviceType.threePhase;

  bool get requiresRiggingPoints => this == GremiumDeviceType.rigging;
}

/// Best-effort guess from Gremium's free-text category/name - always
/// overridable by the user in the review panel, never blocks anything.
GremiumDeviceType guessGremiumDeviceType(GremiumItem item) {
  final category = (item.category ?? '').toLowerCase();
  final name = '${item.name} ${item.projectLabel ?? ''}'.toLowerCase();

  bool nameHas(String needle) => name.contains(needle);
  bool categoryIs(String needle) => category.contains(needle);

  if (nameHas('kabel') ||
      nameHas('cable') ||
      nameHas('przewód') ||
      nameHas('multicore')) {
    return GremiumDeviceType.cable;
  }
  if (categoryIs('rigging') ||
      nameHas('trawers') ||
      nameHas('hak') ||
      nameHas('kratownic')) {
    return GremiumDeviceType.rigging;
  }
  if (categoryIs('zasilanie') ||
      categoryIs('statyw') ||
      categoryIs('akcesori') ||
      nameHas('przedłużacz') ||
      nameHas('listwa') ||
      nameHas('statyw') ||
      nameHas('taca')) {
    return GremiumDeviceType.passive;
  }
  return GremiumDeviceType.singlePhase;
}

/// Maps a device type + Gremium's free-text category to the closed
/// `CatalogDeviceCategory` enum - always a best effort, freely correctable
/// afterwards on the Catalog screen.
CatalogDeviceCategory guessCatalogCategory(
  GremiumDeviceType type,
  String? gremiumCategory,
) {
  if (type == GremiumDeviceType.cable) {
    return CatalogDeviceCategory.cable;
  }
  if (type == GremiumDeviceType.rigging) {
    return CatalogDeviceCategory.rigging;
  }

  final text = (gremiumCategory ?? '').toLowerCase();
  if (text.contains('audio') ||
      text.contains('nagłośnienie') ||
      text.contains('dźwięk') ||
      text.contains('mikrofon')) {
    return CatalogDeviceCategory.sound;
  }
  if (text.contains('multimedia') ||
      text.contains('wideo') ||
      text.contains('projek')) {
    return CatalogDeviceCategory.multimedia;
  }
  if (text.contains('zasilanie') || text.contains('dystrybu')) {
    return CatalogDeviceCategory.distribution;
  }
  if (text.contains('oświetlenie') ||
      text.contains('lighting') ||
      text.contains('lampa')) {
    return CatalogDeviceCategory.lighting;
  }
  return CatalogDeviceCategory.other;
}
