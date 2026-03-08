import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for fetching hospital data from the API
class HospitalApiService {
  // ============================================================
  // API BASE URL
  // ============================================================
  static const String _baseUrl = 'https://innovative-illumination-production-df84.up.railway.app';
  // ============================================================

  static final HospitalApiService _instance = HospitalApiService._internal();
  factory HospitalApiService() => _instance;
  HospitalApiService._internal();
  
  // Flag to control whether to use mock data or real API
  static bool useMockData = false; // Set to false to use real API

  /// Fetch active alerts
  /// Returns a list of alerts with level, message, and optional timestamp
  Future<List<Alert>> getAlerts() async {
    if (useMockData) return _getMockAlerts();
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/alerts'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both {alerts: [...]} and direct array response
        final alertsList = data is List ? data : (data['alerts'] as List? ?? []);
        return alertsList.map((a) => Alert.fromJson(a)).toList();
      }
      throw Exception('Failed to load alerts: ${response.statusCode}');
    } catch (e) {
      print('Error fetching alerts: $e');
      // Fallback to mock data on error
      return _getMockAlerts();
    }
  }

  /// Fetch maintenance activities
  /// Returns a list of maintenance items with type, location, status, and expected completion
  Future<List<Maintenance>> getMaintenance() async {
    if (useMockData) return _getMockMaintenance();
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/maintenance'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both {maintenance: [...]} and direct array response
        final maintenanceList = data is List ? data : (data['maintenance'] as List? ?? []);
        return maintenanceList.map((m) => Maintenance.fromJson(m)).toList();
      }
      throw Exception('Failed to load maintenance: ${response.statusCode}');
    } catch (e) {
      print('Error fetching maintenance: $e');
      // Fallback to mock data on error
      return _getMockMaintenance();
    }
  }

  /// Fetch ward status
  /// Returns a list of wards with current OP number, total beds, and occupied beds
  Future<List<WardStatus>> getWardsStatus() async {
    if (useMockData) return _getMockWardsStatus();
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wards/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both {wards: [...]} and direct array response
        final wardsList = data is List ? data : (data['wards'] as List? ?? []);
        return wardsList.map((w) => WardStatus.fromJson(w)).toList();
      }
      throw Exception('Failed to load wards status: ${response.statusCode}');
    } catch (e) {
      print('Error fetching wards status: $e');
      // Fallback to mock data on error
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
