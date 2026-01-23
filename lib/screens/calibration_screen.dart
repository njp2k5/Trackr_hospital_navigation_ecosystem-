import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hospital_nav_app/services/campus_routing_service.dart';

/// Light theme color palette
const Color _primaryColor = Color(0xFF2563EB);
const Color _backgroundColor = Color(0xFFF8FAFC);
const Color _surfaceColor = Colors.white;
const Color _cardBorderColor = Color(0xFFE2E8F0);
const Color _textPrimaryColor = Color(0xFF1E293B);
const Color _textSecondaryColor = Color(0xFF64748B);
const Color _accent4Color = Color(0xFF10B981);

/// Visual Calibration Tool for positioning destination markers
/// on the campus map. Allows dragging markers to align with
/// actual numbered positions on the floor plan image.
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  /// Mutable positions for each destination (normalized 0-1 coordinates)
  late Map<int, Offset> _positions;
  
  /// Mutable corridor snap points for each destination
  late Map<int, Offset> _snapPoints;
  
  /// Currently selected/dragging marker
  int? _selectedMarkerId;
  
  /// Whether editing position or snap point
  bool _editingSnapPoint = false;
  
  /// Image rect for coordinate conversion
  Rect _imageRect = Rect.zero;
  
  /// Original image size
  Size? _imageSize;
  
  /// Show snap points toggle
  bool _showSnapPoints = false;
  
  /// Show grid overlay
  bool _showGrid = false;

  @override
  void initState() {
    super.initState();
    _initializePositions();
  }

  void _initializePositions() {
    _positions = {};
    _snapPoints = {};
    
    for (final entry in CampusRoutingService.destinations.entries) {
      _positions[entry.key] = entry.value.position;
      _snapPoints[entry.key] = entry.value.corridorSnapPoint;
    }
  }

  void _resetPositions() {
    setState(() {
      _initializePositions();
      _selectedMarkerId = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Positions reset to defaults'),
        backgroundColor: _AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _exportCoordinates() {
    final buffer = StringBuffer();
    buffer.writeln('// Copy this into campus_routing_service.dart');
    buffer.writeln('static const Map<int, DestinationInfo> destinations = {');
    
    for (final entry in CampusRoutingService.destinations.entries) {
      final id = entry.key;
      final dest = entry.value;
      final pos = _positions[id]!;
      final snap = _snapPoints[id]!;
      
      buffer.writeln('  $id: DestinationInfo(');
      buffer.writeln('    id: $id,');
      buffer.writeln("    name: '${dest.name}',");
      buffer.writeln("    shortName: '${dest.shortName}',");
      buffer.writeln('    position: Offset(${pos.dx.toStringAsFixed(3)}, ${pos.dy.toStringAsFixed(3)}),');
      buffer.writeln('    corridorSnapPoint: Offset(${snap.dx.toStringAsFixed(3)}, ${snap.dy.toStringAsFixed(3)}),');
      buffer.writeln('  ),');
    }
    
    buffer.writeln('};');
    
    final code = buffer.toString();
    
    Clipboard.setData(ClipboardData(text: code));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Coordinates copied to clipboard!')),
          ],
        ),
        backgroundColor: _AppColors.accent4,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    
    // Also show in a dialog for manual copy
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exported Coordinates'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
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

  /// Convert screen position to normalized coordinates
  Offset _screenToNormalized(Offset screenPos) {
    if (_imageRect == Rect.zero) return Offset.zero;
    
    final normalizedX = (screenPos.dx - _imageRect.left) / _imageRect.width;
    final normalizedY = (screenPos.dy - _imageRect.top) / _imageRect.height;
    
    return Offset(
      normalizedX.clamp(0.0, 1.0),
      normalizedY.clamp(0.0, 1.0),
    );
  }

  /// Convert normalized coordinates to screen position
  Offset _normalizedToScreen(Offset normalized) {
    if (_imageRect == Rect.zero) return Offset.zero;
    
    return Offset(
      _imageRect.left + normalized.dx * _imageRect.width,
      _imageRect.top + normalized.dy * _imageRect.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildToolbar(),
            Expanded(child: _buildCalibrationArea()),
            _buildSelectedMarkerInfo(),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calibration Tool',
                  style: TextStyle(
                    color: _AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Drag markers to align with map',
                  style: TextStyle(
                    color: _AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _resetPositions,
            icon: const Icon(Icons.refresh, color: _AppColors.textSecondary),
            tooltip: 'Reset positions',
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _AppColors.surface,
      child: Row(
        children: [
          // Toggle: Edit position vs snap point
          ToggleButtons(
            isSelected: [!_editingSnapPoint, _editingSnapPoint],
            onPressed: (index) {
              setState(() {
                _editingSnapPoint = index == 1;
              });
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: _AppColors.primary,
            color: _AppColors.textSecondary,
            constraints: const BoxConstraints(minWidth: 80, minHeight: 36),
            children: const [
              Text('Position', style: TextStyle(fontSize: 12)),
              Text('Snap Point', style: TextStyle(fontSize: 12)),
            ],
          ),
          const Spacer(),
          // Show snap points toggle
          FilterChip(
            label: const Text('Snap Points', style: TextStyle(fontSize: 11)),
            selected: _showSnapPoints,
            onSelected: (v) => setState(() => _showSnapPoints = v),
            selectedColor: _AppColors.primary.withOpacity(0.2),
            checkmarkColor: _AppColors.primary,
          ),
          const SizedBox(width: 8),
          // Show grid toggle
          FilterChip(
            label: const Text('Grid', style: TextStyle(fontSize: 11)),
            selected: _showGrid,
            onSelected: (v) => setState(() => _showGrid = v),
            selectedColor: _AppColors.primary.withOpacity(0.2),
            checkmarkColor: _AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationArea() {
    return Container(
      margin: const EdgeInsets.all(12),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
            
            return _CalibrationMapView(
              containerSize: containerSize,
              positions: _positions,
              snapPoints: _snapPoints,
              selectedMarkerId: _selectedMarkerId,
              editingSnapPoint: _editingSnapPoint,
              showSnapPoints: _showSnapPoints,
              showGrid: _showGrid,
              onImageRectChanged: (rect, imageSize) {
                _imageRect = rect;
                _imageSize = imageSize;
              },
              onMarkerSelected: (id) {
                setState(() {
                  _selectedMarkerId = id;
                });
              },
              onMarkerMoved: (id, newNormalizedPos) {
                setState(() {
                  if (_editingSnapPoint) {
                    _snapPoints[id] = newNormalizedPos;
                  } else {
                    _positions[id] = newNormalizedPos;
                  }
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedMarkerInfo() {
    if (_selectedMarkerId == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _AppColors.cardBorder.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, color: _AppColors.textSecondary, size: 20),
            SizedBox(width: 8),
            Text(
              'Tap a marker to select, then drag to reposition',
              style: TextStyle(color: _AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final dest = CampusRoutingService.destinations[_selectedMarkerId]!;
    final pos = _positions[_selectedMarkerId]!;
    final snap = _snapPoints[_selectedMarkerId]!;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$_selectedMarkerId',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dest.shortName,
                      style: const TextStyle(
                        color: _AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      dest.name,
                      style: const TextStyle(
                        color: _AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _selectedMarkerId = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CoordinateDisplay(
                  label: 'Position',
                  offset: pos,
                  isActive: !_editingSnapPoint,
                  color: _AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CoordinateDisplay(
                  label: 'Snap Point',
                  offset: snap,
                  isActive: _editingSnapPoint,
                  color: _AppColors.accent4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetPositions,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _AppColors.textSecondary,
                side: const BorderSide(color: _AppColors.cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _exportCoordinates,
              icon: const Icon(Icons.content_copy, size: 18),
              label: const Text('Export Coordinates'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coordinate display widget
class _CoordinateDisplay extends StatelessWidget {
  final String label;
  final Offset offset;
  final bool isActive;
  final Color color;

  const _CoordinateDisplay({
    required this.label,
    required this.offset,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : _AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '(${offset.dx.toStringAsFixed(3)}, ${offset.dy.toStringAsFixed(3)})',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? _AppColors.textPrimary : _AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The map view with draggable markers
class _CalibrationMapView extends StatefulWidget {
  final Size containerSize;
  final Map<int, Offset> positions;
  final Map<int, Offset> snapPoints;
  final int? selectedMarkerId;
  final bool editingSnapPoint;
  final bool showSnapPoints;
  final bool showGrid;
  final void Function(Rect imageRect, Size? imageSize) onImageRectChanged;
  final void Function(int id) onMarkerSelected;
  final void Function(int id, Offset newNormalizedPos) onMarkerMoved;

  const _CalibrationMapView({
    required this.containerSize,
    required this.positions,
    required this.snapPoints,
    required this.selectedMarkerId,
    required this.editingSnapPoint,
    required this.showSnapPoints,
    required this.showGrid,
    required this.onImageRectChanged,
    required this.onMarkerSelected,
    required this.onMarkerMoved,
  });

  @override
  State<_CalibrationMapView> createState() => _CalibrationMapViewState();
}

class _CalibrationMapViewState extends State<_CalibrationMapView> {
  Size? _imageSize;
  Rect _imageRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    try {
      const imageProvider = AssetImage('assets/images/floor_plan.png');
      final completer = imageProvider.resolve(const ImageConfiguration());
      completer.addListener(ImageStreamListener((info, _) {
        if (mounted) {
          setState(() {
            _imageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
            _calculateImageRect();
          });
        }
      }));
    } catch (e) {
      // Use container size as fallback
      if (mounted) {
        setState(() {
          _imageSize = widget.containerSize;
          _imageRect = Rect.fromLTWH(0, 0, widget.containerSize.width, widget.containerSize.height);
          widget.onImageRectChanged(_imageRect, _imageSize);
        });
      }
    }
  }

  void _calculateImageRect() {
    if (_imageSize == null) return;

    final containerAspect = widget.containerSize.width / widget.containerSize.height;
    final imageAspect = _imageSize!.width / _imageSize!.height;

    double renderedWidth, renderedHeight;
    double offsetX, offsetY;

    if (imageAspect > containerAspect) {
      renderedWidth = widget.containerSize.width;
      renderedHeight = widget.containerSize.width / imageAspect;
      offsetX = 0;
      offsetY = (widget.containerSize.height - renderedHeight) / 2;
    } else {
      renderedHeight = widget.containerSize.height;
      renderedWidth = widget.containerSize.height * imageAspect;
      offsetX = (widget.containerSize.width - renderedWidth) / 2;
      offsetY = 0;
    }

    _imageRect = Rect.fromLTWH(offsetX, offsetY, renderedWidth, renderedHeight);
    widget.onImageRectChanged(_imageRect, _imageSize);
  }

  Offset _normalizedToScreen(Offset normalized) {
    return Offset(
      _imageRect.left + normalized.dx * _imageRect.width,
      _imageRect.top + normalized.dy * _imageRect.height,
    );
  }

  Offset _screenToNormalized(Offset screen) {
    final x = (screen.dx - _imageRect.left) / _imageRect.width;
    final y = (screen.dy - _imageRect.top) / _imageRect.height;
    return Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: Map Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/floor_plan.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFF1F5F9),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map, size: 64, color: Color(0xFF94A3B8)),
                      SizedBox(height: 16),
                      Text(
                        'Add floor_plan.png to\nassets/images/',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Layer 2: Grid overlay (optional)
        if (widget.showGrid && _imageRect != Rect.zero)
          Positioned.fill(
            child: CustomPaint(
              painter: _GridOverlayPainter(imageRect: _imageRect),
            ),
          ),

        // Layer 3: Snap point markers (optional)
        if (widget.showSnapPoints && _imageRect != Rect.zero)
          ...widget.snapPoints.entries.map((entry) {
            final screenPos = _normalizedToScreen(entry.value);
            return Positioned(
              left: screenPos.dx - 6,
              top: screenPos.dy - 6,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _AppColors.accent4.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            );
          }),

        // Layer 4: Lines connecting positions to snap points (when editing)
        if (widget.showSnapPoints && _imageRect != Rect.zero)
          Positioned.fill(
            child: CustomPaint(
              painter: _ConnectionLinesPainter(
                positions: widget.positions,
                snapPoints: widget.snapPoints,
                imageRect: _imageRect,
              ),
            ),
          ),

        // Layer 5: Draggable destination markers
        if (_imageRect != Rect.zero)
          ...widget.positions.entries.map((entry) {
            final id = entry.key;
            final normalizedPos = widget.editingSnapPoint 
                ? widget.snapPoints[id]! 
                : entry.value;
            final screenPos = _normalizedToScreen(normalizedPos);
            final isSelected = widget.selectedMarkerId == id;

            return Positioned(
              left: screenPos.dx - (isSelected ? 18 : 14),
              top: screenPos.dy - (isSelected ? 18 : 14),
              child: GestureDetector(
                onTap: () => widget.onMarkerSelected(id),
                onPanStart: (_) => widget.onMarkerSelected(id),
                onPanUpdate: (details) {
                  final newScreen = Offset(
                    screenPos.dx + details.delta.dx,
                    screenPos.dy + details.delta.dy,
                  );
                  final newNormalized = _screenToNormalized(newScreen);
                  widget.onMarkerMoved(id, newNormalized);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: isSelected ? 36 : 28,
                  height: isSelected ? 36 : 28,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (widget.editingSnapPoint ? _AppColors.accent4 : _AppColors.primary)
                        : _AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? Colors.white
                          : (widget.editingSnapPoint ? _AppColors.accent4 : _AppColors.primary),
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected 
                            ? _AppColors.primary.withOpacity(0.4)
                            : Colors.black.withOpacity(0.2),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$id',
                      style: TextStyle(
                        color: isSelected ? Colors.white : _AppColors.primary,
                        fontSize: isSelected ? 14 : 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

        // Layer 6: Instructions overlay
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: widget.editingSnapPoint 
                        ? _AppColors.accent4 
                        : _AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.editingSnapPoint ? Icons.adjust : Icons.location_on,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.editingSnapPoint
                        ? 'Editing Snap Points (corridor connections)'
                        : 'Editing Positions (marker locations)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Grid overlay painter
class _GridOverlayPainter extends CustomPainter {
  final Rect imageRect;

  _GridOverlayPainter({required this.imageRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw 10x10 grid
    const divisions = 10;
    final stepX = imageRect.width / divisions;
    final stepY = imageRect.height / divisions;

    for (int i = 0; i <= divisions; i++) {
      // Vertical lines
      final x = imageRect.left + i * stepX;
      canvas.drawLine(
        Offset(x, imageRect.top),
        Offset(x, imageRect.bottom),
        paint,
      );

      // Horizontal lines
      final y = imageRect.top + i * stepY;
      canvas.drawLine(
        Offset(imageRect.left, y),
        Offset(imageRect.right, y),
        paint,
      );
    }

    // Draw coordinate labels
    final textPaint = Paint()..color = Colors.blue.withOpacity(0.5);
    for (int i = 0; i <= divisions; i++) {
      final value = (i / divisions).toStringAsFixed(1);
      
      // X labels
      final xLabelPainter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(color: textPaint.color, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      );
      xLabelPainter.layout();
      xLabelPainter.paint(
        canvas,
        Offset(imageRect.left + i * stepX - xLabelPainter.width / 2, imageRect.bottom + 2),
      );

      // Y labels
      final yLabelPainter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(color: textPaint.color, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      );
      yLabelPainter.layout();
      yLabelPainter.paint(
        canvas,
        Offset(imageRect.left - yLabelPainter.width - 4, imageRect.top + i * stepY - yLabelPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridOverlayPainter oldDelegate) {
    return oldDelegate.imageRect != imageRect;
  }
}

/// Painter for lines connecting positions to snap points
class _ConnectionLinesPainter extends CustomPainter {
  final Map<int, Offset> positions;
  final Map<int, Offset> snapPoints;
  final Rect imageRect;

  _ConnectionLinesPainter({
    required this.positions,
    required this.snapPoints,
    required this.imageRect,
  });

  Offset _normalizedToScreen(Offset normalized) {
    return Offset(
      imageRect.left + normalized.dx * imageRect.width,
      imageRect.top + normalized.dy * imageRect.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _AppColors.accent4.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (final entry in positions.entries) {
      final id = entry.key;
      final posScreen = _normalizedToScreen(entry.value);
      final snapScreen = _normalizedToScreen(snapPoints[id]!);

      canvas.drawLine(posScreen, snapScreen, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionLinesPainter oldDelegate) => true;
}
