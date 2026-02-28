import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';

// ---------------------------------------------------------------------------
// 인증 레포지토리 프로바이더 (auth_repository.dart에서 re-export)
// ---------------------------------------------------------------------------

export '../data/repositories/auth_repository.dart'
    show authRepositoryProvider, authStateProvider;

// ---------------------------------------------------------------------------
// 현재 Firebase User 프로바이더
// ---------------------------------------------------------------------------

/// 현재 로그인된 Firebase [User]를 노출합니다.
/// 로그인되지 않았으면 null.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// ---------------------------------------------------------------------------
// 인증 여부
// ---------------------------------------------------------------------------

/// 사용자가 현재 로그인되어 있으면 true.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// 현재 사용자가 익명인지 여부
final isAnonymousProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAnonymous ?? false;
});

// ---------------------------------------------------------------------------
// 현재 사용자 UID
// ---------------------------------------------------------------------------

/// 현재 사용자 UID. 로그인되지 않았으면 null.
final currentUserUidProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

// ---------------------------------------------------------------------------
// 현재 사용자 Firestore 프로필
// ---------------------------------------------------------------------------

/// 현재 로그인된 사용자의 Firestore [UserProfile] 스트림.
///
/// 로그인하지 않은 경우 null을 방출합니다.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUserUidProvider);
  if (uid == null) {
    return const Stream.empty();
  }
  return ref.watch(userRepositoryProvider).getUserProfileStream(uid);
});

// ---------------------------------------------------------------------------
// 로그인 상태 AsyncValue (로딩 상태 추적)
// ---------------------------------------------------------------------------

/// [authStateProvider]의 AsyncValue를 그대로 노출합니다.
/// UI에서 로딩/오류/데이터 상태를 분기할 때 사용합니다.
final authAsyncProvider = Provider<AsyncValue<User?>>((ref) {
  return ref.watch(authStateProvider);
});
