class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceLabel,
    this.renewalText,
    this.statusText,
    this.infoText,
    this.isCurrent = false,
    this.isSelectable = true,
    this.trialDays = 14,
  });

  final String id;
  final String name;
  final String description;
  final String priceLabel;
  final String? renewalText;
  final String? statusText;
  final String? infoText;
  final bool isCurrent;
  final bool isSelectable;
  final int trialDays;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priceLabel: json['price_label']?.toString() ?? r'$0.00',
      renewalText: json['renewal_text']?.toString(),
      statusText: json['status_text']?.toString(),
      infoText: json['info_text']?.toString(),
      isCurrent: json['is_current'] == true,
      isSelectable: json['is_selectable'] != false,
      trialDays: (json['trial_days'] as num?)?.toInt() ?? 14,
    );
  }

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? description,
    String? priceLabel,
    String? renewalText,
    String? statusText,
    String? infoText,
    bool? isCurrent,
    bool? isSelectable,
    int? trialDays,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      priceLabel: priceLabel ?? this.priceLabel,
      renewalText: renewalText ?? this.renewalText,
      statusText: statusText ?? this.statusText,
      infoText: infoText ?? this.infoText,
      isCurrent: isCurrent ?? this.isCurrent,
      isSelectable: isSelectable ?? this.isSelectable,
      trialDays: trialDays ?? this.trialDays,
    );
  }
}
