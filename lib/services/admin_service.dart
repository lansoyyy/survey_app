import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_app/models/user_profile.dart';
import 'package:survey_app/models/survey_response.dart';
import 'package:survey_app/models/health_metrics.dart';
import 'package:survey_app/models/analytics_data.dart';
import 'package:rxdart/rxdart.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users (for admin dashboard)
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

  // Get all survey responses
  Stream<List<SurveyResponse>> getAllSurveyResponses() {
    try {
      return _firestore
          .collection('survey_responses')
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

  // Get survey responses filtered by period
  Stream<List<SurveyResponse>> getSurveyResponsesByPeriod(String period) {
    try {
      DateTime startDate = _getStartDateForPeriod(period);
      
      return _firestore
          .collection('survey_responses')
          .where('submittedAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
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

  // Get all health metrics
  Stream<List<HealthMetrics>> getAllHealthMetrics() {
    try {
      return _firestore
          .collection('health_metrics')
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

  // Get analytics data - Calculate from actual data instead of fetching pre-calculated document
  Stream<AnalyticsData?> getAnalyticsData({String period = 'monthly'}) {
    try {
      // Combine streams for users and survey responses
      return Rx.combineLatest2<List<UserProfile>, List<SurveyResponse>, AnalyticsData?>(
        getAllUsers(),
        getSurveyResponsesByPeriod(period),
        (users, responses) {
          if (users.isEmpty) {
            return null;
          }
          
          // Calculate analytics data
          return _calculateAnalyticsData(users, responses, period);
        },
      ).handleError((error) {
        throw Exception('Failed to fetch analytics data: $error');
      });
    } catch (e) {
      throw Exception('Failed to fetch analytics data: $e');
    }
  }

  // Calculate analytics data from users and survey responses
  AnalyticsData _calculateAnalyticsData(List<UserProfile> users, List<SurveyResponse> responses, String period) {
    // Total users
    final totalUsers = users.length;
    
    // Active users (users with accountStatus 'active')
    final activeUsers = users.where((user) => user.accountStatus == 'active').length;
    
    // Average risk score
    double averageRiskScore = 0;
    if (responses.isNotEmpty) {
      double totalRiskScore = responses.fold(0, (sum, response) => sum + response.riskScore);
      averageRiskScore = totalRiskScore / responses.length;
    }
    
    // Completion rate (percentage of completed surveys)
    double completionRate = 0;
    if (responses.isNotEmpty) {
      final completedSurveys = responses.where((response) => response.completionStatus == 'completed').length;
      completionRate = (completedSurveys / responses.length) * 100;
    }
    
    // Demographic data
    final demographicData = _calculateDemographicData(users, responses);
    
    // Time-based data for charts
    final timeBasedData = _calculateTimeBasedData(responses, period);
    
    return AnalyticsData(
      analyticsId: 'latest',
      startDate: _getStartDateForPeriod(period),
      endDate: DateTime.now(),
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      averageRiskScore: averageRiskScore,
      completionRate: completionRate,
      demographicData: {
        ...demographicData,
        'timeBasedData': timeBasedData,
      },
    );
  }
  
  // Calculate demographic data
  Map<String, dynamic> _calculateDemographicData(List<UserProfile> users, List<SurveyResponse> responses) {
    // Gender distribution
    final genderDistribution = <String, int>{};
    for (var user in users) {
      final gender = user.gender;
      genderDistribution[gender] = (genderDistribution[gender] ?? 0) + 1;
    }
    
    // Age groups
    final ageGroups = <String, int>{};
    for (var user in users) {
      if (user.age < 18) {
        ageGroups['Under 18'] = (ageGroups['Under 18'] ?? 0) + 1;
      } else if (user.age < 30) {
        ageGroups['18-29'] = (ageGroups['18-29'] ?? 0) + 1;
      } else if (user.age < 50) {
        ageGroups['30-49'] = (ageGroups['30-49'] ?? 0) + 1;
      } else {
        ageGroups['50+'] = (ageGroups['50+'] ?? 0) + 1;
      }
    }
    
    // Risk levels
    final riskLevels = <String, int>{};
    for (var response in responses) {
      String riskLevel;
      if (response.riskScore <= 20) {
        riskLevel = 'Normal';
      } else if (response.riskScore <= 40) {
        riskLevel = 'Elevated';
      } else if (response.riskScore <= 60) {
        riskLevel = 'High';
      } else if (response.riskScore <= 80) {
        riskLevel = 'Very High';
      } else {
        riskLevel = 'Critical';
      }
      riskLevels[riskLevel] = (riskLevels[riskLevel] ?? 0) + 1;
    }
    
    // Convert risk levels to percentages
    final riskLevelPercentages = <String, double>{};
    if (responses.isNotEmpty) {
      riskLevels.forEach((level, count) {
        riskLevelPercentages[level] = (count / responses.length) * 100;
      });
    }
    
    return {
      'gender': genderDistribution,
      'ageGroups': ageGroups,
      'riskLevels': riskLevelPercentages,
    };
  }
  
  // Calculate time-based data for charts
  Map<String, dynamic> _calculateTimeBasedData(List<SurveyResponse> responses, String period) {
    final timeBasedData = <String, List<Map<String, dynamic>>>{};
    
    // Group responses by time period
    final groupedData = <String, List<SurveyResponse>>{};
    
    for (var response in responses) {
      String key;
      switch (period) {
        case 'daily':
          key = '${response.submittedAt.year}-${response.submittedAt.month}-${response.submittedAt.day}';
          break;
        case 'weekly':
          final weekNumber = (response.submittedAt.day / 7).ceil();
          key = '${response.submittedAt.year}-${response.submittedAt.month}-W$weekNumber';
          break;
        case 'monthly':
          key = '${response.submittedAt.year}-${response.submittedAt.month}';
          break;
        case 'yearly':
          key = '${response.submittedAt.year}';
          break;
        default:
          key = '${response.submittedAt.year}-${response.submittedAt.month}';
      }
      
      if (!groupedData.containsKey(key)) {
        groupedData[key] = [];
      }
      groupedData[key]!.add(response);
    }
    
    // Calculate metrics for each time period
    final userGrowthData = <Map<String, dynamic>>[];
    final completionRateData = <Map<String, dynamic>>[];
    final riskDistributionData = <Map<String, dynamic>>[];
    
    // Sort keys chronologically
    final sortedKeys = groupedData.keys.toList()
      ..sort((a, b) {
        // Simple sorting for demonstration - in a real app, you'd parse the dates properly
        return a.compareTo(b);
      });
    
    int cumulativeUsers = 0;
    for (var key in sortedKeys) {
      final periodResponses = groupedData[key]!;
      
      // User growth data
      cumulativeUsers += periodResponses.length;
      userGrowthData.add({
        'period': key,
        'users': cumulativeUsers,
      });
      
      // Completion rate data
      if (periodResponses.isNotEmpty) {
        final completedCount = periodResponses
            .where((response) => response.completionStatus == 'completed')
            .length;
        final completionRate = (completedCount / periodResponses.length) * 100;
        completionRateData.add({
          'period': key,
          'rate': completionRate,
        });
      }
      
      // Risk distribution data
      final riskLevels = <String, int>{
        'normal': 0,
        'elevated': 0,
        'high': 0,
        'veryHigh': 0,
        'critical': 0,
      };
      
      for (var response in periodResponses) {
        if (response.riskScore <= 20) {
          riskLevels['normal'] = riskLevels['normal']! + 1;
        } else if (response.riskScore <= 40) {
          riskLevels['elevated'] = riskLevels['elevated']! + 1;
        } else if (response.riskScore <= 60) {
          riskLevels['high'] = riskLevels['high']! + 1;
        } else if (response.riskScore <= 80) {
          riskLevels['veryHigh'] = riskLevels['veryHigh']! + 1;
        } else {
          riskLevels['critical'] = riskLevels['critical']! + 1;
        }
      }
      
      riskDistributionData.add({
        'period': key,
        'normal': riskLevels['normal']!,
        'elevated': riskLevels['elevated']!,
        'high': riskLevels['high']!,
        'veryHigh': riskLevels['veryHigh']!,
        'critical': riskLevels['critical']!,
      });
    }
    
    return {
      'userGrowth': userGrowthData,
      'completionRate': completionRateData,
      'riskDistribution': riskDistributionData,
    };
  }
  
  // Helper method to get start date for a given period
  DateTime _getStartDateForPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
      case 'weekly':
        // Start of the week (Monday)
        final daysSinceMonday = now.weekday - 1;
        return DateTime(now.year, now.month, now.day - daysSinceMonday);
      case 'monthly':
        return DateTime(now.year, now.month, 1);
      case 'yearly':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  // Update user account status
  Future<void> updateUserAccountStatus(String uid, String status) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'accountStatus': status,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user details by ID
  Future<UserProfile?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}