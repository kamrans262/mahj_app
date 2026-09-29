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
    );
  }
}
