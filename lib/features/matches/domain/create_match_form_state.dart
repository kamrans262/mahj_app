class CreateMatchFormState {
  const CreateMatchFormState({
    this.matchName = '',
    this.locationAddress,
    this.venueName = '',
    this.notes = '',
    this.selectedDate,
    this.selectedTimeMinutes,
    this.isPublicMatch = true,
    this.isInviteOnly = false,
  });

  final String matchName;
  final String? locationAddress;
  final String venueName;
  final String notes;
  final DateTime? selectedDate;
  final int? selectedTimeMinutes;
  final bool isPublicMatch;
  final bool isInviteOnly;

  bool get hasRequiredFields =>
      matchName.trim().isNotEmpty &&
      locationAddress != null &&
      locationAddress!.trim().isNotEmpty &&
      selectedDate != null &&
      selectedTimeMinutes != null;

  CreateMatchFormState copyWith({
    String? matchName,
    String? locationAddress,
    bool clearLocation = false,
    String? venueName,
    String? notes,
    DateTime? selectedDate,
    bool clearDate = false,
    int? selectedTimeMinutes,
    bool clearTime = false,
    bool? isPublicMatch,
    bool? isInviteOnly,
  }) {
    return CreateMatchFormState(
      matchName: matchName ?? this.matchName,
      locationAddress: clearLocation
          ? null
          : locationAddress ?? this.locationAddress,
      venueName: venueName ?? this.venueName,
      notes: notes ?? this.notes,
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
    final name = matchName.trim();
    final location = locationAddress?.trim();

    if (name.isEmpty ||
        date == null ||
        minutes == null ||
        location == null ||
        location.isEmpty) {
      return null;
    }

    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    return CreateMatchRequest(
      matchName: name,
      locationAddress: location,
      venueName: venueName.trim().isEmpty ? null : venueName.trim(),
      notes: notes.trim().isEmpty ? null : notes.trim(),
      startsAt: DateTime(date.year, date.month, date.day, hour, minute),
      isPublicMatch: isPublicMatch,
      isInviteOnly: isInviteOnly,
    );
  }
}

class CreateMatchRequest {
  const CreateMatchRequest({
    required this.matchName,
    required this.locationAddress,
    required this.startsAt,
    required this.isPublicMatch,
    required this.isInviteOnly,
    this.venueName,
    this.notes,
    this.locationId,
    this.latitude,
    this.longitude,
  });

  final String matchName;
  final String locationAddress;
  final String? venueName;
  final String? notes;
  final DateTime startsAt;
  final bool isPublicMatch;
  final bool isInviteOnly;

  // Backend-ready structured location fields. These remain null until the
  // location API/model supplies structured values instead of only an address.
  final String? locationId;
  final double? latitude;
  final double? longitude;
}
