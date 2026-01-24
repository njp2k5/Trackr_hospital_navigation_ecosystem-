import 'dart:math';
import 'package:flutter/material.dart';

/// Campus routing service for indoor navigation on a static map.
/// Uses calibrated reference points and graph-based pathfinding.
///
/// **Coordinate System:**
/// - All destination markers and route points use normalized (0–1) coordinates
///   relative to the ORIGINAL image dimensions, not the screen.
/// - To convert to screen space: screenX = normalized.dx * imageWidth
///   and screenY = normalized.dy * imageHeight.
/// - This ensures markers align exactly with visible map locations regardless
///   of screen size or aspect ratio.
///
/// **Routing Rules:**
/// - Walkable paths are defined by calibrated reference points.
/// - Routes MUST strictly follow paths through these reference points.
/// - NEVER draw straight lines between destinations.
/// - Always follow the path through connected reference points.
///
/// **Rendering Guidelines:**
/// - Draw the route as a thin, semi-transparent polyline using CustomPainter.
/// - Use rounded stroke caps (StrokeCap.round) and joins (StrokeJoin.round).
/// - Layer order:
///   1) Map image (bottom)
///   2) Route overlay
///   3) Destination numbers / markers (always visible above route)
class CampusRoutingService {
  static final CampusRoutingService _instance =
      CampusRoutingService._internal();
  factory CampusRoutingService() => _instance;
  CampusRoutingService._internal();

  /// Calibrated reference points for the walkable path network
  /// These points were manually calibrated on the 2D map
  /// Generated: 2026-01-24
  static const List<Map<String, dynamic>> referencePoints = [
    {'id': 1, 'x': 0.2819, 'y': 0.1716, 'label': 'Ref 2'},
    {'id': 2, 'x': 0.2604, 'y': 0.0888, 'label': 'Ref 3'},
    {'id': 3, 'x': 0.3051, 'y': 0.2465, 'label': 'Ref 4'},
    {'id': 4, 'x': 0.3303, 'y': 0.3310, 'label': 'Ref 5'},
    {'id': 5, 'x': 0.3493, 'y': 0.4112, 'label': 'Ref 6'},
    {'id': 8, 'x': 0.3935, 'y': 0.3554, 'label': 'Ref 9'},
    {'id': 9, 'x': 0.4763, 'y': 0.3447, 'label': 'Ref 10'},
    {'id': 10, 'x': 0.5523, 'y': 0.3533, 'label': 'Ref 11'},
    {'id': 11, 'x': 0.6272, 'y': 0.3811, 'label': 'Ref 12'},
    {'id': 12, 'x': 0.6795, 'y': 0.4341, 'label': 'Ref 13'},
    {'id': 13, 'x': 0.7152, 'y': 0.4816, 'label': 'Ref 14'},
    {'id': 14, 'x': 0.6277, 'y': 0.4860, 'label': 'Ref 15'},
    {'id': 15, 'x': 0.5636, 'y': 0.5221, 'label': 'Ref 16'},
    {'id': 16, 'x': 0.5814, 'y': 0.5863, 'label': 'Ref 17'},
    {'id': 18, 'x': 0.5744, 'y': 0.6535, 'label': 'Ref 19'},
    {'id': 19, 'x': 0.5319, 'y': 0.7026, 'label': 'Ref 20'},
    {'id': 20, 'x': 0.4763, 'y': 0.7317, 'label': 'Ref 21'},
    {'id': 21, 'x': 0.4030, 'y': 0.7202, 'label': 'Ref 22'},
    {'id': 22, 'x': 0.3552, 'y': 0.6589, 'label': 'Ref 23'},
    {'id': 24, 'x': 0.3473, 'y': 0.5897, 'label': 'Ref 25'},
    {'id': 25, 'x': 0.3847, 'y': 0.5194, 'label': 'Ref 26'},
    {'id': 26, 'x': 0.3598, 'y': 0.7428, 'label': 'Ref 27'},
    {'id': 27, 'x': 0.3968, 'y': 0.7681, 'label': 'Ref 28'},
    {'id': 28, 'x': 0.3215, 'y': 0.7843, 'label': 'Ref 29'},
    {'id': 29, 'x': 0.6997, 'y': 0.3907, 'label': 'Ref 30'},
    {'id': 30, 'x': 0.7467, 'y': 0.3550, 'label': 'Ref 31'},
    {'id': 31, 'x': 0.4859, 'y': 0.7817, 'label': 'Ref 32'},
    {'id': 32, 'x': 0.3982, 'y': 0.8272, 'label': 'Ref 33'},
    {'id': 33, 'x': 0.4300, 'y': 0.8651, 'label': 'Ref 34'},
    {'id': 34, 'x': 0.4633, 'y': 0.9043, 'label': 'Ref 35'},
    {'id': 35, 'x': 0.3612, 'y': 0.8074, 'label': 'Ref 36'},
    {'id': 36, 'x': 0.3716, 'y': 0.4727, 'label': 'Ref 37'},
    {'id': 37, 'x': 0.1788, 'y': 0.0898, 'label': 'Ref 38'},
    {'id': 39, 'x': 0.2997, 'y': 0.0526, 'label': 'Ref 40'},
    {'id': 40, 'x': 0.7697, 'y': 0.5125, 'label': 'Ref 41'},
    {'id': 41, 'x': 0.5113, 'y': 0.8729, 'label': 'Ref 42'},
    {'id': 42, 'x': 0.4475, 'y': 0.9388, 'label': 'Ref 43'},
  ];

