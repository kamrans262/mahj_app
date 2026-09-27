class CreateMatchFormState {
  const CreateMatchFormState({
    this.locationAddress,
    this.venueName = '',
    this.selectedDate,
    this.selectedTimeMinutes,
    this.isPublicMatch = true,
    this.isInviteOnly = false,
  });

  final String? locationAddress;
  final String venueName;
  final DateTime? selectedDate;
  final int? selectedTimeMinutes;
  final bool isPublicMatch;
  final bool isInviteOnly;

  bool get hasRequiredFields =>
      locationAddress != null &&
      locationAddress!.trim().isNotEmpty &&
      selectedDate != null &&
      selectedTimeMinutes != null;

  CreateMatchFormState copyWith({
    String? locationAddress,
    bool clearLocation = false,
    String? venueName,
    DateTime? selectedDate,
    bool clearDate = false,
    int? selectedTimeMinutes,
    bool clearTime = false,
    bool? isPublicMatch,
    bool? isInviteOnly,
  }) {
    return CreateMatchFormState(
      locationAddress: clearLocation
          ? null
          : locationAddress ?? this.locationAddress,
      venueName: venueName ?? this.venueName,
      selectedDate: clearDate ? null : selectedDate ?? this.selectedDate,
      selectedTimeMinutes: clearTime
          ? null
          : selectedTimeMinutes ?? this.selectedTimeMinutes,
      isPublicMatch: isPublicMatch ?? this.isPublicMatch,
      isInviteOnly: isInviteOnly ?? this.isInviteOnly,
    );
  }

  CreateMatchRequest? toRequest() {
    final date = selectedDate;
    final minutes = selectedTimeMinutes;
    final location = locationAddress?.trim();

    if (date == null ||
        minutes == null ||
        location == null ||
        location.isEmpty) {
      return null;
    }

    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    return CreateMatchRequest(
      locationAddress: location,
      venueName: venueName.trim().isEmpty ? null : venueName.trim(),
      startsAt: DateTime(date.year, date.month, date.day, hour, minute),
      isPublicMatch: isPublicMatch,
      isInviteOnly: isInviteOnly,
    );
  }
}

class CreateMatchRequest {
  const CreateMatchRequest({
    required this.locationAddress,
    required this.startsAt,
    required this.isPublicMatch,
    required this.isInviteOnly,
    this.venueName,
    this.locationId,
    this.latitude,
    this.longitude,
  });

  final String locationAddress;
  final String? venueName;
  final DateTime startsAt;
  final bool isPublicMatch;
  final bool isInviteOnly;

  // Backend-ready structured location fields. These remain null until the
  // location API/model supplies structured values instead of only an address.
  final String? locationId;
  final double? latitude;
  final double? longitude;
}
