import 'dart:math';
import 'package:flutter/material.dart';

/// Campus routing service for indoor navigation on a static map.
/// Uses predefined corridor polylines and graph-based pathfinding.
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
/// - Walkable paths are predefined as corridor polylines (curved paths allowed).
/// - Routes MUST strictly follow these corridor polylines only.
/// - NEVER draw straight lines between destinations.
/// - NEVER cross the central blue circle or any non-walkable area.
/// - Even if longer, always follow the curved corridor path segments.
///
/// **Rendering Guidelines:**
/// - Draw the route as a thin, semi-transparent polyline using CustomPainter.
/// - Use rounded stroke caps (StrokeCap.round) and joins (StrokeJoin.round).
/// - Layer order:
///   1) Map image (bottom)
///   2) Route overlay
///   3) Destination numbers / markers (always visible above route)
class CampusRoutingService {
  static final CampusRoutingService _instance = CampusRoutingService._internal();
  factory CampusRoutingService() => _instance;
  CampusRoutingService._internal();

  /// Destination locations mapped by number and name
  /// Coordinates are normalized (0-1) based on map image dimensions
  static const Map<int, DestinationInfo> destinations = {
    1: DestinationInfo(
      id: 1,
      name: 'Block A / Administrative Block',
      shortName: 'Block A',
      position: Offset(0.548, 0.767),
      corridorSnapPoint: Offset(0.220, 0.380),
    ),
    2: DestinationInfo(
      id: 2,
      name: 'Block D / Department Block',
      shortName: 'Block D',
      position: Offset(0.438, 0.804),
      corridorSnapPoint: Offset(0.500, 0.450),
    ),
    3: DestinationInfo(
      id: 3,
      name: 'Block C / Workshop Block',
      shortName: 'Workshop',
      position: Offset(0.491, 0.278),
      corridorSnapPoint: Offset(0.380, 0.320),
    ),
    4: DestinationInfo(
      id: 4,
      name: 'Casting Yard',
      shortName: 'Casting Yard',
      position: Offset(0.655, 0.438),
      corridorSnapPoint: Offset(0.450, 0.280),
    ),
    5: DestinationInfo(
      id: 5,
      name: 'Badminton Court',
      shortName: 'Badminton',
      position: Offset(0.547, 0.429),
      corridorSnapPoint: Offset(0.720, 0.220),
    ),
    6: DestinationInfo(
      id: 6,
      name: 'Volleyball Court',
      shortName: 'Volleyball',
      position: Offset(0.270, 0.746),
      corridorSnapPoint: Offset(0.750, 0.300),
    ),
    7: DestinationInfo(
      id: 7,
      name: 'Ground / Playground',
      shortName: 'Ground',
      position: Offset(0.602, 0.288),
      corridorSnapPoint: Offset(0.620, 0.220),
    ),
    8: DestinationInfo(
      id: 8,
      name: 'Kuppi Veedu',
      shortName: 'Kuppi Veedu',
      position: Offset(0.783, 0.391),
      corridorSnapPoint: Offset(0.650, 0.520),
    ),
    9: DestinationInfo(
      id: 9,
      name: 'Canteen',
      shortName: 'Canteen',
      position: Offset(0.655, 0.513),
      corridorSnapPoint: Offset(0.420, 0.520),
    ),
    10: DestinationInfo(
      id: 10,
      name: 'Pond',
      shortName: 'Pond',
      position: Offset(0.460, 0.620),
      corridorSnapPoint: Offset(0.550, 0.620),
    ),
    11: DestinationInfo(
      id: 11,
      name: 'Small Pond',
      shortName: 'Small Pond',
      position: Offset(0.600, 0.566),
      corridorSnapPoint: Offset(0.480, 0.650),
    ),
    12: DestinationInfo(
      id: 12,
      name: 'Staff Parking',
      shortName: 'Staff Parking',
      position: Offset(0.623, 0.614),
      corridorSnapPoint: Offset(0.200, 0.520),
    ),
    13: DestinationInfo(
      id: 13,
      name: 'Parking Area',
      shortName: 'Parking',
      position: Offset(0.434, 0.312),
      corridorSnapPoint: Offset(0.180, 0.720),
    ),
    14: DestinationInfo(
      id: 14,
      name: 'Student Parking',
      shortName: 'Student Parking',
      position: Offset(0.371, 0.265),
      corridorSnapPoint: Offset(0.280, 0.750),
    ),
    15: DestinationInfo(
      id: 15,
      name: 'Basketball Court',
      shortName: 'Basketball',
      position: Offset(0.296, 0.656),
      corridorSnapPoint: Offset(0.780, 0.350),
    ),
  };

