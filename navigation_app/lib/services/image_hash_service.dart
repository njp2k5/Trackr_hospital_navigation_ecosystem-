import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// Service for image hashing and matching against reference images.
/// Uses average hash (aHash) for perceptual image comparison.
class ImageHashService {
  static final ImageHashService _instance = ImageHashService._internal();
  factory ImageHashService() => _instance;
  ImageHashService._internal();

  // Reference images mapping: hash -> destination info
  final Map<String, ReferenceImage> _referenceImages = {};
  bool _isInitialized = false;

  /// Reference image definitions - add your reference images here
  /// Format: asset path -> (destination name, location tag)
  static const Map<String, Map<String, String>> _referenceImageDefs = {
    'assets/reference_images/badminton_court.jpeg': {
      'name': 'Badminton Court',
      'tag': 'BADMINTON_COURT',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/basketball_court.jpeg': {
      'name': 'Basketball Court',
      'tag': 'BASKETBALL_COURT',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/block_a.jpeg': {
      'name': 'Block A',
      'tag': 'BLOCK_A',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/block_d.jpeg': {
      'name': 'Block D',
      'tag': 'BLOCK_D',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/canteen.jpeg': {
      'name': 'Canteen',
      'tag': 'CANTEEN',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/casting_hard.jpeg': {
      'name': 'Casting Hard',
      'tag': 'CASTING_HARD',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/kuppiveed.jpeg': {
      'name': 'Kuppiveed',
      'tag': 'KUPPIVEED',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/parking_area.jpeg': {
      'name': 'Parking Area',
      'tag': 'PARKING_AREA',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/playground.jpeg': {
      'name': 'Playground',
      'tag': 'PLAYGROUND',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/small_pond.jpeg': {
      'name': 'Small Pond',
      'tag': 'SMALL_POND',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/staff_parking_area.jpeg': {
      'name': 'Staff Parking Area',
      'tag': 'STAFF_PARKING_AREA',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/student_parking_area.jpeg': {
      'name': 'Student Parking Area',
      'tag': 'STUDENT_PARKING_AREA',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/volleyball_court.jpeg': {
      'name': 'Volleyball Court',
      'tag': 'VOLLEYBALL_COURT',
      'floor': 'Ground Floor',
    },
    'assets/reference_images/workshop.jpeg': {
      'name': 'Workshop',
      'tag': 'WORKSHOP',
      'floor': 'Ground Floor',
    },
  };

  /// Initialize the service by loading and hashing all reference images
  Future<void> initialize() async {
    if (_isInitialized) return;

    for (final entry in _referenceImageDefs.entries) {
      try {
        final ByteData data = await rootBundle.load(entry.key);
        final Uint8List bytes = data.buffer.asUint8List();
        final hash = _computeAverageHash(bytes);
        
        if (hash != null) {
          _referenceImages[hash] = ReferenceImage(
            assetPath: entry.key,
            destinationName: entry.value['name']!,
            tag: entry.value['tag']!,
            floor: entry.value['floor']!,
            hash: hash,
          );
        }
      } catch (e) {
        // Reference image not found - skip silently
        // In production, you'd want to log this
      }
    }

    _isInitialized = true;
  }

  /// Compute average hash (aHash) for an image
  String? _computeAverageHash(Uint8List imageBytes) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Resize to 8x8
      final resized = img.copyResize(image, width: 8, height: 8);
      
      // Convert to grayscale
      final grayscale = img.grayscale(resized);

      // Calculate average pixel value
      int sum = 0;
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final pixel = grayscale.getPixel(x, y);
          sum += img.getLuminance(pixel).toInt();
        }
      }
      final average = sum ~/ 64;

      // Build hash string
      final StringBuffer hashBuffer = StringBuffer();
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final pixel = grayscale.getPixel(x, y);
          final luminance = img.getLuminance(pixel).toInt();
          hashBuffer.write(luminance >= average ? '1' : '0');
        }
      }

      return hashBuffer.toString();
    } catch (e) {
      return null;
    }
  }

  /// Calculate Hamming distance between two hashes
  int _hammingDistance(String hash1, String hash2) {
    if (hash1.length != hash2.length) return 64; // Max distance
    
    int distance = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] != hash2[i]) distance++;
    }
    return distance;
  }

  /// Match an uploaded image against reference images
  /// Returns the best match if similarity is above threshold
  Future<MatchResult?> matchImage(File imageFile) async {
    await initialize();

    final bytes = await imageFile.readAsBytes();
    final uploadedHash = _computeAverageHash(bytes);
    
    if (uploadedHash == null) return null;

    ReferenceImage? bestMatch;
    int bestDistance = 64; // Max possible distance for 64-bit hash
    const int threshold = 12; // Allow up to 12 bits difference (~80% similar)

    for (final ref in _referenceImages.values) {
      final distance = _hammingDistance(uploadedHash, ref.hash);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestMatch = ref;
      }
    }

    if (bestMatch != null && bestDistance <= threshold) {
      final similarity = ((64 - bestDistance) / 64 * 100).round();
      return MatchResult(
        referenceImage: bestMatch,
        similarity: similarity,
        distance: bestDistance,
      );
    }

    return null;
  }

  /// Get all available destinations
  List<String> getAvailableDestinations() {
    return _referenceImageDefs.values
        .map((v) => v['name']!)
        .toList();
  }

  /// Find destination by name
  ReferenceImage? findByName(String name) {
    for (final ref in _referenceImages.values) {
      if (ref.destinationName.toLowerCase() == name.toLowerCase()) {
        return ref;
      }
    }
    return null;
  }
}

class ReferenceImage {
  final String assetPath;
  final String destinationName;
  final String tag;
  final String floor;
  final String hash;

  const ReferenceImage({
    required this.assetPath,
    required this.destinationName,
    required this.tag,
    required this.floor,
    required this.hash,
  });
}

class MatchResult {
  final ReferenceImage referenceImage;
  final int similarity;
  final int distance;

  const MatchResult({
    required this.referenceImage,
    required this.similarity,
    required this.distance,
  });
}
