import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for fetching hospital data from the API
class HospitalApiService {
  static const String _baseUrl = 'http://your-api-url.com'; // TODO: Replace with actual API URL

  static final HospitalApiService _instance = HospitalApiService._internal();
  factory HospitalApiService() => _instance;
  HospitalApiService._internal();

  /// Fetch active alerts
  /// Returns a list of alerts with level, message, and optional timestamp
  Future<List<Alert>> getAlerts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/alerts'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final alerts = (data['alerts'] as List?)
            ?.map((a) => Alert.fromJson(a))
            .toList() ?? [];
        return alerts;
      }
      throw Exception('Failed to load alerts: ${response.statusCode}');
    } catch (e) {
      // For demo purposes, return mock data when API is unavailable
      return _getMockAlerts();
    }
  }

  /// Fetch maintenance activities
  /// Returns a list of maintenance items with type, location, status, and expected completion
  Future<List<Maintenance>> getMaintenance() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/maintenance'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final maintenance = (data['maintenance'] as List?)
            ?.map((m) => Maintenance.fromJson(m))
            .toList() ?? [];
        return maintenance;
      }
      throw Exception('Failed to load maintenance: ${response.statusCode}');
    } catch (e) {
      // For demo purposes, return mock data when API is unavailable
      return _getMockMaintenance();
    }
  }

  /// Fetch ward status
  /// Returns a list of wards with current OP number, total beds, and occupied beds
  Future<List<WardStatus>> getWardsStatus() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/wards/status'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final wards = (data['wards'] as List?)
            ?.map((w) => WardStatus.fromJson(w))
            .toList() ?? [];
        return wards;
      }
      throw Exception('Failed to load wards status: ${response.statusCode}');
    } catch (e) {
      // For demo purposes, return mock data when API is unavailable
      return _getMockWardsStatus();
    }
  }

  /// Monitor ward OP number and notify when user's OP is called
  /// Returns a stream that emits true when the user's OP number is reached
  Stream<int> monitorWardOP(String wardId) async* {
    while (true) {
      try {
        final wards = await getWardsStatus();
        final ward = wards.firstWhere(
          (w) => w.wardId == wardId,
          orElse: () => WardStatus(wardId: wardId, currentOpNumber: 0, totalBeds: 0, occupiedBeds: 0),
        );
        yield ward.currentOpNumber;
      } catch (e) {
        // In case of error, yield -1 to indicate issue
        yield -1;
      }
      // Poll every 30 seconds
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  // Mock data for demo/offline mode
  List<Alert> _getMockAlerts() {
    return [
      Alert(
        level: 'critical',
        message: 'Emergency ward operating at full capacity',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Alert(
        level: 'warning',
        message: 'Long wait times expected in OPD today',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Alert(
        level: 'info',
        message: 'Free health checkup camp this weekend',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }

  List<Maintenance> _getMockMaintenance() {
    return [
      Maintenance(
        type: 'lift',
        location: 'Block A - Lift 2',
        status: 'Under repair',
        expectedCompletion: DateTime.now().add(const Duration(hours: 2)),
      ),
      Maintenance(
        type: 'cleaning',
        location: 'Ground Floor Corridor',
        status: 'In progress',
        expectedCompletion: DateTime.now().add(const Duration(minutes: 45)),
      ),
      Maintenance(
        type: 'equipment',
        location: 'Radiology Department',
        status: 'Scheduled',
        expectedCompletion: null,
      ),
    ];
  }

  List<WardStatus> _getMockWardsStatus() {
    return [
      WardStatus(wardId: 'ER', currentOpNumber: 47, totalBeds: 50, occupiedBeds: 52),
      WardStatus(wardId: 'CASUALTY', currentOpNumber: 20, totalBeds: 20, occupiedBeds: 18),
      WardStatus(wardId: 'GENERAL', currentOpNumber: 85, totalBeds: 100, occupiedBeds: 72),
      WardStatus(wardId: 'PEDIATRIC', currentOpNumber: 31, totalBeds: 30, occupiedBeds: 21),
      WardStatus(wardId: 'MATERNITY', currentOpNumber: 20, totalBeds: 25, occupiedBeds: 19),
      WardStatus(wardId: 'SURGERY', currentOpNumber: 15, totalBeds: 15, occupiedBeds: 14),
      WardStatus(wardId: 'CARDIOLOGY', currentOpNumber: 37, totalBeds: 35, occupiedBeds: 28),
    ];
  }
}

/// Alert model
class Alert {
  final String level; // "critical", "warning", "info"
  final String message;
  final DateTime? timestamp;

  Alert({
    required this.level,
    required this.message,
    this.timestamp,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      level: json['level'] ?? 'info',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp']) 
          : null,
    );
  }
}

/// Maintenance model
class Maintenance {
  final String type; // e.g., "lift", "cleaning"
  final String location;
  final String status;
  final DateTime? expectedCompletion;

  Maintenance({
    required this.type,
    required this.location,
    required this.status,
    this.expectedCompletion,
  });

  factory Maintenance.fromJson(Map<String, dynamic> json) {
    return Maintenance(
      type: json['type'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? '',
      expectedCompletion: json['expected_completion'] != null 
          ? DateTime.tryParse(json['expected_completion']) 
          : null,
    );
  }
}

/// Ward status model
class WardStatus {
  final String wardId;
  final int currentOpNumber;
  final int totalBeds;
  final int occupiedBeds;

  WardStatus({
    required this.wardId,
    required this.currentOpNumber,
    required this.totalBeds,
    required this.occupiedBeds,
  });

  factory WardStatus.fromJson(Map<String, dynamic> json) {
    return WardStatus(
      wardId: json['ward_id'] ?? '',
      currentOpNumber: json['current_op_number'] ?? 0,
      totalBeds: json['total_beds'] ?? 0,
      occupiedBeds: json['occupied_beds'] ?? 0,
    );
  }
}