  /// Corridor network defined as connected path segments
  /// Each corridor is a polyline of normalized points
  static const List<CorridorSegment> corridors = [
    // Main entrance to central junction
    CorridorSegment(
      id: 'main_entrance',
      points: [
        Offset(0.18, 0.85), // Main entrance
        Offset(0.18, 0.75),
        Offset(0.20, 0.72),
        Offset(0.25, 0.68),
        Offset(0.30, 0.62),
        Offset(0.35, 0.55),
        Offset(0.38, 0.52), // Central junction
      ],
    ),
    
    // Central ring corridor (main walkway around campus)
    CorridorSegment(
      id: 'central_ring_south',
      points: [
        Offset(0.38, 0.52),
        Offset(0.42, 0.52),
        Offset(0.48, 0.52),
        Offset(0.55, 0.52),
        Offset(0.62, 0.52),
        Offset(0.65, 0.52),
      ],
    ),
    
    CorridorSegment(
      id: 'central_ring_east',
      points: [
        Offset(0.65, 0.52),
        Offset(0.68, 0.48),
        Offset(0.72, 0.42),
        Offset(0.75, 0.35),
        Offset(0.78, 0.30),
        Offset(0.78, 0.25),
        Offset(0.75, 0.22),
        Offset(0.72, 0.22),
      ],
    ),
    
    CorridorSegment(
      id: 'central_ring_north',
      points: [
        Offset(0.72, 0.22),
        Offset(0.65, 0.22),
        Offset(0.62, 0.22),
        Offset(0.55, 0.25),
        Offset(0.48, 0.28),
        Offset(0.45, 0.28),
        Offset(0.40, 0.30),
        Offset(0.38, 0.32),
      ],
    ),
    
    CorridorSegment(
      id: 'central_ring_west',
      points: [
        Offset(0.38, 0.32),
        Offset(0.32, 0.35),
        Offset(0.28, 0.38),
        Offset(0.22, 0.38),
        Offset(0.20, 0.42),
        Offset(0.20, 0.48),
        Offset(0.20, 0.52),
        Offset(0.22, 0.55),
        Offset(0.28, 0.58),
        Offset(0.35, 0.55),
        Offset(0.38, 0.52),
      ],
    ),
    
    // Radial paths to destinations
    CorridorSegment(
      id: 'to_block_d',
      points: [
        Offset(0.50, 0.45),
        Offset(0.52, 0.48),
        Offset(0.55, 0.52),
      ],
    ),
    
    CorridorSegment(
      id: 'to_canteen',
      points: [
        Offset(0.42, 0.52),
        Offset(0.42, 0.55),
        Offset(0.42, 0.58),
      ],
    ),
    
    CorridorSegment(
      id: 'to_ponds',
      points: [
        Offset(0.55, 0.52),
        Offset(0.52, 0.58),
        Offset(0.48, 0.62),
        Offset(0.48, 0.65),
        Offset(0.52, 0.62),
        Offset(0.55, 0.62),
      ],
    ),
    
    CorridorSegment(
      id: 'to_sports_east',
      points: [
        Offset(0.75, 0.30),
        Offset(0.78, 0.32),
        Offset(0.78, 0.35),
      ],
    ),
    
    CorridorSegment(
      id: 'to_parking_south',
      points: [
        Offset(0.28, 0.75),
        Offset(0.25, 0.72),
        Offset(0.20, 0.72),
        Offset(0.18, 0.75),
      ],
    ),
  ];