  /// Path connections between reference points (adjacency list)
  /// Each entry defines which reference points are directly connected
  static const Map<int, List<int>> pathConnections = {
    // Northern area connections
    37: [2], // Ref 38 -> Ref 3
    2: [37, 1, 39], // Ref 3 -> Ref 38, Ref 2, Ref 40
    39: [2], // Ref 40 -> Ref 3
    1: [2, 3], // Ref 2 -> Ref 3, Ref 4
    3: [1, 4], // Ref 4 -> Ref 2, Ref 5
    4: [3, 5, 8], // Ref 5 -> Ref 4, Ref 6, Ref 9
    // Central area connections
    5: [4, 36], // Ref 6 -> Ref 5, Ref 37
    36: [5, 25], // Ref 37 -> Ref 6, Ref 26
    25: [36, 24], // Ref 26 -> Ref 37, Ref 25
    24: [25, 22], // Ref 25 -> Ref 26, Ref 23
    22: [24, 21, 26], // Ref 23 -> Ref 25, Ref 22, Ref 27
    // Main pathway connections
    8: [4, 9], // Ref 9 -> Ref 5, Ref 10
    9: [8, 10], // Ref 10 -> Ref 9, Ref 11
    10: [9, 11], // Ref 11 -> Ref 10, Ref 12
    11: [10, 12, 29], // Ref 12 -> Ref 11, Ref 13, Ref 30
    12: [11, 13, 14], // Ref 13 -> Ref 12, Ref 14, Ref 15
    // Eastern area connections
    29: [11, 30], // Ref 30 -> Ref 12, Ref 31
    30: [29], // Ref 31 -> Ref 30
    13: [12, 40], // Ref 14 -> Ref 13, Ref 41
    40: [13], // Ref 41 -> Ref 14
    // Canteen/central area connections
    14: [12, 15], // Ref 15 -> Ref 13, Ref 16
    15: [14, 16], // Ref 16 -> Ref 15, Ref 17
    16: [15, 18], // Ref 17 -> Ref 16, Ref 19
    18: [16, 19], // Ref 19 -> Ref 17, Ref 20
    19: [18, 20], // Ref 20 -> Ref 19, Ref 21
    20: [19, 21, 31], // Ref 21 -> Ref 20, Ref 22, Ref 32
    // Western/southern area connections
    21: [20, 22, 27], // Ref 22 -> Ref 21, Ref 23, Ref 28
    26: [22, 27, 28], // Ref 27 -> Ref 23, Ref 28, Ref 29
    27: [21, 26, 32], // Ref 28 -> Ref 22, Ref 27, Ref 33
    28: [26, 35], // Ref 29 -> Ref 27, Ref 36
    35: [28, 32], // Ref 36 -> Ref 29, Ref 33
    // Southern entrance area connections
    31: [20, 41], // Ref 32 -> Ref 21, Ref 42
    32: [27, 35, 33], // Ref 33 -> Ref 28, Ref 36, Ref 34
    33: [32, 34], // Ref 34 -> Ref 33, Ref 35
    34: [33, 42], // Ref 35 -> Ref 34, Ref 43
    41: [31, 42], // Ref 42 -> Ref 32, Ref 43
    42: [34, 41], // Ref 43 -> Ref 35, Ref 42
  };

