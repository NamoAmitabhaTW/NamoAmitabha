import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'auth_provider.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;

  final AuthProvider? primaryProvider;

  final List<AuthProvider> providers;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.primaryProvider,
    this.providers = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromFirebaseUser(fb.User u, {AuthProvider? primary}) {
    final linked = u.providerData
        .map((p) => AuthProviderX.fromProviderId(p.providerId))
        .where((e) => e != AuthProvider.unknown)
        .toList();

    return AppUser(
      uid: u.uid,
      email: u.email,
      displayName: u.displayName,
      photoUrl: u.photoURL,
      isAnonymous: u.isAnonymous,
      primaryProvider:
          primary ??
          (linked.isNotEmpty
              ? linked.first
              : (u.isAnonymous ? AuthProvider.anonymous : null)),
      providers: linked,
    );
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    final primary = AuthProviderX.fromShort(map['provider'] as String?);
    final list =
        (map['providers'] as List?)
            ?.map((e) => AuthProviderX.fromShort(e as String?))
            .where((e) => e != AuthProvider.unknown)
            .toList() ??
        const <AuthProvider>[];

    return AppUser(
      uid: uid,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      isAnonymous: (map['isAnonymous'] as bool?) ?? false,
      primaryProvider: primary != AuthProvider.unknown ? primary : null,
      providers: list,
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'isAnonymous': isAnonymous};
    if (email != null) map['email'] = email;
    if (displayName != null) map['displayName'] = displayName;
    if (photoUrl != null) map['photoUrl'] = photoUrl;
    if (primaryProvider != null) map['provider'] = primaryProvider!.short;
    if (providers.isNotEmpty)
      map['providers'] = providers.map((e) => e.short).toList();
    if (createdAt != null) map['createdAt'] = createdAt;
    if (updatedAt != null) map['updatedAt'] = updatedAt;
    return map;
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    AuthProvider? primaryProvider,
    List<AuthProvider>? providers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      primaryProvider: primaryProvider ?? this.primaryProvider,
      providers: providers ?? this.providers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
