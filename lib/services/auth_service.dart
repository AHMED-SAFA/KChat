import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
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
          email: email, password: password);
      if (credencial.user != null) {
        _user = credencial.user;
        return true;
      }
    } catch (e) {
      print(e);
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

  //auth registration
  Future<UserCredential> register(String email, String password) async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }


}