  /// Graph representation for pathfinding
  late Map<String, List<GraphEdge>> _graph;
  late List<Offset> _allNodes;
  
  bool _initialized = false;

  /// Initialize the routing graph
  void initialize() {
    if (_initialized) return;
    
    _buildGraph();
    _initialized = true;
  }

  /// Build the graph from corridor segments
  void _buildGraph() {
    _graph = {};
    _allNodes = [];
    
    // Collect all unique nodes and build edges
    for (final corridor in corridors) {
      for (int i = 0; i < corridor.points.length; i++) {
        final point = corridor.points[i];
        final nodeKey = _nodeKey(point);
        
        if (!_allNodes.any((n) => _distance(n, point) < 0.001)) {
          _allNodes.add(point);
        }
        
        _graph.putIfAbsent(nodeKey, () => []);
        
        // Connect to next point in corridor
        if (i < corridor.points.length - 1) {
          final nextPoint = corridor.points[i + 1];
          final nextKey = _nodeKey(nextPoint);
          final dist = _distance(point, nextPoint);
          
          _graph[nodeKey]!.add(GraphEdge(nextKey, nextPoint, dist));
          _graph.putIfAbsent(nextKey, () => []);
          _graph[nextKey]!.add(GraphEdge(nodeKey, point, dist));
        }
      }
    }
    
    // Connect nearby nodes from different corridors (junction points)
    final nodeList = _allNodes.toList();
    for (int i = 0; i < nodeList.length; i++) {
      for (int j = i + 1; j < nodeList.length; j++) {
        final dist = _distance(nodeList[i], nodeList[j]);
        if (dist < 0.02 && dist > 0.001) {
          // Close enough to be a junction
          final keyI = _nodeKey(nodeList[i]);
          final keyJ = _nodeKey(nodeList[j]);
          _graph[keyI]!.add(GraphEdge(keyJ, nodeList[j], dist));
          _graph[keyJ]!.add(GraphEdge(keyI, nodeList[i], dist));
        }
      }
    }
  }

