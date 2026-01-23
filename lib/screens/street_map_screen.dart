import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

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
  static const List<VideoNode> _nodes = [
    VideoNode(
      id: 0,
      name: 'Main Entrance',
      timestamp: Duration(milliseconds: 0),
      connections: {'forward': 1},
    ),
    VideoNode(
      id: 1,
      name: 'Front Pathway',
      timestamp: Duration(milliseconds: 3000),
      connections: {'forward': 2, 'back': 0},
    ),
    VideoNode(
      id: 2,
      name: 'Central Junction',
      timestamp: Duration(milliseconds: 6000),
      connections: {'forward': 3, 'back': 1, 'left': 4, 'right': 5},
    ),
    VideoNode(
      id: 3,
      name: 'Block A - Administrative',
      timestamp: Duration(milliseconds: 9000),
      connections: {'back': 2},
    ),
    VideoNode(
      id: 4,
      name: 'Block D - Departments',
      timestamp: Duration(milliseconds: 12000),
      connections: {'back': 2, 'forward': 6},
    ),
    VideoNode(
      id: 5,
      name: 'Workshop Area',
      timestamp: Duration(milliseconds: 15000),
      connections: {'back': 2, 'forward': 7},
    ),
    VideoNode(
      id: 6,
      name: 'Canteen',
      timestamp: Duration(milliseconds: 18000),
      connections: {'back': 4},
    ),
    VideoNode(
      id: 7,
      name: 'Sports Complex',
      timestamp: Duration(milliseconds: 21000),
      connections: {'back': 5, 'left': 8, 'right': 9},
    ),
    VideoNode(
      id: 8,
      name: 'Basketball Court',
      timestamp: Duration(milliseconds: 24000),
      connections: {'back': 7},
    ),
    VideoNode(
      id: 9,
      name: 'Volleyball Court',
      timestamp: Duration(milliseconds: 27000),
      connections: {'back': 7},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    // Lock to landscape for immersive street view
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializeVideo() async {
    try {
      // Initialize video player with local asset
      _controller = VideoPlayerController.asset('assets/videos/campus_tour.mp4');
      
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
    final segmentDuration = (targetNode.timestamp - currentNode.timestamp).abs();
    
    // Determine if we're going forward or backward in video
    final isForward = targetNode.timestamp > currentNode.timestamp;
    
    if (isForward) {
      // Play forward from current position to target
      await _controller!.seekTo(currentNode.timestamp);
      await _controller!.play();
      
      // Set timer to pause at target node
      _segmentTimer?.cancel();
      _segmentTimer = Timer(segmentDuration + const Duration(milliseconds: 100), () async {
        await _controller!.pause();
        await _controller!.seekTo(targetNode.timestamp);
        if (mounted) {
          setState(() {
            _currentNodeIndex = targetNodeIndex;
            _isPlaying = false;
          });
        }
      });
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
          
          // Location name overlay
          _buildLocationOverlay(),
          
          // Navigation arrows
          if (_isInitialized && !_isPlaying)
            _buildNavigationArrows(),
          
          // Loading/Playing indicator
          if (_isPlaying)
            _buildMovingIndicator(),
          
          // Back button
          _buildBackButton(),
          
          // Mini map toggle (optional)
          _buildMiniMapButton(),
        ],
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

  Widget _buildLocationOverlay() {
    final currentNode = _nodes[_currentNodeIndex];
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                currentNode.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationArrows() {
    final directions = _availableDirections;
    
    return Stack(
      children: [
        // Forward arrow (top center)
        if (directions.containsKey('forward'))
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 0,
            right: 0,
            child: Center(
              child: _NavigationArrow(
                direction: 'forward',
                icon: Icons.arrow_upward_rounded,
                onTap: () => _navigateToNode(directions['forward']!),
                label: _nodes[directions['forward']!].name,
              ),
            ),
          ),
        
        // Back arrow (bottom center)
        if (directions.containsKey('back'))
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: _NavigationArrow(
                direction: 'back',
                icon: Icons.arrow_downward_rounded,
                onTap: () => _navigateToNode(directions['back']!),
                label: _nodes[directions['back']!].name,
              ),
            ),
          ),
        
        // Left arrow
        if (directions.containsKey('left'))
          Positioned(
            top: 0,
            bottom: 0,
            left: 40,
            child: Center(
              child: _NavigationArrow(
                direction: 'left',
                icon: Icons.arrow_back_rounded,
                onTap: () => _navigateToNode(directions['left']!),
                label: _nodes[directions['left']!].name,
              ),
            ),
          ),
        
        // Right arrow
        if (directions.containsKey('right'))
          Positioned(
            top: 0,
            bottom: 0,
            right: 40,
            child: Center(
              child: _NavigationArrow(
                direction: 'right',
                icon: Icons.arrow_forward_rounded,
                onTap: () => _navigateToNode(directions['right']!),
                label: _nodes[directions['right']!].name,
              ),
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
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
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
                      isCurrentNode ? Icons.location_on : Icons.location_on_outlined,
                      color: isCurrentNode ? Colors.redAccent : Colors.white54,
                    ),
                    title: Text(
                      node.name,
                      style: TextStyle(
                        color: isCurrentNode ? Colors.redAccent : Colors.white,
                        fontWeight: isCurrentNode ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isCurrentNode
                        ? const Text('Current', style: TextStyle(color: Colors.white54, fontSize: 12))
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 32,
                    ),
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
