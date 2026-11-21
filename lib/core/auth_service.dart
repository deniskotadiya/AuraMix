import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'monetization_config.dart';
import 'iap_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ValueNotifier<UserProfile?> currentUserNotifier = ValueNotifier<UserProfile?>(null);
  final Set<String> _sessionUnlockedControls = {};

  UserProfile? get currentUser => currentUserNotifier.value;
  bool get isSignedIn => currentUserNotifier.value != null;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isVip = IAPService.instance.isVip;

    if (MonetizationConfig.firebaseEnabled) {
      try {
        final fbUser = FirebaseAuth.instance.currentUser;
        if (fbUser != null) {
          currentUserNotifier.value = UserProfile(
            uid: fbUser.uid,
            displayName: fbUser.displayName?.isNotEmpty == true ? fbUser.displayName! : 'Audiophile Pilot',
            email: fbUser.email ?? 'driver@auramix.app',
            isVip: isVip,
            sessionUnlockedControls: _sessionUnlockedControls,
          );
          return;
        }
      } catch (e) {
        debugPrint('[AuthService] Firebase auth check error: $e');
      }
    }

    // Check local profile
    final storedEmail = prefs.getString('auramix_user_email');
    if (storedEmail != null) {
      final name = prefs.getString('auramix_user_name') ?? 'Car Pilot';
      final uid = prefs.getString('auramix_user_uid') ?? 'local_pilot_01';
      currentUserNotifier.value = UserProfile(
        uid: uid,
        displayName: name,
        email: storedEmail,
        isVip: isVip,
        sessionUnlockedControls: _sessionUnlockedControls,
      );
    }
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
    bool isSignUp = false,
  }) async {
    if (MonetizationConfig.firebaseEnabled) {
      if (isSignUp) {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (displayName != null && displayName.trim().isNotEmpty) {
          await credential.user?.updateDisplayName(displayName.trim());
        }
        currentUserNotifier.value = UserProfile(
          uid: credential.user!.uid,
          displayName: displayName ?? 'Audiophile Driver',
          email: credential.user!.email ?? email,
          isVip: IAPService.instance.isVip,
          sessionUnlockedControls: _sessionUnlockedControls,
        );
      } else {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        currentUserNotifier.value = UserProfile(
          uid: credential.user!.uid,
          displayName: credential.user?.displayName ?? 'Audiophile Driver',
          email: credential.user!.email ?? email,
          isVip: IAPService.instance.isVip,
          sessionUnlockedControls: _sessionUnlockedControls,
        );
      }
    } else {
      // Local persistent profile mode
      final prefs = await SharedPreferences.getInstance();
      final name = displayName?.trim().isNotEmpty == true ? displayName!.trim() : 'Audiophile Pilot';
      final uid = 'pilot_${DateTime.now().millisecondsSinceEpoch % 100000}';

      await prefs.setString('auramix_user_email', email.trim());
      await prefs.setString('auramix_user_name', name);
      await prefs.setString('auramix_user_uid', uid);

      currentUserNotifier.value = UserProfile(
        uid: uid,
        displayName: name,
        email: email.trim(),
        isVip: IAPService.instance.isVip,
        sessionUnlockedControls: _sessionUnlockedControls,
      );
    }
  }

  Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    const guestEmail = 'guest.driver@auramix.app';
    const guestName = 'Night Driver (Guest)';
    final uid = 'guest_${DateTime.now().millisecondsSinceEpoch % 10000}';

    await prefs.setString('auramix_user_email', guestEmail);
    await prefs.setString('auramix_user_name', guestName);
    await prefs.setString('auramix_user_uid', uid);

    currentUserNotifier.value = UserProfile(
      uid: uid,
      displayName: guestName,
      email: guestEmail,
      isVip: IAPService.instance.isVip,
      sessionUnlockedControls: _sessionUnlockedControls,
    );
  }

  void unlockControlForSession(String controlKey) {
    _sessionUnlockedControls.add(controlKey);
    if (currentUserNotifier.value != null) {
      currentUserNotifier.value = currentUserNotifier.value!.copyWith(
        sessionUnlockedControls: Set<String>.from(_sessionUnlockedControls),
      );
    }
  }

  bool isControlUnlocked(String controlKey) {
    if (IAPService.instance.isVip) return true;
    return _sessionUnlockedControls.contains(controlKey);
  }

  Future<void> signOut() async {
    if (MonetizationConfig.firebaseEnabled) {
      await FirebaseAuth.instance.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auramix_user_email');
    await prefs.remove('auramix_user_name');
    await prefs.remove('auramix_user_uid');
    _sessionUnlockedControls.clear();
    currentUserNotifier.value = null;
  }
}
