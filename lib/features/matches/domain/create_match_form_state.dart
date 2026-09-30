import 'sport_option.dart';

class CreateMatchFormState {
  const CreateMatchFormState({
    this.selectedSport,
    this.customSportName = '',
    this.locationAddress,
    this.venueName = '',
    this.notes = '',
    this.selectedDate,
    this.selectedTimeMinutes,
    this.isPublicMatch = true,
    this.isInviteOnly = false,
  });

  final SportOption? selectedSport;
  final String customSportName;
  final String? locationAddress;
  final String venueName;
  final String notes;
  final DateTime? selectedDate;
  final int? selectedTimeMinutes;
  final bool isPublicMatch;
  final bool isInviteOnly;

  String get effectiveSportName {
    final sport = selectedSport;
    if (sport == null) return '';
    if (sport.isOther) return customSportName.trim();
    return sport.name;
  }

  bool get hasRequiredFields =>
      selectedSport != null &&
      effectiveSportName.isNotEmpty &&
      locationAddress != null &&
      locationAddress!.trim().isNotEmpty &&
      selectedDate != null &&
      selectedTimeMinutes != null;

  CreateMatchFormState copyWith({
    SportOption? selectedSport,
    bool clearSport = false,
    String? customSportName,
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
      selectedSport: clearSport ? null : selectedSport ?? this.selectedSport,
      customSportName: customSportName ?? this.customSportName,
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
    final sport = selectedSport;
    final date = selectedDate;
    final minutes = selectedTimeMinutes;
    final sportName = effectiveSportName;
    final location = locationAddress?.trim();

    if (sport == null ||
        sportName.isEmpty ||
        date == null ||
        minutes == null ||
        location == null ||
        location.isEmpty) {
      return null;
    }

    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    return CreateMatchRequest(
      sportId: sport.isOther ? null : sport.id,
      customSportName: sport.isOther ? sportName : null,
      sportName: sportName,
      sportSlug: sport.isOther ? null : sport.slug,
      sportIconKey: sport.isOther ? 'generic' : sport.iconKey,
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
    required this.sportName,
    required this.sportIconKey,
    required this.locationAddress,
    required this.startsAt,
    required this.isPublicMatch,
    required this.isInviteOnly,
    this.sportId,
    this.sportSlug,
    this.customSportName,
    this.venueName,
    this.notes,
    this.locationId,
    this.latitude,
    this.longitude,
  });

  final int? sportId;
  final String? sportSlug;
  final String? customSportName;
  final String sportName;
  final String sportIconKey;
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
