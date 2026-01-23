import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hospital_nav_app/services/campus_routing_service.dart';

// Light theme color palette
class _AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF0891B2);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color accent1 = Color(0xFFEF4444);
  static const Color accent4 = Color(0xFF10B981);
  static const Color routeColor = Color(0xFF2563EB);
}

class RouteDisplayScreen extends StatefulWidget {
  final String currentLocation;
  final String destination;
  final bool isWheelchairFriendly;

  const RouteDisplayScreen({
    super.key,
    required this.currentLocation,
    required this.destination,
    this.isWheelchairFriendly = false,
  });

  @override
  State<RouteDisplayScreen> createState() => _RouteDisplayScreenState();
}

class _RouteDisplayScreenState extends State<RouteDisplayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  final CampusRoutingService _routingService = CampusRoutingService();
  late List<Offset> _routePoints;
  late List<DestinationMarker> _destinationMarkers;
  bool _showCorridors = false; // Debug: show corridor network
  
  // Zoom and pan controls
  final TransformationController _transformationController = TransformationController();
  double _currentZoom = 1.0;
  
  // Calibration mode
  bool _isCalibrationMode = false;
  bool _isCalibrationLocked = false;
  Map<int, Offset> _calibratedPositions = {};
  int? _selectedMarkerId;

  @override
  void initState() {
    super.initState();
    
    // Initialize routing service
    _routingService.initialize();
    
    // Generate route using corridor-based pathfinding
    _routePoints = _routingService.findRoute(
      widget.currentLocation,
      widget.destination,
    );
    
    // Get destination markers for display
    _destinationMarkers = _routingService.getDestinationMarkers();
    
    // Initialize calibrated positions from current destinations
    _initializeCalibratedPositions();
    
    // Animation controller for route drawing
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
    
    // Listen to transformation changes
    _transformationController.addListener(_onTransformChanged);
  }

  void _initializeCalibratedPositions() {
    _calibratedPositions = {};
    for (final marker in _destinationMarkers) {
      _calibratedPositions[marker.id] = marker.position;
    }
  }

  void _onTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale != _currentZoom) {
      setState(() {
        _currentZoom = scale;
      });
    }
  }

  void _toggleCalibrationMode() {
    setState(() {
      _isCalibrationMode = !_isCalibrationMode;
      if (!_isCalibrationMode) {
        _selectedMarkerId = null;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isCalibrationMode ? Icons.tune : Icons.map,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(_isCalibrationMode 
                ? 'Calibration mode ON - drag markers to reposition' 
                : 'Calibration mode OFF'),
          ],
        ),
        backgroundColor: _isCalibrationMode ? _AppColors.accent1 : _AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggleCalibrationLock() {
    setState(() {
      _isCalibrationLocked = !_isCalibrationLocked;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isCalibrationLocked ? Icons.lock : Icons.lock_open,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(_isCalibrationLocked 
                ? 'Points locked - positions fixed' 
                : 'Points unlocked - drag to adjust'),
          ],
        ),
        backgroundColor: _isCalibrationLocked ? _AppColors.accent4 : _AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _exportCalibratedCoordinates() {
    final buffer = StringBuffer();
    buffer.writeln('// Calibrated coordinates - copy to campus_routing_service.dart');
    buffer.writeln('static const Map<int, DestinationInfo> destinations = {');
    
    for (final entry in CampusRoutingService.destinations.entries) {
      final id = entry.key;
      final dest = entry.value;
      final pos = _calibratedPositions[id] ?? dest.position;
      
      buffer.writeln('  $id: DestinationInfo(');
      buffer.writeln('    id: $id,');
      buffer.writeln("    name: '${dest.name}',");
      buffer.writeln("    shortName: '${dest.shortName}',");
      buffer.writeln('    position: Offset(${pos.dx.toStringAsFixed(3)}, ${pos.dy.toStringAsFixed(3)}),');
      buffer.writeln('    corridorSnapPoint: Offset(${dest.corridorSnapPoint.dx.toStringAsFixed(3)}, ${dest.corridorSnapPoint.dy.toStringAsFixed(3)}),');
      buffer.writeln('  ),');
    }
    
    buffer.writeln('};');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.code, color: _AppColors.primary),
            SizedBox(width: 8),
            Text('Calibrated Coordinates'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: SingleChildScrollView(
            child: SelectableText(
              buffer.toString(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.3).clamp(1.0, 5.0);
    _setZoom(newScale);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.3).clamp(1.0, 5.0);
    _setZoom(newScale);
  }

  void _setZoom(double scale) {
    // Get the center point of the current view
    final matrix = _transformationController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    
    // Calculate scale factor
    final scaleFactor = scale / currentScale;
    
    // Scale from center
    matrix.scale(scaleFactor);
    _transformationController.value = matrix;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildRouteInfoCard(),
            Expanded(
              child: _buildMapWithRoute(),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: _AppColors.surface,
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
            icon: const Icon(Icons.arrow_back_ios_new, color: _AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Campus Navigation',
                  style: TextStyle(
                    color: _AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.isWheelchairFriendly ? 'Accessible Route' : 'Walking Route',
                  style: TextStyle(
                    color: widget.isWheelchairFriendly ? _AppColors.primary : _AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Debug toggle for corridors
          IconButton(
            onPressed: () {
              setState(() {
                _showCorridors = !_showCorridors;
              });
            },
            icon: Icon(
              Icons.route,
              color: _showCorridors ? _AppColors.primary : _AppColors.textSecondary,
            ),
            tooltip: 'Show/Hide Corridors',
          ),
          IconButton(
            onPressed: () {
              _animationController.reset();
              _animationController.forward();
            },
            icon: const Icon(Icons.replay, color: _AppColors.primary),
            tooltip: 'Replay Animation',
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          // Source
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _AppColors.accent4.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location, color: _AppColors.accent4, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'From',
                  style: TextStyle(color: _AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.currentLocation,
                  style: const TextStyle(
                    color: _AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Arrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 30, height: 2, color: _AppColors.primary),
                      const Icon(Icons.arrow_forward, color: _AppColors.primary, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '~${_estimateWalkTime()} min',
                  style: TextStyle(
                    color: _AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Destination
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _AppColors.accent1.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag, color: _AppColors.accent1, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'To',
                  style: TextStyle(color: _AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.destination,
                  style: const TextStyle(
                    color: _AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _estimateWalkTime() {
    // Estimate based on route length (rough approximation)
    double totalDist = 0;
    for (int i = 1; i < _routePoints.length; i++) {
      totalDist += (_routePoints[i] - _routePoints[i - 1]).distance;
    }
    // Assume 0.1 normalized units ≈ 50 meters, walking speed ~5 km/h
    return max(1, (totalDist * 500 / 83).round()); // ~1 min per 83m
  }

  Widget _buildMapWithRoute() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Zoomable/pannable map (always enabled)
            LayoutBuilder(
              builder: (context, constraints) {
                final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
                
                return InteractiveViewer(
                  transformationController: _transformationController,
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 1.0,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(100),
                  child: _ImageAwareStack(
                    containerSize: containerSize,
                    imagePath: 'assets/images/floor_plan.png',
                    routePoints: _routePoints,
                    destinationMarkers: _destinationMarkers,
                    corridors: _routingService.getCorridorPolylines(),
                    showCorridors: _showCorridors,
                    animation: _animation,
                    buildDestinationNumber: _buildDestinationNumber,
                    buildYouAreHereMarker: _buildYouAreHereMarker,
                    buildDestinationFlag: _buildDestinationFlag,
                    buildLegend: _buildLegend,
                    isCalibrationMode: _isCalibrationMode,
                    isCalibrationLocked: _isCalibrationLocked,
                    calibratedPositions: _calibratedPositions,
                    selectedMarkerId: _selectedMarkerId,
                    onMarkerSelected: (id) {
                      if (_isCalibrationMode && !_isCalibrationLocked) {
                        setState(() => _selectedMarkerId = id);
                      }
                    },
                    onMarkerMoved: (id, newPosition) {
                      if (_isCalibrationMode && !_isCalibrationLocked) {
                        setState(() {
                          _calibratedPositions[id] = newPosition;
                        });
                      }
                    },
                  ),
                );
              },
            ),
            
            // Zoom controls overlay
            Positioned(
              right: 12,
              bottom: 12,
              child: _buildZoomControls(),
            ),
            
            // Zoom level indicator
            if (_currentZoom > 1.01)
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${(_currentZoom * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            
            // Calibration mode indicator
            if (_isCalibrationMode)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isCalibrationLocked ? _AppColors.accent4 : Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isCalibrationLocked ? Icons.lock : Icons.edit_location_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isCalibrationLocked ? 'Points Locked' : 'Drag Points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom in (always enabled)
          _ZoomControlButton(
            icon: Icons.add,
            onPressed: _zoomIn,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          Container(height: 1, width: 36, color: _AppColors.cardBorder),
          // Reset zoom
          _ZoomControlButton(
            icon: Icons.fit_screen,
            onPressed: _resetZoom,
            borderRadius: BorderRadius.zero,
          ),
          Container(height: 1, width: 36, color: _AppColors.cardBorder),
          // Zoom out (always enabled)
          _ZoomControlButton(
            icon: Icons.remove,
            onPressed: _zoomOut,
            borderRadius: BorderRadius.zero,
          ),
          Container(height: 1, width: 36, color: _AppColors.cardBorder),
          // Calibration mode toggle
          _ZoomControlButton(
            icon: _isCalibrationMode ? Icons.edit_off : Icons.edit_location_alt,
            onPressed: _toggleCalibrationMode,
            borderRadius: _isCalibrationMode ? BorderRadius.zero : const BorderRadius.vertical(bottom: Radius.circular(12)),
            isActive: _isCalibrationMode,
          ),
          // Lock/unlock calibration points (only in calibration mode)
          if (_isCalibrationMode) ...[
            Container(height: 1, width: 36, color: _AppColors.cardBorder),
            _ZoomControlButton(
              icon: _isCalibrationLocked ? Icons.lock : Icons.lock_open,
              onPressed: _toggleCalibrationLock,
              borderRadius: BorderRadius.zero,
              isActive: _isCalibrationLocked,
            ),
            Container(height: 1, width: 36, color: _AppColors.cardBorder),
            // Export calibrated coordinates
            _ZoomControlButton(
              icon: Icons.download,
              onPressed: _exportCalibratedCoordinates,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDestinationNumber(DestinationMarker marker) {
    return Tooltip(
      message: marker.name,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _AppColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            marker.label,
            style: const TextStyle(
              color: _AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYouAreHereMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _AppColors.accent4,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: _AppColors.accent4.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'You are here',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePainter(color: _AppColors.accent4),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: _AppColors.accent4,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: _AppColors.accent4.withOpacity(0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationFlag() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _AppColors.accent1,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _AppColors.accent1.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.flag, color: Colors.white, size: 16),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem(
            Container(width: 16, height: 3, decoration: BoxDecoration(
              color: _AppColors.routeColor,
              borderRadius: BorderRadius.circular(2),
            )),
            'Your Route',
          ),
          const SizedBox(height: 4),
          _legendItem(
            Container(width: 10, height: 10, decoration: const BoxDecoration(
              color: _AppColors.accent4,
              shape: BoxShape.circle,
            )),
            'Start',
          ),
          const SizedBox(height: 4),
          _legendItem(
            Container(width: 10, height: 10, decoration: const BoxDecoration(
              color: _AppColors.accent1,
              shape: BoxShape.circle,
            )),
            'Destination',
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Widget icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 9, color: _AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: _AppColors.cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Route sharing coming soon!'),
                    backgroundColor: _AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              icon: const Icon(Icons.share, color: _AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Turn-by-turn navigation coming soon!'),
                      backgroundColor: _AppColors.accent4,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_AppColors.primary, _AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Start Navigation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Zoom control button widget
class _ZoomControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final BorderRadius borderRadius;
  final bool isActive;

  const _ZoomControlButton({
    required this.icon,
    required this.onPressed,
    required this.borderRadius,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);
    const accent4Color = Color(0xFF10B981);
    const textSecondary = Color(0xFF64748B);
    
    final isEnabled = onPressed != null;
    final buttonColor = isActive 
        ? accent4Color 
        : (isEnabled ? primaryColor : textSecondary.withOpacity(0.5));
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: isActive ? accent4Color.withOpacity(0.1) : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: buttonColor,
          ),
        ),
      ),
    );
  }
}

/// Widget that properly positions markers relative to the actual rendered image size.
/// This ensures normalized (0-1) coordinates align with visible map locations
/// regardless of container size or aspect ratio.
class _ImageAwareStack extends StatefulWidget {
  final Size containerSize;
  final String imagePath;
  final List<Offset> routePoints;
  final List<DestinationMarker> destinationMarkers;
  final List<List<Offset>> corridors;
  final bool showCorridors;
  final Animation<double> animation;
  final Widget Function(DestinationMarker) buildDestinationNumber;
  final Widget Function() buildYouAreHereMarker;
  final Widget Function() buildDestinationFlag;
  final Widget Function() buildLegend;
  // Calibration properties
  final bool isCalibrationMode;
  final bool isCalibrationLocked;
  final Map<int, Offset> calibratedPositions;
  final int? selectedMarkerId;
  final void Function(int id)? onMarkerSelected;
  final void Function(int id, Offset newPosition)? onMarkerMoved;

  const _ImageAwareStack({
    required this.containerSize,
    required this.imagePath,
    required this.routePoints,
    required this.destinationMarkers,
    required this.corridors,
    required this.showCorridors,
    required this.animation,
    required this.buildDestinationNumber,
    required this.buildYouAreHereMarker,
    required this.buildDestinationFlag,
    required this.buildLegend,
    this.isCalibrationMode = false,
    this.isCalibrationLocked = true,
    this.calibratedPositions = const {},
    this.selectedMarkerId,
    this.onMarkerSelected,
    this.onMarkerMoved,
  });

  @override
  State<_ImageAwareStack> createState() => _ImageAwareStackState();
}

class _ImageAwareStackState extends State<_ImageAwareStack> {
  Size? _imageSize;
  Rect? _imageRect;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  @override
  void didUpdateWidget(covariant _ImageAwareStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate image rect if container size changed
    if (oldWidget.containerSize != widget.containerSize) {
      _calculateImageRect();
    }
  }

  Future<void> _loadImageSize() async {
    try {
      final imageProvider = AssetImage(widget.imagePath);
      final completer = imageProvider.resolve(const ImageConfiguration());
      completer.addListener(ImageStreamListener((info, _) {
        if (mounted) {
          setState(() {
            _imageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
            _calculateImageRect();
            _imageLoaded = true;
          });
        }
      }));
    } catch (e) {
      // Use container size as fallback
      if (mounted) {
        setState(() {
          _imageSize = widget.containerSize;
          _imageRect = Rect.fromLTWH(0, 0, widget.containerSize.width, widget.containerSize.height);
          _imageLoaded = true;
        });
      }
    }
  }

  void _calculateImageRect() {
    if (_imageSize == null) return;

    final containerWidth = widget.containerSize.width;
    final containerHeight = widget.containerSize.height;
    final imageWidth = _imageSize!.width;
    final imageHeight = _imageSize!.height;

    final containerAspect = containerWidth / containerHeight;
    final imageAspect = imageWidth / imageHeight;

    double renderedWidth, renderedHeight;
    double offsetX, offsetY;

    if (imageAspect > containerAspect) {
      // Image is wider than container - fit to width, letterbox top/bottom
      renderedWidth = containerWidth;
      renderedHeight = containerWidth / imageAspect;
      offsetX = 0;
      offsetY = (containerHeight - renderedHeight) / 2;
    } else {
      // Image is taller than container - fit to height, letterbox left/right
      renderedHeight = containerHeight;
      renderedWidth = containerHeight * imageAspect;
      offsetX = (containerWidth - renderedWidth) / 2;
      offsetY = 0;
    }

    _imageRect = Rect.fromLTWH(offsetX, offsetY, renderedWidth, renderedHeight);
  }

  /// Convert normalized (0-1) coordinates to screen position within the rendered image
  Offset _normalizedToScreen(Offset normalized) {
    if (_imageRect == null) {
      // Fallback: use container size (will be corrected once image loads)
      return Offset(
        normalized.dx * widget.containerSize.width,
        normalized.dy * widget.containerSize.height,
      );
    }
    // Convert normalized coords to position within the actual rendered image area
    return Offset(
      _imageRect!.left + normalized.dx * _imageRect!.width,
      _imageRect!.top + normalized.dy * _imageRect!.height,
    );
  }

  /// Convert screen position back to normalized (0-1) coordinates
  Offset _screenToNormalized(Offset screen) {
    if (_imageRect == null) {
      // Fallback: use container size
      return Offset(
        screen.dx / widget.containerSize.width,
        screen.dy / widget.containerSize.height,
      );
    }
    // Convert screen coords back to normalized coords relative to image area
    return Offset(
      (screen.dx - _imageRect!.left) / _imageRect!.width,
      (screen.dy - _imageRect!.top) / _imageRect!.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: Map Image (bottom)
        Positioned.fill(
          child: Image.asset(
            widget.imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return CustomPaint(
                size: widget.containerSize,
                painter: _PlaceholderMapPainter(),
              );
            },
          ),
        ),

        // Layer 2: Corridor network (debug, optional)
        if (widget.showCorridors && _imageRect != null)
          Positioned.fill(
            child: CustomPaint(
              size: widget.containerSize,
              painter: _CorridorNetworkPainter(
                corridors: widget.corridors,
                imageRect: _imageRect!,
              ),
            ),
          ),

        // Layer 3: Animated Route Overlay
        if (_imageRect != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: widget.animation,
              builder: (context, child) {
                return CustomPaint(
                  size: widget.containerSize,
                  painter: _RoutePathPainter(
                    routePoints: widget.routePoints,
                    progress: widget.animation.value,
                    imageRect: _imageRect!,
                  ),
                );
              },
            ),
          ),

        // Layer 4: Destination Numbers (always visible above route)
        // In calibration mode, use calibratedPositions and make them draggable
        if (_imageLoaded && _imageRect != null)
          ...widget.destinationMarkers.map((marker) {
            // Use calibrated position if available, otherwise use original
            final position = widget.isCalibrationMode && widget.calibratedPositions.containsKey(marker.id)
                ? widget.calibratedPositions[marker.id]!
                : marker.position;
            final screenPos = _normalizedToScreen(position);
            final isSelected = widget.isCalibrationMode && widget.selectedMarkerId == marker.id;
            
            // Draggable in calibration mode when not locked
            if (widget.isCalibrationMode && !widget.isCalibrationLocked) {
              return Positioned(
                left: screenPos.dx - 12,
                top: screenPos.dy - 12,
                child: GestureDetector(
                  onTap: () => widget.onMarkerSelected?.call(marker.id),
                  onPanStart: (_) => widget.onMarkerSelected?.call(marker.id),
                  onPanUpdate: (details) {
                    // Calculate new screen position
                    final newScreenPos = Offset(
                      screenPos.dx + details.delta.dx,
                      screenPos.dy + details.delta.dy,
                    );
                    // Convert back to normalized and notify parent
                    final newNormalized = _screenToNormalized(newScreenPos);
                    widget.onMarkerMoved?.call(marker.id, newNormalized);
                  },
                  child: Container(
                    decoration: isSelected
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          )
                        : null,
                    child: widget.buildDestinationNumber(marker),
                  ),
                ),
              );
            }
            
            // Not in calibration mode or locked - static markers
            return Positioned(
              left: screenPos.dx - 12,
              top: screenPos.dy - 12,
              child: widget.buildDestinationNumber(marker),
            );
          }),

        // Layer 5: You Are Here marker
        if (_imageLoaded && _imageRect != null && widget.routePoints.isNotEmpty)
          Builder(builder: (context) {
            final screenPos = _normalizedToScreen(widget.routePoints.first);
            return Positioned(
              left: screenPos.dx - 45,
              top: screenPos.dy - 55,
              child: widget.buildYouAreHereMarker(),
            );
          }),

        // Layer 6: Destination flag marker
        if (_imageLoaded && _imageRect != null && widget.routePoints.isNotEmpty)
          Builder(builder: (context) {
            final screenPos = _normalizedToScreen(widget.routePoints.last);
            return Positioned(
              left: screenPos.dx - 12,
              top: screenPos.dy - 30,
              child: widget.buildDestinationFlag(),
            );
          }),

        // Layer 7: Legend
        Positioned(
          left: 10,
          bottom: 10,
          child: widget.buildLegend(),
        ),
      ],
    );
  }
}

/// CustomPainter for animated route path using PathMetrics.
/// Routes are drawn as thin, semi-transparent polylines with rounded caps/joins.
/// Coordinates are normalized (0-1) relative to the original image.
class _RoutePathPainter extends CustomPainter {
  final List<Offset> routePoints;
  final double progress;
  final Rect imageRect;

  _RoutePathPainter({
    required this.routePoints,
    required this.progress,
    required this.imageRect,
  });

  /// Convert normalized (0-1) coordinate to screen position within imageRect
  Offset _normalizedToScreen(Offset normalized) {
    return Offset(
      imageRect.left + normalized.dx * imageRect.width,
      imageRect.top + normalized.dy * imageRect.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.length < 2 || progress <= 0) return;

    // Scale points to image rect (not full canvas)
    final scaledPoints = routePoints.map((p) => _normalizedToScreen(p)).toList();

    // Create path through all points
    final path = Path();
    path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
    
    for (int i = 1; i < scaledPoints.length; i++) {
      path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
    }

    // Get path metrics for animation
    final pathMetrics = path.computeMetrics();

    // Glow/shadow effect
    final glowPaint = Paint()
      ..color = const Color(0xFF2563EB).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Main route line
    final routePaint = Paint()
      ..color = const Color(0xFF2563EB).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw animated path
    for (final metric in pathMetrics) {
      final extractLength = metric.length * progress;
      final extractedPath = metric.extractPath(0, extractLength);
      
      canvas.drawPath(extractedPath, glowPaint);
      canvas.drawPath(extractedPath, routePaint);
    }

    // Draw direction dots along the path
    if (progress > 0.2) {
      _drawDirectionDots(canvas, path, progress);
    }
  }

  void _drawDirectionDots(Canvas canvas, Path path, double progress) {
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;

    final metric = pathMetrics.first;
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw dots at intervals
    final dotCount = 4;
    final animatedLength = metric.length * progress;
    
    for (int i = 1; i <= dotCount; i++) {
      final position = (animatedLength * i) / (dotCount + 1);
      if (position <= 0 || position >= animatedLength) continue;

      final tangent = metric.getTangentForOffset(position);
      if (tangent == null) continue;

      canvas.drawCircle(tangent.position, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePathPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.routePoints != routePoints ||
        oldDelegate.imageRect != imageRect;
  }
}

/// CustomPainter for corridor network (debug visualization).
/// Shows all walkable paths on the campus map.
class _CorridorNetworkPainter extends CustomPainter {
  final List<List<Offset>> corridors;
  final Rect imageRect;

  _CorridorNetworkPainter({
    required this.corridors,
    required this.imageRect,
  });

  /// Convert normalized (0-1) coordinate to screen position within imageRect
  Offset _normalizedToScreen(Offset normalized) {
    return Offset(
      imageRect.left + normalized.dx * imageRect.width,
      imageRect.top + normalized.dy * imageRect.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final corridor in corridors) {
      if (corridor.length < 2) continue;
      
      final startPoint = _normalizedToScreen(corridor.first);
      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);
      
      for (int i = 1; i < corridor.length; i++) {
        final point = _normalizedToScreen(corridor[i]);
        path.lineTo(point.dx, point.dy);
      }
      
      canvas.drawPath(path, paint);
    }

    // Draw nodes
    final nodePaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (final corridor in corridors) {
      for (final point in corridor) {
        final screenPos = _normalizedToScreen(point);
        canvas.drawCircle(screenPos, 3, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CorridorNetworkPainter oldDelegate) {
    return oldDelegate.imageRect != imageRect;
  }
}

/// Placeholder map painter when image is not available
class _PlaceholderMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF1F5F9),
    );

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gridSize = 25.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // "Campus Map" text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Campus Map\n(Add floor_plan.png)',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height / 2 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Triangle painter for markers
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}
