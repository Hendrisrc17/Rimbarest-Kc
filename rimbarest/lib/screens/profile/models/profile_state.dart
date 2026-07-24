class ProfileState {
  final bool notif;
  final bool location;
  final bool nightMode;
  final String interval;

  const ProfileState({
    required this.notif,
    required this.location,
    required this.nightMode,
    required this.interval,
  });

  factory ProfileState.fromUser(Map<String, dynamic> user) {
    return ProfileState(
      notif: user["notification_enabled"] ?? true,
      location: user["location_enabled"] ?? true,
      nightMode: user["night_mode"] ?? false,
      interval: user["sync_interval"] ?? "5 detik",
    );
  }

  ProfileState copyWith({
    bool? notif,
    bool? location,
    bool? nightMode,
    String? interval,
  }) {
    return ProfileState(
      notif: notif ?? this.notif,
      location: location ?? this.location,
      nightMode: nightMode ?? this.nightMode,
      interval: interval ?? this.interval,
    );
  }
}
