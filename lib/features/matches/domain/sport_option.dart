class SportOption {
  const SportOption({
    required this.name,
    required this.slug,
    required this.iconKey,
    this.id,
  });

  final int? id;
  final String name;
  final String slug;
  final String iconKey;

  bool get isOther => slug == 'other';

  static const SportOption other = SportOption(
    name: 'Other',
    slug: 'other',
    iconKey: 'generic',
  );

  factory SportOption.fromJson(Map<String, dynamic> json) {
    return SportOption(
      id: (json['id'] as num?)?.toInt(),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? 'generic',
    );
  }
}
