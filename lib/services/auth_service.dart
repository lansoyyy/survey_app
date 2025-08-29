import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_app/models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // User login
  Future<UserCredential> login(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login timestamp
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // User signup
  Future<UserCredential> signup({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      if (userCredential.user != null) {
        final userProfile = UserProfile(
          userId: userCredential.user!.uid,
          name: name,
          email: email,
          age: age,
          gender: gender,
          registrationDate: DateTime.now(),
          lastLogin: DateTime.now(),
          accountStatus: 'active',
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set(
              userProfile.toJson(),
            );
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Admin login
  Future<UserCredential> adminLogin(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if user is admin
      final adminDoc = await _firestore.collection('admin_users').doc(userCredential.user!.uid).get();
      if (!adminDoc.exists) {
        await _auth.signOut();
        throw Exception('User is not an admin');
      }
      
      // Update last login timestamp
      await _firestore.collection('admin_users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin(String uid) async {
    try {
      final adminDoc = await _firestore.collection('admin_users').doc(uid).get();
      return adminDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}