  /// Wheelchair-friendly path connections (subset of pathConnections)
  /// Excludes paths with stairs, steep inclines, or rough terrain
  /// Accessible paths are generally wider, paved, and have gentle slopes
  static const Map<int, List<int>> wheelchairPathConnections = {
    // Main accessible northern pathway
    2: [1, 39], // Ref 3 - accessible entrance area
    39: [2], // Ref 40 -> Ref 3
    1: [2, 3], // Ref 2 - paved walkway
    3: [1, 4], // Ref 4 - main road
    4: [3, 8], // Ref 5 - main road (excludes 5 which has rough path)
    // Main accessible pathway (paved road)
    8: [4, 9], // Ref 9 - paved main road
    9: [8, 10], // Ref 10 - continues on paved road
    10: [9, 11], // Ref 11 - main campus road
    11: [10, 12, 29], // Ref 12 - main road junction
    12: [11, 13, 14], // Ref 13 - accessible junction
    // Eastern accessible area
    29: [11, 30], // Ref 30 - paved path
    30: [29], // Ref 31 - accessible endpoint
    13: [12, 40], // Ref 14 - paved path to building
    40: [13], // Ref 41 - building entrance (accessible)
    // Central accessible paths
    14: [12, 15], // Ref 15 - accessible path
    15: [14, 16], // Ref 16 - paved walkway
    16: [15, 18], // Ref 17 - accessible route
    18: [16, 19], // Ref 19 - paved path
    19: [18, 20], // Ref 20 - main accessible route
    20: [19, 21, 31], // Ref 21 - accessible junction
    // Western accessible route (avoiding rough terrain)
    21: [20, 27], // Ref 22 - accessible (excludes 22 which has steps)
    27: [21, 32], // Ref 28 - paved path (excludes 26 steep path)
    // Southern accessible entrance
    31: [20, 41], // Ref 32 - accessible main entrance path
    32: [27, 33], // Ref 33 - paved walkway (excludes 35 steep)
    33: [32, 34], // Ref 34 - accessible path
    34: [33, 42], // Ref 35 - main entrance accessible
    41: [31, 42], // Ref 42 - accessible path
    42: [34, 41], // Ref 43 - main accessible entrance
  };

