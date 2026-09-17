class AppMetadata {
  const AppMetadata._();

  static const name = 'StageCalc';
  static const description =
      'Profesjonalne narzędzie do planowania zasilania, masy oraz infrastruktury technicznej wydarzeń.';
  static const version = '0.6.0';
  static const author = 'Julian Szymański';
  static const organization = 'GreenCrew';
  static const website = 'greencrew.pl';
  static const repository = 'GitHub';

  /// `owner/name` on GitHub - used to build the Releases API URL and the
  /// release page link for the update-check feature, distinct from
  /// [repository] above (a plain display label, not a URL).
  static const repositorySlug = 'DjGreenKrk/StageCalc';
  static const license = 'PolyForm Shield License 1.0.0';
  static const packageId = 'pl.greencrew.tools.stagecalc';
  static const ecosystem = 'Część ekosystemu GreenCrew Tools.';
  static const copyright = '© Julian Szymański / GreenCrew';
}
