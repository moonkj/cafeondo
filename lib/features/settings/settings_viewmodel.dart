import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Notification Settings ─────────────────────────────────────────────────────

const _kNotifMeasurementKey = 'notif_measurement';
const _kNotifRankingKey = 'notif_ranking';
const _kNotifNewCafeKey = 'notif_new_cafe';

class NotificationSettings {
  final bool measurementAlert;
  final bool rankingChange;
  final bool newCafeAlert;

  const NotificationSettings({
    this.measurementAlert = true,
    this.rankingChange = false,
    this.newCafeAlert = true,
  });

  NotificationSettings copyWith({
    bool? measurementAlert,
    bool? rankingChange,
    bool? newCafeAlert,
  }) {
    return NotificationSettings(
      measurementAlert: measurementAlert ?? this.measurementAlert,
      rankingChange: rankingChange ?? this.rankingChange,
      newCafeAlert: newCafeAlert ?? this.newCafeAlert,
    );
  }
}

// ── Settings State ────────────────────────────────────────────────────────────

class SettingsState {
  final NotificationSettings notifications;
  final bool isPremium;
  final bool isLoading;
  final String appVersion;

  const SettingsState({
    this.notifications = const NotificationSettings(),
    this.isPremium = false,
    this.isLoading = false,
    this.appVersion = '1.0.0',
  });

  SettingsState copyWith({
    NotificationSettings? notifications,
    bool? isPremium,
    bool? isLoading,
    String? appVersion,
  }) {
    return SettingsState(
      notifications: notifications ?? this.notifications,
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}

// ── Settings ViewModel ────────────────────────────────────────────────────────

class SettingsViewModel extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadPreferences();
    return const SettingsState();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      state = state.copyWith(
        notifications: NotificationSettings(
          measurementAlert: prefs.getBool(_kNotifMeasurementKey) ?? true,
          rankingChange: prefs.getBool(_kNotifRankingKey) ?? false,
          newCafeAlert: prefs.getBool(_kNotifNewCafeKey) ?? true,
        ),
      );
    } catch (_) {
      // 기본값 유지
    }
  }

  Future<void> setMeasurementAlert(bool value) async {
    state = state.copyWith(
      notifications: state.notifications.copyWith(measurementAlert: value),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifMeasurementKey, value);
  }

  Future<void> setRankingChange(bool value) async {
    state = state.copyWith(
      notifications: state.notifications.copyWith(rankingChange: value),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifRankingKey, value);
  }

  Future<void> setNewCafeAlert(bool value) async {
    state = state.copyWith(
      notifications: state.notifications.copyWith(newCafeAlert: value),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifNewCafeKey, value);
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!ref.mounted) return;
    // 실제 구현: FirebaseAuth.instance.signOut()
    state = state.copyWith(isLoading: false);
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!ref.mounted) return;
    // 실제 구현: Firebase Auth user.delete()
    state = state.copyWith(isLoading: false);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final settingsProvider =
    NotifierProvider<SettingsViewModel, SettingsState>(
  SettingsViewModel.new,
);
