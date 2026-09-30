class DiscoveryLocation {
  const DiscoveryLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
    this.city = '',
    this.state = '',
    this.zipCode = '',
  });

  const DiscoveryLocation.current({
    required this.latitude,
    required this.longitude,
  }) : label = 'Current Location',
       city = '',
       state = '',
       zipCode = '';

  final String label;
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String zipCode;

  factory DiscoveryLocation.fromJson(Map<String, dynamic> json) {
    return DiscoveryLocation(
      label: json['label']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      zipCode: json['zip_code']?.toString() ?? '',
    );
  }
}
