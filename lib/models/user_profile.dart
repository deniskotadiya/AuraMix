class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final bool isVip;
  final Set<String> sessionUnlockedControls;
  final List<String> likedPresetIds;
  final int presetsCreated;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.isVip = false,
    this.sessionUnlockedControls = const {},
    this.likedPresetIds = const [],
    this.presetsCreated = 0,
  });

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    bool? isVip,
    Set<String>? sessionUnlockedControls,
    List<String>? likedPresetIds,
    int? presetsCreated,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isVip: isVip ?? this.isVip,
      sessionUnlockedControls: sessionUnlockedControls ?? this.sessionUnlockedControls,
      likedPresetIds: likedPresetIds ?? this.likedPresetIds,
      presetsCreated: presetsCreated ?? this.presetsCreated,
    );
  }

  bool isControlUnlocked(String controlKey) {
    if (isVip) return true;
    return sessionUnlockedControls.contains(controlKey);
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'isVip': isVip,
    'likedPresetIds': likedPresetIds,
    'presetsCreated': presetsCreated,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'] as String? ?? 'guest_user',
    displayName: json['displayName'] as String? ?? 'Audiophile Driver',
    email: json['email'] as String? ?? 'user@auramix.app',
    isVip: json['isVip'] as bool? ?? false,
    sessionUnlockedControls: {},
    likedPresetIds: (json['likedPresetIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    presetsCreated: (json['presetsCreated'] as num?)?.toInt() ?? 0,
  );
}
