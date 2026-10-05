enum MatchInvitationStatus { pending, accepted, declined }

class MatchPerson {
  const MatchPerson({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.invitationStatus,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final MatchInvitationStatus? invitationStatus;

  factory MatchPerson.fromJson(Map<String, dynamic> json) {
    return MatchPerson(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Player',
      avatarUrl: json['avatar_url']?.toString(),
      invitationStatus: _statusFromJson(json['status']?.toString()),
    );
  }

  static MatchInvitationStatus? _statusFromJson(String? value) {
    return switch (value) {
      'pending' => MatchInvitationStatus.pending,
      'accepted' => MatchInvitationStatus.accepted,
      'declined' => MatchInvitationStatus.declined,
      _ => null,
    };
  }
}

class MatchPeopleData {
  const MatchPeopleData({
    this.players = const <MatchPerson>[],
    this.invitedPlayers = const <MatchPerson>[],
  });

  final List<MatchPerson> players;
  final List<MatchPerson> invitedPlayers;

  factory MatchPeopleData.fromJson(Map<String, dynamic> json) {
    List<MatchPerson> parseList(dynamic raw) {
      if (raw is! List) return const <MatchPerson>[];

      return raw
          .whereType<Map>()
          .map(
            (item) => MatchPerson.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((person) => person.id.isNotEmpty)
          .toList(growable: false);
    }

    return MatchPeopleData(
      players: parseList(json['players']),
      invitedPlayers: parseList(json['invited_players']),
    );
  }
}
