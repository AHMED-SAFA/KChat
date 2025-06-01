import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? _user;

  User? get user {
    return _user;
  }

  AuthService() {
    _firebaseAuth.authStateChanges().listen(authListener);
  }

  Future<bool> login(String email, String password) async {
    try {
      final credencial = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credencial.user != null) {
        // Check if email is verified
        await credencial.user!.reload(); // Refresh user data
        if (credencial.user!.emailVerified) {
          _user = credencial.user;
          return true;
        } else {
          // Email not verified, sign out the user
          await _firebaseAuth.signOut();
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Please verify your email address before logging in.',
          );
        }
      }
    } catch (e) {
      print(e);
      rethrow; // Re-throw to handle in UI
    }
    return false;
  }

  void authListener(User? user) {
    if (user != null) {
      _user = user;
    } else {
      _user = null;
    }
  }

  Future<bool> logout() async {
    try {
      await _firebaseAuth.signOut();
      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  // Auth registration with email verification
  Future<UserCredential> register(String email, String password) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    // Send email verification
    await userCredential.user!.sendEmailVerification();

    return userCredential;
  }

  // Method to resend verification email with email/password
  Future<void> resendVerificationEmail(String email, String password) async {
    try {
      // Sign in the user temporarily to get access to send verification email
      UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = credential.user;
      if (user != null && !user.emailVerified) {
        // Send new verification email (this automatically invalidates previous ones)
        await user.sendEmailVerification();
        // Sign out immediately after sending verification
        await _firebaseAuth.signOut();
      }
    } catch (e) {
      print('Error resending verification email: $e');
      rethrow;
    }
  }

  // Method to check if current user's email is verified
  Future<bool> isEmailVerified() async {
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }
}