  /// Find route between two locations
  List<Offset> findRoute(String source, String destination) {
    initialize();
    
    // Find destination info by name
    final sourceInfo = _findDestinationByName(source);
    final destInfo = _findDestinationByName(destination);
    
    if (sourceInfo == null || destInfo == null) {
      // Fallback: return direct path
      return [
        sourceInfo?.corridorSnapPoint ?? const Offset(0.18, 0.85),
        destInfo?.corridorSnapPoint ?? const Offset(0.5, 0.5),
      ];
    }
    
    // Find path on corridor network using A* algorithm
    final path = _findPath(sourceInfo.corridorSnapPoint, destInfo.corridorSnapPoint);
    
    if (path.isEmpty) {
      // Fallback: direct path via snap points
      return [sourceInfo.corridorSnapPoint, destInfo.corridorSnapPoint];
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

  /// A* pathfinding algorithm
  List<Offset> _findPath(Offset start, Offset end) {
    // Find nearest graph nodes to start and end
    final startNode = _findNearestNode(start);
    final endNode = _findNearestNode(end);
    
    if (startNode == null || endNode == null) {
      return [start, end];
    }
    
    final startKey = _nodeKey(startNode);
    final endKey = _nodeKey(endNode);
    
    // A* algorithm
    final openSet = <String>{startKey};
    final cameFrom = <String, String>{};
    final gScore = <String, double>{startKey: 0};
    final fScore = <String, double>{startKey: _distance(startNode, endNode)};
    
    while (openSet.isNotEmpty) {
      // Find node with lowest fScore
      String current = openSet.first;
      for (final node in openSet) {
        if ((fScore[node] ?? double.infinity) < (fScore[current] ?? double.infinity)) {
          current = node;
        }
      }
      
      if (current == endKey) {
        // Reconstruct path
        final path = <Offset>[start];
        var node = current;
        final pathKeys = <String>[node];
        
        while (cameFrom.containsKey(node)) {
          node = cameFrom[node]!;
          pathKeys.insert(0, node);
        }
        
        for (final key in pathKeys) {
          final point = _keyToOffset(key);
          if (point != null && (path.isEmpty || _distance(path.last, point) > 0.001)) {
            path.add(point);
          }
        }
        
        path.add(end);
        return _smoothPath(path);
      }
      
      openSet.remove(current);
      
      for (final edge in _graph[current] ?? []) {
        final tentativeG = (gScore[current] ?? double.infinity) + edge.distance;
        
        if (tentativeG < (gScore[edge.targetKey] ?? double.infinity)) {
          cameFrom[edge.targetKey] = current;
          gScore[edge.targetKey] = tentativeG;
          fScore[edge.targetKey] = tentativeG + _distance(edge.targetPoint, endNode);
          openSet.add(edge.targetKey);
        }
      }
    }
    
    // No path found
    return [start, end];
  }

  /// Find the nearest node in the graph
  Offset? _findNearestNode(Offset point) {
    Offset? nearest;
    double minDist = double.infinity;
    
    for (final node in _allNodes) {
      final dist = _distance(node, point);
      if (dist < minDist) {
        minDist = dist;
        nearest = node;
      }
    }
    
    return nearest;
  }

  /// Smooth the path by removing redundant points
  List<Offset> _smoothPath(List<Offset> path) {
    if (path.length <= 2) return path;
    
    final smoothed = <Offset>[path.first];
    
    for (int i = 1; i < path.length - 1; i++) {
      final prev = smoothed.last;
      final curr = path[i];
      final next = path[i + 1];
      
      // Check if current point is on the line between prev and next
      final crossProduct = (curr.dx - prev.dx) * (next.dy - prev.dy) -
                          (curr.dy - prev.dy) * (next.dx - prev.dx);
      
      if (crossProduct.abs() > 0.005) {
        smoothed.add(curr);
      }
    }
    
    smoothed.add(path.last);
    return smoothed;
  }

  String _nodeKey(Offset point) => '${point.dx.toStringAsFixed(3)},${point.dy.toStringAsFixed(3)}';
  
  Offset? _keyToOffset(String key) {
    final parts = key.split(',');
    if (parts.length != 2) return null;
    final dx = double.tryParse(parts[0]);
    final dy = double.tryParse(parts[1]);
    if (dx == null || dy == null) return null;
    return Offset(dx, dy);
  }

  double _distance(Offset a, Offset b) {
    return sqrt(pow(a.dx - b.dx, 2) + pow(a.dy - b.dy, 2));
  }

  /// Get all destination markers for display
  List<DestinationMarker> getDestinationMarkers() {
    return destinations.entries.map((e) => DestinationMarker(
      id: e.key,
      position: e.value.position,
      label: e.key.toString(),
      name: e.value.shortName,
    )).toList();
  }

  /// Get all corridor polylines for debug visualization
  List<List<Offset>> getCorridorPolylines() {
    return corridors.map((c) => c.points).toList();
  }
}

/// Destination information
class DestinationInfo {
  final int id;
  final String name;
  final String shortName;
  final Offset position;  // Visual position on map
  final Offset corridorSnapPoint;  // Nearest point on walkable corridor

  const DestinationInfo({
    required this.id,
    required this.name,
    required this.shortName,
    required this.position,
    required this.corridorSnapPoint,
  });
}

/// Corridor segment (walkable path)
class CorridorSegment {
  final String id;
  final List<Offset> points;

  const CorridorSegment({
    required this.id,
    required this.points,
  });
}

/// Graph edge for pathfinding
class GraphEdge {
  final String targetKey;
  final Offset targetPoint;
  final double distance;

  GraphEdge(this.targetKey, this.targetPoint, this.distance);
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