  /// Destination locations mapped by number and name
  /// Coordinates are normalized (0-1) based on map image dimensions
  /// nearestRefPoint indicates which reference point is closest for routing
  static const Map<int, DestinationInfo> destinations = {
    1: DestinationInfo(
      id: 1,
      name: 'Block A / Administrative Block',
      shortName: 'Block A',
      position: Offset(0.548, 0.767),
      nearestRefPoint: 20, // Near Ref 21
    ),
    2: DestinationInfo(
      id: 2,
      name: 'Block D / Department Block',
      shortName: 'Block D',
      position: Offset(0.438, 0.804),
      nearestRefPoint: 27, // Near Ref 28
    ),
    3: DestinationInfo(
      id: 3,
      name: 'Block C / Workshop Block',
      shortName: 'Workshop',
      position: Offset(0.491, 0.278),
      nearestRefPoint: 9, // Near Ref 10
    ),
    4: DestinationInfo(
      id: 4,
      name: 'Casting Yard',
      shortName: 'Casting Yard',
      position: Offset(0.655, 0.438),
      nearestRefPoint: 12, // Near Ref 13
    ),
    5: DestinationInfo(
      id: 5,
      name: 'Badminton Court',
      shortName: 'Badminton',
      position: Offset(0.547, 0.429),
      nearestRefPoint: 10, // Near Ref 11
    ),
    6: DestinationInfo(
      id: 6,
      name: 'Volleyball Court',
      shortName: 'Volleyball',
      position: Offset(0.270, 0.746),
      nearestRefPoint: 26, // Near Ref 27
    ),
    7: DestinationInfo(
      id: 7,
      name: 'Ground / Playground',
      shortName: 'Ground',
      position: Offset(0.602, 0.288),
      nearestRefPoint: 10, // Near Ref 11
    ),
    8: DestinationInfo(
      id: 8,
      name: 'Kuppi Veedu',
      shortName: 'Kuppi Veedu',
      position: Offset(0.783, 0.391),
      nearestRefPoint: 30, // Near Ref 31
    ),
    9: DestinationInfo(
      id: 9,
      name: 'Canteen',
      shortName: 'Canteen',
      position: Offset(0.655, 0.513),
      nearestRefPoint: 13, // Near Ref 14
    ),
    10: DestinationInfo(
      id: 10,
      name: 'Pond',
      shortName: 'Pond',
      position: Offset(0.460, 0.620),
      nearestRefPoint: 22, // Near Ref 23
    ),
    11: DestinationInfo(
      id: 11,
      name: 'Small Pond',
      shortName: 'Small Pond',
      position: Offset(0.600, 0.566),
      nearestRefPoint: 16, // Near Ref 17
    ),
    12: DestinationInfo(
      id: 12,
      name: 'Staff Parking',
      shortName: 'Staff Parking',
      position: Offset(0.623, 0.614),
      nearestRefPoint: 18, // Near Ref 19
    ),
    13: DestinationInfo(
      id: 13,
      name: 'Parking Area',
      shortName: 'Parking',
      position: Offset(0.434, 0.312),
      nearestRefPoint: 8, // Near Ref 9
    ),
    14: DestinationInfo(
      id: 14,
      name: 'Student Parking',
      shortName: 'Student Parking',
      position: Offset(0.371, 0.265),
      nearestRefPoint: 4, // Near Ref 5
    ),
    15: DestinationInfo(
      id: 15,
      name: 'Basketball Court',
      shortName: 'Basketball',
      position: Offset(0.296, 0.656),
      nearestRefPoint: 22, // Near Ref 23
    ),
  };

  /// Graph representation for pathfinding
  late Map<int, List<GraphEdge>> _graph;
  late Map<int, Offset> _nodePositions;

  bool _initialized = false;
  bool _isWheelchairMode = false;

  /// Initialize the routing graph
  void initialize({bool wheelchairMode = false}) {
    // Reinitialize if wheelchair mode changed
    if (_initialized && _isWheelchairMode == wheelchairMode) return;

    _isWheelchairMode = wheelchairMode;
    _buildGraph(wheelchairMode: wheelchairMode);
    _initialized = true;
  }

  /// Build the graph from reference points and connections
  void _buildGraph({bool wheelchairMode = false}) {
    _graph = {};
    _nodePositions = {};

    // Build node positions from reference points
    for (final ref in referencePoints) {
      final id = ref['id'] as int;
      final x = ref['x'] as double;
      final y = ref['y'] as double;
      _nodePositions[id] = Offset(x, y);
      _graph[id] = [];
    }

    // Choose path connections based on wheelchair mode
    final connections = wheelchairMode
        ? wheelchairPathConnections
        : pathConnections;

    // Build edges from path connections
    for (final entry in connections.entries) {
      final fromId = entry.key;
      final neighborIds = entry.value;

      if (!_nodePositions.containsKey(fromId)) continue;

      for (final toId in neighborIds) {
        if (!_nodePositions.containsKey(toId)) continue;

        final fromPos = _nodePositions[fromId]!;
        final toPos = _nodePositions[toId]!;
        final dist = _distance(fromPos, toPos);

        // Add bidirectional edge
        _graph[fromId]!.add(GraphEdge(toId, toPos, dist));
      }
    }
  }

