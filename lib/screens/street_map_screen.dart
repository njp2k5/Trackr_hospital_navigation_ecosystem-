import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:math' as math;

/// Street-View-like video navigation using timestamp-based nodes.
/// Uses a single video asset with virtual locations defined by timestamps.
/// Navigation arrows allow moving between nodes by seeking to timestamps.
class StreetMapScreen extends StatefulWidget {
  const StreetMapScreen({super.key});

  @override
  State<StreetMapScreen> createState() => _StreetMapScreenState();
}

class _StreetMapScreenState extends State<StreetMapScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  String _errorMessage = '';

  // Current node index
  int _currentNodeIndex = 0;

  // Timer to check when segment ends
  Timer? _segmentTimer;

  /// Define virtual locations as timestamp nodes in the video.
  /// Each node has:
  /// - id: unique identifier
  /// - name: location name to display
  /// - timestamp: position in video (milliseconds)
  /// - connections: map of direction to node index
  ///   Directions are forward, back, left, right
  ///
  /// Updated timestamps for new longer video:
  /// Main Gate - 00:00.00
  /// Student Parking Area - 02:09.88
  /// Parking Area - 02:14.92
  /// Pond - 04:39.94
  /// Workshop Block - 05:23.62
  /// Badminton Court - 06:25.77
  /// Kuppi Veedu - 07:33.52
  /// Canteen - 08:10.48
  static const List<VideoNode> _nodes = [
    VideoNode(
      id: 0,
      name: 'Main Gate',
      timestamp: Duration(milliseconds: 0),
      connections: {'forward': 1},
    ),
    VideoNode(
      id: 1,
      name: 'Student Parking Area',
      timestamp: Duration(milliseconds: 129880), // 02:09.88
      connections: {'forward': 2, 'back': 0},
    ),
    VideoNode(
      id: 2,
      name: 'Parking Area',
      timestamp: Duration(milliseconds: 134920), // 02:14.92
      connections: {'forward': 3, 'back': 1},
    ),
    VideoNode(
      id: 3,
      name: 'Pond',
      timestamp: Duration(milliseconds: 279940), // 04:39.94
      connections: {'forward': 4, 'back': 2},
    ),
    VideoNode(
      id: 4,
      name: 'Workshop Block',
      timestamp: Duration(milliseconds: 323620), // 05:23.62
      connections: {'forward': 5, 'back': 3},
    ),
    VideoNode(
      id: 5,
      name: 'Badminton Court',
      timestamp: Duration(milliseconds: 385770), // 06:25.77
      connections: {'forward': 6, 'back': 4},
    ),
    VideoNode(
      id: 6,
      name: 'Kuppi Veedu',
      timestamp: Duration(milliseconds: 453520), // 07:33.52
      connections: {'forward': 7, 'back': 5},
    ),
    VideoNode(
      id: 7,
      name: 'Canteen',
      timestamp: Duration(milliseconds: 490480), // 08:10.48
      connections: {'back': 6},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    // Lock to portrait for street view
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _initializeVideo() async {
    try {
      // Initialize video player with local asset
      _controller = VideoPlayerController.asset(
        'assets/videos/campus_tour.mp4',
      );

      await _controller!.initialize();

      // Start at first node
      await _controller!.seekTo(_nodes[0].timestamp);
      await _controller!.pause();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load video: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _segmentTimer?.cancel();
    _controller?.dispose();
    // Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  /// Navigate to a new node by seeking and playing a short segment
  Future<void> _navigateToNode(int targetNodeIndex) async {
    if (_controller == null || !_isInitialized) return;
    if (_isPlaying) return; // Prevent navigation while moving
    if (targetNodeIndex < 0 || targetNodeIndex >= _nodes.length) return;

    setState(() {
      _isPlaying = true;
    });

    final targetNode = _nodes[targetNodeIndex];
    final currentNode = _nodes[_currentNodeIndex];

    // Calculate segment duration (time between current and target)
    final segmentDuration = (targetNode.timestamp - currentNode.timestamp)
        .abs();

    // Determine if we're going forward or backward in video
    final isForward = targetNode.timestamp > currentNode.timestamp;

    if (isForward) {
      // Play forward from current position to target
      await _controller!.seekTo(currentNode.timestamp);
      await _controller!.play();

      // Set timer to pause at target node
      _segmentTimer?.cancel();
      _segmentTimer = Timer(
        segmentDuration + const Duration(milliseconds: 100),
        () async {
          await _controller!.pause();
          await _controller!.seekTo(targetNode.timestamp);
          if (mounted) {
            setState(() {
              _currentNodeIndex = targetNodeIndex;
              _isPlaying = false;
            });
          }
        },
      );
    } else {
      // For backward movement, just seek directly (can't play video backward)
      // Create illusion with quick transition
      await _controller!.seekTo(targetNode.timestamp);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _currentNodeIndex = targetNodeIndex;
          _isPlaying = false;
        });
      }
    }
  }

  /// Get available directions from current node
  Map<String, int> get _availableDirections {
    return _nodes[_currentNodeIndex].connections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video layer
          _buildVideoLayer(),

          // Gradient overlay for better UI visibility
          _buildGradientOverlay(),

          // Google Street View style overlays
          if (_isInitialized && !_isLoading) ...[
            // Road path overlay (chevrons on ground)
            if (!_isPlaying && _availableDirections.containsKey('forward'))
              _buildRoadPathOverlay(),

            // Bottom info bar with location
            _buildStreetViewBottomBar(),

            // Compass indicator
            _buildCompassIndicator(),

            // Progress timeline
            _buildProgressTimeline(),

            // Navigation arrows with chevron style
            if (!_isPlaying) _buildNavigationArrows(),

            // Zoom controls
            _buildZoomControls(),
          ],

          // Loading/Playing indicator
          if (_isPlaying) _buildMovingIndicator(),

          // Back button
          _buildBackButton(),

          // Mini map toggle
          _buildMiniMapButton(),
        ],
      ),
    );
  }

  /// Google Street View style road path chevrons
  Widget _buildRoadPathOverlay() {
    return Positioned(
      bottom: 180,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          children: List.generate(5, (index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 800 + (index * 100)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: (1.0 - (index * 0.15)) * value,
                  child: Transform.translate(
                    offset: Offset(0, -index * 15.0 * value),
                    child: CustomPaint(
                      size: Size(80 - (index * 10), 20),
                      painter: _ChevronPainter(
                        color: Colors.white.withOpacity(0.7 - (index * 0.1)),
                        strokeWidth: 3.0 - (index * 0.3),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  /// Street View style bottom info bar
  Widget _buildStreetViewBottomBar() {
    final currentNode = _nodes[_currentNodeIndex];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
          ),
        ),
        child: Row(
          children: [
            // Location pin and name
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentNode.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Campus Navigation • ${_currentNodeIndex + 1} of ${_nodes.length}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Street View icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(
                Icons.streetview,
                color: Colors.amber,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compass indicator (Google Street View style)
  Widget _buildCompassIndicator() {
    // Simulate compass direction based on node position
    final direction = (_currentNodeIndex * 45) % 360;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 16,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Compass ring
            Transform.rotate(
              angle: direction * math.pi / 180,
              child: const Icon(Icons.navigation, color: Colors.red, size: 24),
            ),
            // N indicator
            Positioned(
              top: 4,
              child: Text(
                'N',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Progress timeline showing path through locations
  Widget _buildProgressTimeline() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress dots
            ...List.generate(_nodes.length, (index) {
              final isVisited = index <= _currentNodeIndex;
              final isCurrent = index == _currentNodeIndex;

              return Row(
                children: [
                  Container(
                    width: isCurrent ? 12 : 8,
                    height: isCurrent ? 12 : 8,
                    decoration: BoxDecoration(
                      color: isVisited
                          ? (isCurrent ? Colors.amber : Colors.green)
                          : Colors.white24,
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                  if (index < _nodes.length - 1)
                    Container(
                      width: 16,
                      height: 2,
                      color: isVisited ? Colors.green : Colors.white24,
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Zoom controls (Street View style)
  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            _buildZoomButton(Icons.add, () {
              // Zoom in functionality (placeholder)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Zoom in'),
                  duration: const Duration(milliseconds: 500),
                  backgroundColor: Colors.black87,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),
            Container(height: 1, width: 36, color: Colors.white24),
            _buildZoomButton(Icons.remove, () {
              // Zoom out functionality (placeholder)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Zoom out'),
                  duration: const Duration(milliseconds: 500),
                  backgroundColor: Colors.black87,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading Street View...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _initializeVideo();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Full screen video with aspect ratio handling
    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.4),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.6),
            ],
            stops: const [0.0, 0.2, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationArrows() {
    final directions = _availableDirections;

    return Stack(
      children: [
        // Forward arrow - Street View style ground chevron
        if (directions.containsKey('forward'))
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 180,
            left: 0,
            right: 0,
            child: Center(
              child: _StreetViewChevron(
                direction: 'forward',
                onTap: () => _navigateToNode(directions['forward']!),
                label: _nodes[directions['forward']!].name,
              ),
            ),
          ),

        // Back arrow - smaller at bottom
        if (directions.containsKey('back'))
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 85,
            left: 16,
            child: _StreetViewChevron(
              direction: 'back',
              onTap: () => _navigateToNode(directions['back']!),
              label: _nodes[directions['back']!].name,
              isSmall: true,
            ),
          ),

        // Left arrow - side chevron
        if (directions.containsKey('left'))
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 180,
            left: 24,
            child: _StreetViewChevron(
              direction: 'left',
              onTap: () => _navigateToNode(directions['left']!),
              label: _nodes[directions['left']!].name,
              isSmall: true,
            ),
          ),

        // Right arrow - side chevron
        if (directions.containsKey('right'))
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 180,
            right: 24,
            child: _StreetViewChevron(
              direction: 'right',
              onTap: () => _navigateToNode(directions['right']!),
              label: _nodes[directions['right']!].name,
              isSmall: true,
            ),
          ),
      ],
    );
  }

  Widget _buildMovingIndicator() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Moving...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      child: Material(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMapButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 16,
      child: Material(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            _showNodeSelector();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.map_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  void _showNodeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Jump to Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _nodes.length,
                itemBuilder: (context, index) {
                  final node = _nodes[index];
                  final isCurrentNode = index == _currentNodeIndex;

                  return ListTile(
                    leading: Icon(
                      isCurrentNode
                          ? Icons.location_on
                          : Icons.location_on_outlined,
                      color: isCurrentNode ? Colors.redAccent : Colors.white54,
                    ),
                    title: Text(
                      node.name,
                      style: TextStyle(
                        color: isCurrentNode ? Colors.redAccent : Colors.white,
                        fontWeight: isCurrentNode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isCurrentNode
                        ? const Text(
                            'Current',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    onTap: isCurrentNode
                        ? null
                        : () {
                            Navigator.pop(context);
                            _jumpToNode(index);
                          },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Direct jump to a node (for quick navigation from menu)
  Future<void> _jumpToNode(int targetNodeIndex) async {
    if (_controller == null || !_isInitialized) return;
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
    });

    final targetNode = _nodes[targetNodeIndex];
    await _controller!.seekTo(targetNode.timestamp);
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _currentNodeIndex = targetNodeIndex;
        _isPlaying = false;
      });
    }
  }
}

/// Represents a virtual location node in the video
class VideoNode {
  final int id;
  final String name;
  final Duration timestamp;
  final Map<String, int> connections;

  const VideoNode({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.connections,
  });
}

/// Navigation arrow widget with hover/tap effects
class _NavigationArrow extends StatefulWidget {
  final String direction;
  final IconData icon;
  final VoidCallback onTap;
  final String label;

  const _NavigationArrow({
    required this.direction,
    required this.icon,
    required this.onTap,
    required this.label,
  });

  @override
  State<_NavigationArrow> createState() => _NavigationArrowState();
}

class _NavigationArrowState extends State<_NavigationArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isHovered ? 1.2 : _pulseAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label (shows on hover or for forward direction)
                  if (_isHovered || widget.direction == 'forward')
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  // Arrow button
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(_isHovered ? 0.8 : 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 32),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Street View style chevron navigation widget
class _StreetViewChevron extends StatefulWidget {
  final String direction;
  final VoidCallback onTap;
  final String label;
  final bool isSmall;

  const _StreetViewChevron({
    required this.direction,
    required this.onTap,
    required this.label,
    this.isSmall = false,
  });

  @override
  State<_StreetViewChevron> createState() => _StreetViewChevronState();
}

class _StreetViewChevronState extends State<_StreetViewChevron>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double _getRotation() {
    switch (widget.direction) {
      case 'forward':
        return 0;
      case 'back':
        return math.pi;
      case 'left':
        return -math.pi / 2;
      case 'right':
        return math.pi / 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isSmall ? 50.0 : 70.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label above chevron (for forward direction)
              if (widget.direction == 'forward' || _isPressed)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              // Chevron button with glow effect
              Transform.scale(
                scale: _isPressed ? 0.9 : _scaleAnimation.value,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.amber.withOpacity(_glowAnimation.value),
                        Colors.orange.withOpacity(_glowAnimation.value * 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(
                          _glowAnimation.value * 0.5,
                        ),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Transform.rotate(
                    angle: _getRotation(),
                    child: CustomPaint(
                      painter: _GroundChevronPainter(
                        color: Colors.white,
                        progress: _glowAnimation.value,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: Colors.white,
                          size: widget.isSmall ? 28 : 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Chevron painter for road path overlay
class _ChevronPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ChevronPainter({required this.color, this.strokeWidth = 3.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Ground chevron painter for navigation buttons
class _GroundChevronPainter extends CustomPainter {
  final Color color;
  final double progress;

  _GroundChevronPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle inner chevron lines
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    // Draw concentric arcs
    for (int i = 0; i < 2; i++) {
      final r = radius - (i * 8);
      final rect = Rect.fromCircle(center: center.translate(0, 5), radius: r);
      canvas.drawArc(rect, -math.pi * 0.8, math.pi * 0.6, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GroundChevronPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
