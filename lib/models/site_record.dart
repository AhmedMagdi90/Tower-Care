class SiteRecord {
  const SiteRecord({
    required this.siteName,
    required this.governorate,
    this.lat,
    this.long,
    this.siteType,
    this.powerType,
    this.transmission,
    this.numSectors,
    this.address,
  });

  final String siteName;
  final String governorate;
  final double? lat;
  final double? long;
  final String? siteType;
  final String? powerType;
  final String? transmission;
  final int? numSectors;
  final String? address;

  Map<String, Object?> toMap() {
    return {
      'site_name': siteName,
      'governorate': governorate,
      'lat': lat,
      'long': long,
      'site_type': siteType,
      'power_type': powerType,
      'transmission': transmission,
      'num_sectors': numSectors,
      'address': address,
    };
  }
}