  /// Find route between two locations
  /// Returns a path that starts at the source's actual position (numbered point),
  /// connects through calibrated reference points, and ends at the destination's actual position.
  /// Set wheelchairFriendly to true for accessible routes
  List<Offset> findRoute(
    String source,
    String destination, {
    bool wheelchairFriendly = false,
  }) {
    initialize(wheelchairMode: wheelchairFriendly);

    // Find destination info by name
    final sourceInfo = _findDestinationByName(source);
    final destInfo = _findDestinationByName(destination);

    if (sourceInfo == null || destInfo == null) {
      // Fallback: return direct path between positions or defaults
      final sourcePos = sourceInfo?.position ?? const Offset(0.18, 0.85);
      final destPos = destInfo?.position ?? const Offset(0.5, 0.5);
      return [sourcePos, destPos];
    }

    // Build the complete route:
    // 1. Start at the actual source position (numbered point on map)
    // 2. Connect to nearest reference point
    // 3. Follow reference point path to destination's nearest reference point
    // 4. Connect from reference point to actual destination position

    final sourcePosition = sourceInfo.position;
    final sourceRefPoint = sourceInfo.nearestRefPoint;
    final destRefPoint = destInfo.nearestRefPoint;
    final destPosition = destInfo.position;

    // Find path through reference points using BFS/Dijkstra
    final refPointPath = _findPathBetweenRefPoints(
      sourceRefPoint,
      destRefPoint,
    );

    // Build complete route: source position -> reference points path -> destination position
    final completeRoute = <Offset>[];

    // Add source position (the actual numbered point)
    completeRoute.add(sourcePosition);

    // Add all reference points in the path
    for (final refId in refPointPath) {
      final pos = _nodePositions[refId];
      if (pos != null) {
        completeRoute.add(pos);
      }
    }

    // Add destination position (the actual numbered point)
    completeRoute.add(destPosition);

    return completeRoute;
  }

  /// Find path between two reference points using Dijkstra's algorithm
  List<int> _findPathBetweenRefPoints(int startRef, int endRef) {
    if (startRef == endRef) {
      return [startRef];
    }

    // Dijkstra's algorithm
    final distances = <int, double>{};
    final previous = <int, int?>{};
    final visited = <int>{};
    final queue = <int>[];

    // Initialize
    for (final id in _nodePositions.keys) {
      distances[id] = double.infinity;
      previous[id] = null;
    }
    distances[startRef] = 0;
    queue.add(startRef);

    while (queue.isNotEmpty) {
      // Find node with smallest distance
      queue.sort(
        (a, b) => (distances[a] ?? double.infinity).compareTo(
          distances[b] ?? double.infinity,
        ),
      );
      final current = queue.removeAt(0);

      if (visited.contains(current)) continue;
      visited.add(current);

      if (current == endRef) break;

      // Process neighbors
      for (final edge in _graph[current] ?? []) {
        final neighbor = edge.targetId;
        final newDist = (distances[current] ?? double.infinity) + edge.distance;

        if (newDist < (distances[neighbor] ?? double.infinity)) {
          distances[neighbor] = newDist;
          previous[neighbor] = current;
          if (!visited.contains(neighbor)) {
            queue.add(neighbor);
          }
        }
      }
    }

    // Reconstruct path
    final path = <int>[];
    int? current = endRef;

    while (current != null) {
      path.insert(0, current);
      current = previous[current];
    }

    // If path doesn't start with startRef, no path was found
    if (path.isEmpty || path.first != startRef) {
      return [startRef, endRef]; // Fallback to direct connection
    }

    return path;
  }

