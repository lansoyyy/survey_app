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

  // User signup
  Future<UserCredential> signup({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? username, // Optional username parameter
  }) async {
    try {
      // Validate that either email or username is provided
      bool hasEmail = email.isNotEmpty;
      bool hasUsername = username != null && username.isNotEmpty;

      if (!hasEmail && !hasUsername) {
        throw FirebaseAuthException(
          code: 'missing-identifier',
          message: 'Either email or username is required',
        );
      }

      // If email is provided, check if it's already in use
      if (hasEmail) {
        // Check if email is already in use
        final emailExists = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (!emailExists.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'An account already exists for this email',
          );
        }
      }

      // If username is provided, check if it's already taken
      if (hasUsername) {
        final userDoc = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();

        if (!userDoc.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'username-already-in-use',
            message: 'This username is already taken',
          );
        }
      }

      // Generate a placeholder email if none is provided
      String finalEmail = email;
      if (!hasEmail) {
        // Generate a placeholder email based on username and a domain
        finalEmail = '${username!}@surveyapp.local';
      }

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: finalEmail,
        password: password,
      );

      // Create user profile in Firestore
      if (userCredential.user != null) {
        final userProfile = UserProfile(
          userId: userCredential.user!.uid,
          name: name,
          email: hasEmail ? email : '', // Only store real email if provided
          age: age,
          gender: gender,
          registrationDate: DateTime.now(),
          lastLogin: DateTime.now(),
          accountStatus: 'active',
          username: username, // Include username in profile
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
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user is admin
      final adminDoc = await _firestore
          .collection('admin_users')
          .doc(userCredential.user!.uid)
          .get();
      if (!adminDoc.exists) {
        await _auth.signOut();
        throw Exception('User is not an admin');
      }

      // Update last login timestamp
      await _firestore
          .collection('admin_users')
          .doc(userCredential.user!.uid)
          .update({
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
      final adminDoc =
          await _firestore.collection('admin_users').doc(uid).get();
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

  // User login with email or username
  Future<UserCredential> login(String identifier, String password) async {
    try {
      // Check if identifier is an email
      bool isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(identifier);

      if (isEmail) {
        // Standard email login
        final UserCredential userCredential =
            await _auth.signInWithEmailAndPassword(
          email: identifier,
          password: password,
        );

        // Update last login timestamp
        if (userCredential.user != null) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }

        return userCredential;
      } else {
        // Username login - find user by username
        final userDoc = await _firestore
            .collection('users')
            .where('username', isEqualTo: identifier)
            .limit(1)
            .get();

        if (userDoc.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with this username',
          );
        }

        final userData = userDoc.docs.first.data();
        final userId = userDoc.docs.first.id;

        // For username-only accounts, we need to reconstruct the placeholder email
        // that was used during signup
        String loginEmail;
        if (userData['email'] == null ||
            (userData['email'] as String).isEmpty) {
          // This is a username-only account, reconstruct the placeholder email
          loginEmail = '${identifier}@surveyapp.local';
        } else {
          // This account has an email
          loginEmail = userData['email'] as String;
        }

        // Login with the reconstructed email
        final UserCredential userCredential =
            await _auth.signInWithEmailAndPassword(
          email: loginEmail,
          password: password,
        );

        // Update last login timestamp
        if (userCredential.user != null) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }

        return userCredential;
      }
    } catch (e) {
      rethrow;
    }
  }
}
