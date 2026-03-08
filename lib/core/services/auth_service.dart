import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp(String email, String password) async {
    try {
      dev.log("SignUp Attempt: $email", name: "AUTH_SERVICE");
      
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      dev.log("SignUp Success: ${result.user?.uid}", name: "AUTH_SERVICE");

      return result;
    } on FirebaseAuthException catch (e) {
      dev.log("SignUp Firebase Error", error: e, name: "AUTH_SERVICE");
      rethrow;
    } catch (e) {
      dev.log("SignUp Unknown Error", error: e, name: "AUTH_SERVICE");
      rethrow;
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    try {
      dev.log("SignIn Attempt: $email", name: "AUTH_SERVICE");

      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      dev.log("SignIn Success: ${result.user?.uid}", name: "AUTH_SERVICE");

      return result;
    } on FirebaseAuthException catch (e) {
      dev.log("SignIn Firebase Error", error: e, name: "AUTH_SERVICE");
      rethrow;
    } catch (e) {
      dev.log("SignIn Unknown Error", error: e, name: "AUTH_SERVICE");
      rethrow;
    }
  }

  Future<void> signOut() async {
    dev.log("User Signing Out", name: "AUTH_SERVICE");
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    dev.log("Sending Reset Email: $email", name: "AUTH_SERVICE");
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendEmailVerification() async {
    dev.log("Sending Email Verification", name: "AUTH_SERVICE");
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> deleteAccount() async {
    dev.log("Deleting Account", name: "AUTH_SERVICE");
    await _auth.currentUser?.delete();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      dev.log("Google SignIn Attempt", name: "AUTH_SERVICE");
      
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        dev.log("Google SignIn Cancelled", name: "AUTH_SERVICE");
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      dev.log("Google SignIn Success: ${result.user?.uid}", name: "AUTH_SERVICE");
      
      return result;
    } catch (e) {
      dev.log("Google SignIn Error", error: e, name: "AUTH_SERVICE");
      rethrow;
    }
  }
}