  /// Find destination by name (case-insensitive partial match)
  DestinationInfo? _findDestinationByName(String name) {
    final lowerName = name.toLowerCase().trim();

    // Try exact match first
    for (final dest in destinations.values) {
      if (dest.name.toLowerCase() == lowerName ||
          dest.shortName.toLowerCase() == lowerName) {
        return dest;
      }
    }

    // Try partial match
    for (final dest in destinations.values) {
      if (dest.name.toLowerCase().contains(lowerName) ||
          dest.shortName.toLowerCase().contains(lowerName) ||
          lowerName.contains(dest.shortName.toLowerCase())) {
        return dest;
      }
    }

    // Try number match
    final number = int.tryParse(lowerName);
    if (number != null && destinations.containsKey(number)) {
      return destinations[number];
    }

    // Special cases
    if (lowerName.contains('block a') || lowerName.contains('admin')) {
      return destinations[1];
    }
    if (lowerName.contains('block d') || lowerName.contains('department')) {
      return destinations[2];
    }
    if (lowerName.contains('workshop') || lowerName.contains('block c')) {
      return destinations[3];
    }
    if (lowerName.contains('casting')) {
      return destinations[4];
    }
    if (lowerName.contains('badminton')) {
      return destinations[5];
    }
    if (lowerName.contains('volleyball')) {
      return destinations[6];
    }
    if (lowerName.contains('ground') || lowerName.contains('playground')) {
      return destinations[7];
    }
    if (lowerName.contains('kuppi')) {
      return destinations[8];
    }
    if (lowerName.contains('canteen')) {
      return destinations[9];
    }
    if (lowerName.contains('small pond')) {
      return destinations[11];
    }
    if (lowerName.contains('pond')) {
      return destinations[10];
    }
    if (lowerName.contains('staff') && lowerName.contains('parking')) {
      return destinations[12];
    }
    if (lowerName.contains('student') && lowerName.contains('parking')) {
      return destinations[14];
    }
    if (lowerName.contains('parking')) {
      return destinations[13];
    }
    if (lowerName.contains('basketball')) {
      return destinations[15];
    }

    return null;
  }

  double _distance(Offset a, Offset b) {
    return sqrt(pow(a.dx - b.dx, 2) + pow(a.dy - b.dy, 2));
  }

  /// Get all destination markers for display
  List<DestinationMarker> getDestinationMarkers() {
    return destinations.entries
        .map(
          (e) => DestinationMarker(
            id: e.key,
            position: e.value.position,
            label: e.key.toString(),
            name: e.value.shortName,
          ),
        )
        .toList();
  }

  /// Get all reference point polylines for debug visualization
  List<List<Offset>> getCorridorPolylines() {
    initialize();
    final polylines = <List<Offset>>[];

    // Generate polylines from path connections
    final visited = <String>{};

    for (final entry in pathConnections.entries) {
      final fromId = entry.key;
      final fromPos = _nodePositions[fromId];
      if (fromPos == null) continue;

      for (final toId in entry.value) {
        final key = '${min(fromId, toId)}-${max(fromId, toId)}';
        if (visited.contains(key)) continue;
        visited.add(key);

        final toPos = _nodePositions[toId];
        if (toPos == null) continue;

        polylines.add([fromPos, toPos]);
      }
    }

    return polylines;
  }

  /// Get reference point positions for visualization
  List<Offset> getReferencePointPositions() {
    initialize();
    return _nodePositions.values.toList();
  }
}

/// Destination information
class DestinationInfo {
  final int id;
  final String name;
  final String shortName;
  final Offset position; // Visual position on map
  final int nearestRefPoint; // ID of nearest reference point for routing

  const DestinationInfo({
    required this.id,
    required this.name,
    required this.shortName,
    required this.position,
    required this.nearestRefPoint,
  });
}

/// Graph edge for pathfinding
class GraphEdge {
  final int targetId;
  final Offset targetPoint;
  final double distance;

  GraphEdge(this.targetId, this.targetPoint, this.distance);
}

/// Destination marker for map display
class DestinationMarker {
  final int id;
  final Offset position;
  final String label;
  final String name;

  DestinationMarker({
    required this.id,
    required this.position,
    required this.label,
    required this.name,
  });
}
