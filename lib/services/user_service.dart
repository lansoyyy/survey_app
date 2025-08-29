import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_app/models/user_profile.dart';
import 'package:survey_app/models/health_metrics.dart';
import 'package:survey_app/models/survey_response.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user profile
  Future<UserProfile> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data()!);
      } else {
        throw Exception('User profile not found');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Get all users (for admin)
  Stream<List<UserProfile>> getAllUsers() {
    try {
      return _firestore.collection('users').snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => UserProfile.fromJson(doc.data()))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Get user health metrics
  Stream<List<HealthMetrics>> getUserHealthMetrics(String uid) {
    try {
      return _firestore
          .collection('health_metrics')
          .where('userId', isEqualTo: uid)
          .orderBy('recordedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => HealthMetrics.fromJson(doc.data()))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch health metrics: $e');
    }
  }

  // Add health metrics
  Future<void> addHealthMetrics(HealthMetrics metrics) async {
    try {
      await _firestore.collection('health_metrics').add(metrics.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Get user survey responses
  Stream<List<SurveyResponse>> getUserSurveyResponses(String uid) {
    try {
      return _firestore
          .collection('survey_responses')
          .where('userId', isEqualTo: uid)
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => SurveyResponse.fromJson(doc.data()))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch survey responses: $e');
    }
  }

  // Submit survey response
  Future<void> submitSurveyResponse(SurveyResponse response) async {
    try {
      await _firestore.collection('survey_responses').add(response.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Deactivate user account
  Future<void> deactivateUserAccount(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'accountStatus': 'inactive',
      });
    } catch (e) {
      rethrow;
    }
  }

  // Activate user account
  Future<void> activateUserAccount(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'accountStatus': 'active',
      });
    } catch (e) {
      rethrow;
    }
  }
}