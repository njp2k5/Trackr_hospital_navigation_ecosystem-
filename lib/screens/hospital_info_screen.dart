import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hospital_nav_app/services/hospital_api_service.dart';
import 'package:hospital_nav_app/services/notification_service.dart';

// Light theme color palette
class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF0891B2);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color critical = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF97316);
  static const Color info = Color(0xFF3B82F6);
  static const Color success = Color(0xFF10B981);
}

class HospitalInfoScreen extends StatefulWidget {
  const HospitalInfoScreen({super.key, required this.hospitalName});

  final String hospitalName;

  @override
  State<HospitalInfoScreen> createState() => _HospitalInfoScreenState();
}

class _HospitalInfoScreenState extends State<HospitalInfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HospitalApiService _apiService = HospitalApiService();
  final NotificationService _notificationService = NotificationService();

  List<Alert> _alerts = [];
  List<Maintenance> _maintenanceItems = [];
  List<WardStatus> _wards = [];
  bool _isLoading = true;
  String? _error;

  // OP Notification state
  String? _selectedWard;
  int? _userOpNumber;
  StreamSubscription<int>? _opMonitorSubscription;
  bool _isMonitoring = false;
  int _currentOpNumber = 0;
  int _lastNotifiedPosition = -1; // Track when we last sent an approaching notification

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _opMonitorSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getAlerts(),
        _apiService.getMaintenance(),
        _apiService.getWardsStatus(),
      ]);

      setState(() {
        _alerts = results[0] as List<Alert>;
        _maintenanceItems = results[1] as List<Maintenance>;
        _wards = results[2] as List<WardStatus>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _startMonitoringOP() {
    if (_selectedWard == null || _userOpNumber == null) return;

    _opMonitorSubscription?.cancel();
    
    setState(() {
      _isMonitoring = true;
      _lastNotifiedPosition = -1;
    });

    _opMonitorSubscription = _apiService.monitorWardOP(_selectedWard!).listen(
      (currentOp) {
        setState(() {
          _currentOpNumber = currentOp;
        });

        final positionsAway = _userOpNumber! - currentOp;

        // Send approaching notification when 3 positions away
        if (positionsAway <= 3 && positionsAway > 0 && _lastNotifiedPosition != positionsAway) {
          _lastNotifiedPosition = positionsAway;
          _notificationService.showApproachingNotification(
            currentOp: currentOp,
            userOp: _userOpNumber!,
            wardName: _selectedWard!,
            positionsAway: positionsAway,
          );
        }

        // Send main notification when it's user's turn
        if (currentOp >= _userOpNumber! && currentOp != -1) {
          _showOpNotification();
        }
      },
      onError: (e) {
        _showErrorSnackBar('Error monitoring OP number');
      },
    );

    _showSuccessSnackBar('Monitoring started for OP #$_userOpNumber in $_selectedWard');
  }

  void _stopMonitoringOP() {
    _opMonitorSubscription?.cancel();
    setState(() {
      _isMonitoring = false;
      _currentOpNumber = 0;
      _lastNotifiedPosition = -1;
    });
    _notificationService.cancelAllNotifications();
    _showSuccessSnackBar('Monitoring stopped');
  }

  void _showOpNotification() {
    // Show system notification (works when screen is off)
    _notificationService.showOpNotification(
      opNumber: _userOpNumber!,
      wardName: _selectedWard!,
    );

    // Also show in-app dialog if app is in foreground
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            const Text('Your Turn!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your OP number $_userOpNumber has been called in $_selectedWard ward.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Please proceed to the counter.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _stopMonitoringOP();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.critical,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? _buildErrorView()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAlertsTab(),
                            _buildMaintenanceTab(),
                            _buildOpNotificationTab(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hospital Information',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.hospitalName,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.warning_amber_rounded), text: 'Alerts'),
          Tab(icon: Icon(Icons.construction), text: 'Maintenance'),
          Tab(icon: Icon(Icons.confirmation_number), text: 'OP Tracker'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.critical.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    if (_alerts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Active Alerts',
        subtitle: 'Everything is running smoothly',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        itemCount: _alerts.length,
        itemBuilder: (context, index) => _AlertCard(alert: _alerts[index]),
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    if (_maintenanceItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.build_circle_outlined,
        title: 'No Maintenance Activities',
        subtitle: 'All facilities are operational',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        itemCount: _maintenanceItems.length,
        itemBuilder: (context, index) => _MaintenanceCard(maintenance: _maintenanceItems[index]),
      ),
    );
  }

  Widget _buildOpNotificationTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OP Number Tracker',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get notified when your turn arrives',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Ward selection
          const Text(
            'Select Ward',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedWard,
                hint: const Text('Choose a ward'),
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                items: _wards.map((ward) {
                  return DropdownMenuItem(
                    value: ward.wardId,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ward.wardId),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Current: ${ward.currentOpNumber}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _isMonitoring ? null : (value) {
                  setState(() {
                    _selectedWard = value;
                    // Set current OP number for selected ward
                    final ward = _wards.firstWhere((w) => w.wardId == value);
                    _currentOpNumber = ward.currentOpNumber;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // OP Number input
          const Text(
            'Your OP Number',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            enabled: !_isMonitoring,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter your OP number',
              prefixIcon: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _userOpNumber = int.tryParse(value);
              });
            },
          ),
          const SizedBox(height: 24),

          // Status card when monitoring
          if (_isMonitoring && _selectedWard != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Monitoring Active',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatusItem(
                        label: 'Current OP',
                        value: _currentOpNumber.toString(),
                        color: AppColors.primary,
                      ),
                      _StatusItem(
                        label: 'Your OP',
                        value: _userOpNumber.toString(),
                        color: AppColors.success,
                      ),
                      _StatusItem(
                        label: 'Position',
                        value: '${(_userOpNumber! - _currentOpNumber).clamp(0, 999)}',
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_selectedWard != null && _userOpNumber != null)
                  ? (_isMonitoring ? _stopMonitoringOP : _startMonitoringOP)
                  : null,
              icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
              label: Text(_isMonitoring ? 'Stop Monitoring' : 'Start Monitoring'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMonitoring ? AppColors.critical : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Ward status cards
          const Text(
            'Current Ward Status',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._wards.map((ward) => _WardStatusCard(ward: ward)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.success),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final Alert alert;

  Color get _levelColor {
    switch (alert.level) {
      case 'critical':
        return AppColors.critical;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  IconData get _levelIcon {
    switch (alert.level) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _levelColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _levelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_levelIcon, color: _levelColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _levelColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.level.toUpperCase(),
                        style: TextStyle(
                          color: _levelColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (alert.timestamp != null)
                      Text(
                        _formatTimestamp(alert.timestamp!),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  alert.message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({required this.maintenance});

  final Maintenance maintenance;

  IconData get _typeIcon {
    switch (maintenance.type.toLowerCase()) {
      case 'lift':
        return Icons.elevator;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'equipment':
        return Icons.medical_services;
      default:
        return Icons.construction;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon, color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      maintenance.type.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        maintenance.status,
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      maintenance.location,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (maintenance.expectedCompletion != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Expected: ${_formatCompletion(maintenance.expectedCompletion!)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompletion(DateTime completion) {
    final diff = completion.difference(DateTime.now());
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    } else {
      return '${diff.inDays} days';
    }
  }
}

class _WardStatusCard extends StatelessWidget {
  const _WardStatusCard({required this.ward});

  final WardStatus ward;

  @override
  Widget build(BuildContext context) {
    final occupancyPercent = (ward.occupiedBeds / ward.totalBeds * 100).clamp(0, 100);
    final occupancyColor = occupancyPercent > 90 
        ? AppColors.critical 
        : occupancyPercent > 70 
            ? AppColors.warning 
            : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                ward.wardId.substring(0, ward.wardId.length.clamp(0, 2)),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ward.wardId,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'OP: ${ward.currentOpNumber}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Beds: ${ward.occupiedBeds}/${ward.totalBeds}',
                      style: TextStyle(
                        color: occupancyColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: occupancyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${occupancyPercent.toInt()}%',
              style: TextStyle(
                color: occupancyColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
