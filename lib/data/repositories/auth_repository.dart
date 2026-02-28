import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ---------------------------------------------------------------------------
// 인증 결과 타입
// ---------------------------------------------------------------------------

sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  final User user;
  const AuthSuccess(this.user);
}

class AuthFailure extends AuthResult {
  final String message;
  final Object? error;
  const AuthFailure(this.message, {this.error});
}

// ---------------------------------------------------------------------------
// AuthRepository
// ---------------------------------------------------------------------------

/// 인증 레포지토리
///
/// Firebase Auth를 통해 Google, Apple(플레이스홀더), 익명 로그인을 지원합니다.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
            );

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  // ---------------------------------------------------------------------------
  // 현재 상태 접근
  // ---------------------------------------------------------------------------

  /// 현재 로그인된 사용자. 로그인하지 않은 경우 null.
  User? get currentUser => _auth.currentUser;

  /// 인증 상태 변화 스트림 (로그인/로그아웃 이벤트)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 현재 사용자가 로그인 상태인지 여부
  bool get isAuthenticated => _auth.currentUser != null;

  // ---------------------------------------------------------------------------
  // Google 로그인
  // ---------------------------------------------------------------------------

  /// Google 계정으로 로그인합니다.
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자가 로그인 취소
        return const AuthFailure('Google 로그인이 취소되었습니다.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        return const AuthFailure('Google 로그인에 실패했습니다.');
      }

      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(
        _firebaseAuthErrorMessage(e.code),
        error: e,
      );
    } catch (e) {
      return AuthFailure('알 수 없는 오류가 발생했습니다.', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Apple 로그인 (플레이스홀더 – iOS 전용 네이티브 설정 필요)
  // ---------------------------------------------------------------------------

  /// Apple 계정으로 로그인합니다.
  ///
  /// 실제 구현을 위해서는 `sign_in_with_apple` 패키지와
  /// iOS 네이티브 설정(Capabilities → Sign In with Apple)이 필요합니다.
  Future<AuthResult> signInWithApple() async {
    try {
      // TODO: sign_in_with_apple 패키지 추가 후 실제 구현으로 교체
      // final credential = await SignInWithApple.getAppleIDCredential(...)
      // final oauthCredential = OAuthProvider('apple.com').credential(...)
      // final userCredential = await _auth.signInWithCredential(oauthCredential)
      return const AuthFailure(
        'Apple 로그인은 아직 구현되지 않았습니다. sign_in_with_apple 패키지를 추가해주세요.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_firebaseAuthErrorMessage(e.code), error: e);
    } catch (e) {
      return AuthFailure('알 수 없는 오류가 발생했습니다.', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // 익명 로그인
  // ---------------------------------------------------------------------------

  /// 익명으로 로그인합니다.
  ///
  /// 앱을 먼저 둘러보고 싶은 사용자에게 제공합니다.
  Future<AuthResult> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;
      if (user == null) {
        return const AuthFailure('익명 로그인에 실패했습니다.');
      }
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_firebaseAuthErrorMessage(e.code), error: e);
    } catch (e) {
      return AuthFailure('알 수 없는 오류가 발생했습니다.', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // 익명 계정 연동 (Google)
  // ---------------------------------------------------------------------------

  /// 익명 계정을 Google 계정으로 업그레이드합니다.
  Future<AuthResult> linkWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthFailure('Google 로그인이 취소되었습니다.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return const AuthFailure('현재 로그인된 사용자가 없습니다.');
      }

      final userCredential = await currentUser.linkWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        return const AuthFailure('계정 연동에 실패했습니다.');
      }

      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // 이미 연동된 Google 계정이면 일반 로그인으로 전환
        return signInWithGoogle();
      }
      return AuthFailure(_firebaseAuthErrorMessage(e.code), error: e);
    } catch (e) {
      return AuthFailure('알 수 없는 오류가 발생했습니다.', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // 로그아웃
  // ---------------------------------------------------------------------------

  /// 현재 사용자를 로그아웃합니다.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (_) {
      // 로그아웃 오류는 무시
    }
  }

  // ---------------------------------------------------------------------------
  // 계정 삭제
  // ---------------------------------------------------------------------------

  /// 현재 사용자 계정을 삭제합니다.
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const AuthFailure('로그인된 사용자가 없습니다.');
      }
      await user.delete();
      await _googleSignIn.signOut();
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_firebaseAuthErrorMessage(e.code), error: e);
    } catch (e) {
      return AuthFailure('계정 삭제 중 오류가 발생했습니다.', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // 내부 헬퍼
  // ---------------------------------------------------------------------------

  String _firebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return '동일한 이메일로 다른 로그인 방법을 사용하고 있습니다.';
      case 'invalid-credential':
        return '인증 정보가 유효하지 않습니다.';
      case 'user-disabled':
        return '이 계정은 비활성화되었습니다.';
      case 'user-not-found':
        return '해당 사용자를 찾을 수 없습니다.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      case 'too-many-requests':
        return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      case 'requires-recent-login':
        return '보안을 위해 다시 로그인해주세요.';
      default:
        return '인증 오류가 발생했습니다. ($code)';
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod 프로바이더
// ---------------------------------------------------------------------------

/// [AuthRepository] 프로바이더
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// 인증 상태 스트림 프로바이더 (User? — null이면 미로그인)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
