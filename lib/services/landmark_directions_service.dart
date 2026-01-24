import 'package:flutter/material.dart';

/// Model for a single direction step with landmark information
class LandmarkDirectionStep {
  final int stepNumber;
  final String instruction;
  final String instructionMalayalam;
  final String? landmark;
  final String? landmarkMalayalam;
  final IconData icon;
  final double? distanceMeters;
  final String? floor;

  const LandmarkDirectionStep({
    required this.stepNumber,
    required this.instruction,
    required this.instructionMalayalam,
    this.landmark,
    this.landmarkMalayalam,
    required this.icon,
    this.distanceMeters,
    this.floor,
  });
}

/// Model for complete landmark-based route
class LandmarkRoute {
  final String source;
  final String sourceMalayalam;
  final String destination;
  final String destinationMalayalam;
  final List<LandmarkDirectionStep> steps;
  final double totalDistanceMeters;
  final int estimatedTimeMinutes;
  final bool isWheelchairFriendly;

  const LandmarkRoute({
    required this.source,
    required this.sourceMalayalam,
    required this.destination,
    required this.destinationMalayalam,
    required this.steps,
    required this.totalDistanceMeters,
    required this.estimatedTimeMinutes,
    this.isWheelchairFriendly = false,
  });
}

/// Service for generating landmark-based directions
/// Provides human-readable directions using landmarks as reference points
class LandmarkDirectionsService {
  static final LandmarkDirectionsService _instance = LandmarkDirectionsService._internal();
  factory LandmarkDirectionsService() => _instance;
  LandmarkDirectionsService._internal();

  /// Demo landmark routes for various destinations
  /// In production, this would be generated dynamically based on the graph
  static final Map<String, Map<String, LandmarkRoute>> _demoRoutes = {
    // From Main Entrance
    'Main Entrance': {
      'Block A': _createBlockARoute(),
      'Block D': _createBlockDRoute(),
      'Canteen': _createCanteenRoute(),
      'Emergency': _createEmergencyRoute(),
      'Pharmacy': _createPharmacyRoute(),
      'Radiology': _createRadiologyRoute(),
      'OPD': _createOPDRoute(),
      'ICU': _createICURoute(),
    },
    // From any other location, return a generic route for demo
  };

  /// Get landmark-based directions for a route
  LandmarkRoute getDirections({
    required String source,
    required String destination,
    bool isWheelchairFriendly = false,
  }) {
    // Normalize input
    final normalizedSource = _normalizeLocationName(source);
    final normalizedDest = _normalizeLocationName(destination);
    
    // Try to find a predefined route
    if (_demoRoutes.containsKey(normalizedSource)) {
      final routes = _demoRoutes[normalizedSource]!;
      if (routes.containsKey(normalizedDest)) {
        return routes[normalizedDest]!;
      }
    }
    
    // Return a generic demo route for any other combination
    return _createGenericRoute(source, destination, isWheelchairFriendly);
  }

  /// Get all available destinations for demo
  List<String> getAvailableDestinations() {
    return [
      'Block A',
      'Block D',
      'Canteen',
      'Emergency',
      'Pharmacy',
      'Radiology',
      'OPD',
      'ICU',
      'Laboratory',
      'X-Ray',
      'Cardiology',
      'Pediatrics',
      'Maternity',
      'Surgery',
      'General Ward',
    ];
  }

  String _normalizeLocationName(String name) {
    final lower = name.toLowerCase().trim();
    
    // Map common variations to standard names
    if (lower.contains('entrance') || lower.contains('gate')) {
      return 'Main Entrance';
    }
    if (lower.contains('block a') || lower.contains('admin')) {
      return 'Block A';
    }
    if (lower.contains('block d') || lower.contains('department')) {
      return 'Block D';
    }
    if (lower.contains('canteen') || lower.contains('cafeteria') || lower.contains('food')) {
      return 'Canteen';
    }
    if (lower.contains('emergency') || lower.contains('er') || lower.contains('casualty')) {
      return 'Emergency';
    }
    if (lower.contains('pharmacy') || lower.contains('medicine') || lower.contains('drug')) {
      return 'Pharmacy';
    }
    if (lower.contains('radiology') || lower.contains('scan') || lower.contains('mri')) {
      return 'Radiology';
    }
    if (lower.contains('opd') || lower.contains('outpatient')) {
      return 'OPD';
    }
    if (lower.contains('icu') || lower.contains('intensive')) {
      return 'ICU';
    }
    
    return name;
  }

  // ============================================================
  // DEMO ROUTE DEFINITIONS
  // ============================================================

  static LandmarkRoute _createBlockARoute() {
    return LandmarkRoute(
      source: 'Main Entrance',
      sourceMalayalam: 'പ്രധാന പ്രവേശന കവാടം',
      destination: 'Block A / Administrative Block',
      destinationMalayalam: 'ബ്ലോക്ക് എ / അഡ്മിനിസ്ട്രേറ്റീവ് ബ്ലോക്ക്',
      totalDistanceMeters: 150,
      estimatedTimeMinutes: 3,
      steps: [
        LandmarkDirectionStep(
          stepNumber: 1,
          instruction: 'Enter through the main gate and walk straight ahead',
          instructionMalayalam: 'പ്രധാന ഗേറ്റിലൂടെ അകത്തു കയറി നേരെ നടക്കുക',
          landmark: 'Security Guard Post on your right',
          landmarkMalayalam: 'സെക്യൂരിറ്റി ഗാർഡ് പോസ്റ്റ് നിങ്ങളുടെ വലതുവശത്ത്',
          icon: Icons.straight,
          distanceMeters: 30,
        ),
        LandmarkDirectionStep(
          stepNumber: 2,
          instruction: 'Continue past the large banyan tree on your left',
          instructionMalayalam: 'നിങ്ങളുടെ ഇടതുവശത്തുള്ള വലിയ ആൽമരം കടന്ന് തുടരുക',
          landmark: 'Big Banyan Tree with circular seating',
          landmarkMalayalam: 'വൃത്താകൃതിയിലുള്ള ഇരിപ്പിടമുള്ള വലിയ ആൽമരം',
          icon: Icons.park,
          distanceMeters: 40,
        ),
        LandmarkDirectionStep(
          stepNumber: 3,
          instruction: 'At the fountain, turn right towards the large white building',
          instructionMalayalam: 'ജലധാരയിൽ, വലിയ വെള്ള കെട്ടിടത്തിലേക്ക് വലത്തോട്ട് തിരിയുക',
          landmark: 'Central Fountain with hospital logo',
          landmarkMalayalam: 'ആശുപത്രി ലോഗോയുള്ള മധ്യ ജലധാര',
          icon: Icons.turn_right,
          distanceMeters: 25,
        ),
        LandmarkDirectionStep(
          stepNumber: 4,
          instruction: 'Walk along the covered walkway with blue pillars',
          instructionMalayalam: 'നീല തൂണുകളുള്ള മറഞ്ഞ നടപ്പാതയിലൂടെ നടക്കുക',
          landmark: 'Blue-pillared covered corridor',
          landmarkMalayalam: 'നീല തൂണുകളുള്ള മറഞ്ഞ ഇടനാഴി',
          icon: Icons.straight,
          distanceMeters: 35,
        ),
        LandmarkDirectionStep(
          stepNumber: 5,
          instruction: 'Block A is the 3-story building with glass entrance on your right',
          instructionMalayalam: 'ബ്ലോക്ക് എ നിങ്ങളുടെ വലതുവശത്ത് ഗ്ലാസ് പ്രവേശന ദ്വാരമുള്ള 3 നില കെട്ടിടമാണ്',
          landmark: 'Building with "BLOCK A - ADMINISTRATION" sign',
          landmarkMalayalam: '"ബ്ലോക്ക് എ - അഡ്മിനിസ്ട്രേഷൻ" സൈൻബോർഡുള്ള കെട്ടിടം',
          icon: Icons.location_on,
          distanceMeters: 20,
        ),
      ],
    );
  }

  static LandmarkRoute _createBlockDRoute() {
    return LandmarkRoute(
      source: 'Main Entrance',
      sourceMalayalam: 'പ്രധാന പ്രവേശന കവാടം',
      destination: 'Block D / Department Block',
      destinationMalayalam: 'ബ്ലോക്ക് ഡി / ഡിപ്പാർട്ട്മെന്റ് ബ്ലോക്ക്',
      totalDistanceMeters: 180,
      estimatedTimeMinutes: 4,
      steps: [
        LandmarkDirectionStep(
          stepNumber: 1,
          instruction: 'Enter through the main gate and walk straight',
          instructionMalayalam: 'പ്രധാന ഗേറ്റിലൂടെ അകത്തു കയറി നേരെ നടക്കുക',
          landmark: 'Security Guard Post',
          landmarkMalayalam: 'സെക്യൂരിറ്റി ഗാർഡ് പോസ്റ്റ്',
          icon: Icons.straight,
          distanceMeters: 30,
        ),
        LandmarkDirectionStep(
          stepNumber: 2,
          instruction: 'At the fountain, turn left',
          instructionMalayalam: 'ജലധാരയിൽ, ഇടത്തോട്ട് തിരിയുക',
          landmark: 'Central Fountain',
          landmarkMalayalam: 'മധ്യ ജലധാര',
          icon: Icons.turn_left,
          distanceMeters: 40,
        ),
        LandmarkDirectionStep(
          stepNumber: 3,
          instruction: 'Continue past the garden with benches',
          instructionMalayalam: 'ബെഞ്ചുകളുള്ള പൂന്തോട്ടം കടന്ന് തുടരുക',
          landmark: 'Seating garden with flower beds',
          landmarkMalayalam: 'പൂക്കളുള്ള ഇരിപ്പിട പൂന്തോട്ടം',
          icon: Icons.nature,
          distanceMeters: 50,
        ),
        LandmarkDirectionStep(
          stepNumber: 4,
          instruction: 'Walk towards the brown building ahead',
          instructionMalayalam: 'മുന്നിലുള്ള തവിട്ട് നിറമുള്ള കെട്ടിടത്തിലേക്ക് നടക്കുക',
          landmark: 'Information kiosk near pathway',
          landmarkMalayalam: 'പാതയ്ക്ക് സമീപമുള്ള വിവര കിയോസ്ക്',
          icon: Icons.straight,
          distanceMeters: 40,
        ),
        LandmarkDirectionStep(
          stepNumber: 5,
          instruction: 'Block D is the building with red entrance doors',
          instructionMalayalam: 'ബ്ലോക്ക് ഡി ചുവന്ന പ്രവേശന വാതിലുകളുള്ള കെട്ടിടമാണ്',
          landmark: 'Building marked "BLOCK D - DEPARTMENTS"',
          landmarkMalayalam: '"ബ്ലോക്ക് ഡി - ഡിപ്പാർട്ട്മെന്റ്സ്" എന്ന് അടയാളപ്പെടുത്തിയ കെട്ടിടം',
          icon: Icons.location_on,
          distanceMeters: 20,
        ),
      ],
    );
  }

  static LandmarkRoute _createCanteenRoute() {
    return LandmarkRoute(
      source: 'Main Entrance',
      sourceMalayalam: 'പ്രധാന പ്രവേശന കവാടം',
      destination: 'Canteen',
      destinationMalayalam: 'കാന്റീൻ',
      totalDistanceMeters: 120,
      estimatedTimeMinutes: 2,
      steps: [
        LandmarkDirectionStep(
          stepNumber: 1,
          instruction: 'Enter through main gate and take the right path',
          instructionMalayalam: 'പ്രധാന ഗേറ്റിലൂടെ അകത്തു കയറി വലത്തേ പാത എടുക്കുക',
          landmark: 'Parking lot on your right',
          landmarkMalayalam: 'പാർക്കിംഗ് സ്ഥലം നിങ്ങളുടെ വലതുവശത്ത്',
          icon: Icons.turn_right,
          distanceMeters: 25,
        ),
        LandmarkDirectionStep(
          stepNumber: 2,
          instruction: 'Follow the path past the small garden',
          instructionMalayalam: 'ചെറിയ പൂന്തോട്ടം കടന്ന് പാത പിന്തുടരുക',
          landmark: 'Rose garden with sitting area',
          landmarkMalayalam: 'ഇരിപ്പിട സ്ഥലമുള്ള റോസ് പൂന്തോട്ടം',
          icon: Icons.straight,
          distanceMeters: 35,
        ),
        LandmarkDirectionStep(
          stepNumber: 3,
          instruction: 'You will smell the food from here! Continue straight',
          instructionMalayalam: 'ഇവിടെ നിന്ന് ഭക്ഷണത്തിന്റെ മണം അനുഭവപ്പെടും! നേരെ തുടരുക',
          landmark: 'Food aroma and seating visible ahead',
          landmarkMalayalam: 'ഭക്ഷണത്തിന്റെ സുഗന്ധവും മുന്നിൽ ഇരിപ്പിടങ്ങളും കാണാം',
          icon: Icons.restaurant,
          distanceMeters: 40,
        ),
        LandmarkDirectionStep(
          stepNumber: 4,
          instruction: 'Canteen is the open-air building with metal roof',
          instructionMalayalam: 'കാന്റീൻ ലോഹ മേൽക്കൂരയുള്ള തുറന്ന കെട്ടിടമാണ്',
          landmark: 'Building with "CANTEEN" board and outdoor tables',
          landmarkMalayalam: '"കാന്റീൻ" ബോർഡും പുറത്ത് മേശകളുമുള്ള കെട്ടിടം',
          icon: Icons.location_on,
          distanceMeters: 20,
        ),
      ],
    );
  }

  static LandmarkRoute _createEmergencyRoute() {
    return LandmarkRoute(
      source: 'Main Entrance',
      sourceMalayalam: 'പ്രധാന പ്രവേശന കവാടം',
      destination: 'Emergency Department',
      destinationMalayalam: 'എമർജൻസി വിഭാഗം',
      totalDistanceMeters: 80,
      estimatedTimeMinutes: 1,
      steps: [
        LandmarkDirectionStep(
          stepNumber: 1,
          instruction: 'Enter through main gate - Emergency is clearly marked with red signs',
          instructionMalayalam: 'പ്രധാന ഗേറ്റിലൂടെ അകത്തു കയറുക - എമർജൻസി ചുവന്ന അടയാളങ്ങളാൽ വ്യക്തമായി അടയാളപ്പെടുത്തിയിരിക്കുന്നു',
          landmark: 'Red "EMERGENCY" signs pointing left',
          landmarkMalayalam: 'ഇടത്തോട്ട് ചൂണ്ടുന്ന ചുവന്ന "എമർജൻസി" അടയാളങ്ങൾ',
          icon: Icons.arrow_forward,
          distanceMeters: 20,
        ),
        LandmarkDirectionStep(
          stepNumber: 2,
          instruction: 'Turn left immediately and follow the red floor markings',
          instructionMalayalam: 'ഉടനെ ഇടത്തോട്ട് തിരിഞ്ഞ് ചുവന്ന നിലം അടയാളങ്ങൾ പിന്തുടരുക',
          landmark: 'Red painted pathway on ground',
          landmarkMalayalam: 'നിലത്ത് ചുവന്ന ചായം പൂശിയ പാത',
          icon: Icons.turn_left,
          distanceMeters: 30,
        ),
        LandmarkDirectionStep(
          stepNumber: 3,
          instruction: 'Emergency entrance is the building with ambulance parking',
          instructionMalayalam: 'എമർജൻസി പ്രവേശനം ആംബുലൻസ് പാർക്കിംഗുള്ള കെട്ടിടമാണ്',
          landmark: 'White building with red cross and ambulances',
          landmarkMalayalam: 'ചുവന്ന കുരിശും ആംബുലൻസുകളുമുള്ള വെള്ള കെട്ടിടം',
          icon: Icons.local_hospital,
          distanceMeters: 30,
        ),
      ],
    );
  }

  static LandmarkRoute _createPharmacyRoute() {
    return LandmarkRoute(
      source: 'Main Entrance',
      sourceMalayalam: 'പ്രധാന പ്രവേശന കവാടം',
      destination: 'Pharmacy',
      destinationMalayalam: 'ഫാർമസി',
      totalDistanceMeters: 100,
      estimatedTimeMinutes: 2,
      steps: [
        LandmarkDirectionStep(
          stepNumber: 1,
          instruction: 'Enter through main gate and walk straight',
          instructionMalayalam: 'പ്രധാന ഗേറ്റിലൂടെ അകത്തു കയറി നേരെ നടക്കുക',
          landmark: 'Reception building ahead',
          landmarkMalayalam: 'മുന്നിൽ റിസപ്ഷൻ കെട്ടിടം',
          icon: Icons.straight,
          distanceMeters: 40,
        ),
        LandmarkDirectionStep(
          stepNumber: 2,
          instruction: 'Enter the main reception building through glass doors',
          instructionMalayalam: 'ഗ്ലാസ് വാതിലുകളിലൂടെ പ്രധാന റിസപ്ഷൻ കെട്ടിടത്തിൽ പ്രവേശിക്കുക',
          landmark: 'Glass entrance with "RECEPTION" sign',
          landmarkMalayalam: '"റിസപ്ഷൻ" സൈൻബോർഡുള്ള ഗ്ലാസ് പ്രവേശന കവാടം',
          icon: Icons.meeting_room,
          distanceMeters: 10,
        ),
        LandmarkDirectionStep(
          stepNumber: 3,
          instruction: 'Turn right after entering, pharmacy is at the end of corridor',
          instructionMalayalam: 'അകത്തു കയറിയ ശേഷം വലത്തോട്ട് തിരിയുക, ഇടനാഴിയുടെ അവസാനം ഫാർമസി',
          landmark: 'Green cross sign and medicine smell',
          landmarkMalayalam: 'പച്ച കുരിശ് അടയാളവും മരുന്നിന്റെ മണവും',
          icon: Icons.turn_right,
          distanceMeters: 30,
        ),
        LandmarkDirectionStep(
          stepNumber: 4,
          instruction: 'Pharmacy counter is on your left with token system',
          instructionMalayalam: 'ഫാർമസി കൌണ്ടർ ടോക്കൺ സിസ്റ്റത്തോടെ നിങ്ങളുടെ ഇടതുവശത്താണ്',
          landmark: 'Counter with "PHARMACY" sign and token display',
          landmarkMalayalam: '"ഫാർമസി" സൈൻബോർഡും ടോക്കൺ ഡിസ്‌പ്ലേയുമുള്ള കൌണ്ടർ',
          icon: Icons.medication,
          distanceMeters: 20,
        ),
      ],
    );
  }

  static LandmarkRoute _createRadiologyRoute() {
    return LandmarkRoute(
      source: 'Main Entrance',
      sourceMalayalam: 'പ്രധാന പ്രവേശന കവാടം',
      destination: 'Radiology Department',
      destinationMalayalam: 'റേഡിയോളജി വിഭാഗം',
      totalDistanceMeters: 200,
      estimatedTimeMinutes: 4,
      steps: [
        LandmarkDirectionStep(
          stepNumber: 1,
          instruction: 'Enter through main gate and head to the main building',
          instructionMalayalam: 'പ്രധാന ഗേറ്റിലൂടെ അകത്തു കയറി പ്രധാന കെട്ടിടത്തിലേക്ക് പോകുക',
          landmark: 'Main hospital building with clock tower',
          landmarkMalayalam: 'ക്ലോക്ക് ടവറുള്ള പ്രധാന ആശുപത്രി കെട്ടിടം',
          icon: Icons.straight,
          distanceMeters: 50,
        ),
        LandmarkDirectionStep(
          stepNumber: 2,
          instruction: 'Enter building and take the elevator to Basement Level 1',
          instructionMalayalam: 'കെട്ടിടത്തിൽ പ്രവേശിച്ച് ബേസ്‌മെന്റ് ലെവൽ 1 ലേക്ക് എലിവേറ്റർ എടുക്കുക',
          landmark: 'Elevator lobby near reception',
          landmarkMalayalam: 'റിസപ്ഷനു സമീപമുള്ള എലിവേറ്റർ ലോബി',
          icon: Icons.elevator,
          distanceMeters: 30,
          floor: 'B1',
        ),
        LandmarkDirectionStep(
          stepNumber: 3,
          instruction: 'Exit elevator and turn left',
          instructionMalayalam: 'എലിവേറ്ററിൽ നിന്ന് ഇറങ്ങി ഇടത്തോട്ട് തിരിയുക',
          landmark: 'Blue floor markings for Radiology',
          landmarkMalayalam: 'റേഡിയോളജിക്കുള്ള നീല നില അടയാളങ്ങൾ',
          icon: Icons.turn_left,
          distanceMeters: 10,
        ),
        LandmarkDirectionStep(
          stepNumber: 4,
          instruction: 'Follow corridor past the waiting area',
          instructionMalayalam: 'കാത്തിരിപ്പ് സ്ഥലം കടന്ന് ഇടനാഴി പിന്തുടരുക',
          landmark: 'Waiting room with TV screens',
          landmarkMalayalam: 'ടിവി സ്ക്രീനുകളുള്ള കാത്തിരിപ്പ് മുറി',
          icon: Icons.straight,
          distanceMeters: 60,
        ),
        LandmarkDirectionStep(
          stepNumber: 5,
          instruction: 'Radiology reception is at the end with X-ray and MRI signs',
          instructionMalayalam: 'എക്സ്-റേ, എംആർഐ അടയാളങ്ങളോടെ അവസാനം റേഡിയോളജി റിസപ്ഷൻ',
          landmark: 'Counter with "RADIOLOGY" and radiation symbol',
          landmarkMalayalam: '"റേഡിയോളജി" എഴുത്തും റേഡിയേഷൻ ചിഹ്നവുമുള്ള കൌണ്ടർ',
          icon: Icons.location_on,
          distanceMeters: 50,
        ),
      ],
    );
  }

  static LandmarkRoute _createOPDRoute() {
    return LandmarkRoute(
      source: 'Main Entrance',
      sourceMalayalam: 'പ്രധാന പ്രവേശന കവാടം',
      destination: 'OPD (Out Patient Department)',
      destinationMalayalam: 'ഒപിഡി (ഔട്ട് പേഷ്യന്റ് വിഭാഗം)',
      totalDistanceMeters: 60,
      estimatedTimeMinutes: 1,
      steps: [
        LandmarkDirectionStep(
          stepNumber: 1,
          instruction: 'Enter through main gate - OPD is in the first building on your right',
          instructionMalayalam: 'പ്രധാന ഗേറ്റിലൂടെ അകത്തു കയറുക - ഒപിഡി നിങ്ങളുടെ വലതുവശത്തെ ആദ്യ കെട്ടിടത്തിലാണ്',
          landmark: 'Large OPD signboard visible from gate',
          landmarkMalayalam: 'ഗേറ്റിൽ നിന്ന് കാണാവുന്ന വലിയ ഒപിഡി സൈൻബോർഡ്',
          icon: Icons.straight,
          distanceMeters: 30,
        ),
        LandmarkDirectionStep(
          stepNumber: 2,
          instruction: 'Enter through the wide automatic doors',
          instructionMalayalam: 'വീതിയുള്ള ഓട്ടോമാറ്റിക് വാതിലുകളിലൂടെ അകത്തു കയറുക',
          landmark: 'Glass automatic doors with ramp',
          landmarkMalayalam: 'റാമ്പുള്ള ഗ്ലാസ് ഓട്ടോമാറ്റിക് വാതിലുകൾ',
          icon: Icons.meeting_room,
          distanceMeters: 20,
        ),
        LandmarkDirectionStep(
          stepNumber: 3,
          instruction: 'OPD registration counter is straight ahead',
          instructionMalayalam: 'ഒപിഡി രജിസ്ട്രേഷൻ കൌണ്ടർ നേരെ മുന്നിലാണ്',
          landmark: 'Registration counter with token machine',
          landmarkMalayalam: 'ടോക്കൺ മെഷീനുള്ള രജിസ്ട്രേഷൻ കൌണ്ടർ',
          icon: Icons.location_on,
          distanceMeters: 10,
        ),
      ],
    );
  }

  static LandmarkRoute _createICURoute() {
    return LandmarkRoute(
      source: 'Main Entrance',
      sourceMalayalam: 'പ്രധാന പ്രവേശന കവാടം',
      destination: 'ICU (Intensive Care Unit)',
      destinationMalayalam: 'ഐസിയു (ഇന്റൻസീവ് കെയർ യൂണിറ്റ്)',
      totalDistanceMeters: 180,
      estimatedTimeMinutes: 4,
      steps: [
        LandmarkDirectionStep(
          stepNumber: 1,
          instruction: 'Enter through main gate and go to the main hospital building',
          instructionMalayalam: 'പ്രധാന ഗേറ്റിലൂടെ അകത്തു കയറി പ്രധാന ആശുപത്രി കെട്ടിടത്തിലേക്ക് പോകുക',
          landmark: 'Tall building with blue glass windows',
          landmarkMalayalam: 'നീല ഗ്ലാസ് ജാലകങ്ങളുള്ള ഉയരമുള്ള കെട്ടിടം',
          icon: Icons.straight,
          distanceMeters: 50,
        ),
        LandmarkDirectionStep(
          stepNumber: 2,
          instruction: 'Enter building and take elevator to 2nd floor',
          instructionMalayalam: 'കെട്ടിടത്തിൽ പ്രവേശിച്ച് 2-ാം നിലയിലേക്ക് എലിവേറ്റർ എടുക്കുക',
          landmark: 'Elevator lobby with floor directory',
          landmarkMalayalam: 'ഫ്ലോർ ഡയറക്ടറിയുള്ള എലിവേറ്റർ ലോബി',
          icon: Icons.elevator,
          distanceMeters: 20,
          floor: '2',
        ),
        LandmarkDirectionStep(
          stepNumber: 3,
          instruction: 'Exit elevator and turn right',
          instructionMalayalam: 'എലിവേറ്ററിൽ നിന്ന് ഇറങ്ങി വലത്തോട്ട് തിരിയുക',
          landmark: 'Sign pointing to ICU and Critical Care',
          landmarkMalayalam: 'ഐസിയു, ക്രിട്ടിക്കൽ കെയർ എന്നിവയിലേക്ക് ചൂണ്ടുന്ന അടയാളം',
          icon: Icons.turn_right,
          distanceMeters: 10,
        ),
        LandmarkDirectionStep(
          stepNumber: 4,
          instruction: 'Walk through the restricted access corridor',
          instructionMalayalam: 'നിയന്ത്രിത പ്രവേശന ഇടനാഴിയിലൂടെ നടക്കുക',
          landmark: 'Yellow caution signs and hand sanitizer stations',
          landmarkMalayalam: 'മഞ്ഞ മുന്നറിയിപ്പ് അടയാളങ്ങളും ഹാൻഡ് സാനിറ്റൈസർ സ്റ്റേഷനുകളും',
          icon: Icons.straight,
          distanceMeters: 60,
        ),
        LandmarkDirectionStep(
          stepNumber: 5,
          instruction: 'ICU entrance is the double door with intercom',
          instructionMalayalam: 'ഐസിയു പ്രവേശനം ഇന്റർകോമുള്ള ഇരട്ട വാതിലാണ്',
          landmark: 'Double doors with "ICU - Authorized Personnel Only" sign',
          landmarkMalayalam: '"ഐസിയു - അധികാരപ്പെടുത്തിയ ഉദ്യോഗസ്ഥർക്ക് മാത്രം" എന്ന അടയാളമുള്ള ഇരട്ട വാതിലുകൾ',
          icon: Icons.location_on,
          distanceMeters: 40,
        ),
      ],
    );
  }

  static LandmarkRoute _createGenericRoute(String source, String destination, bool isWheelchairFriendly) {
    return LandmarkRoute(
      source: source,
      sourceMalayalam: _translateToMalayalam(source),
      destination: destination,
      destinationMalayalam: _translateToMalayalam(destination),
      totalDistanceMeters: 150,
      estimatedTimeMinutes: isWheelchairFriendly ? 5 : 3,
      isWheelchairFriendly: isWheelchairFriendly,
      steps: [
        LandmarkDirectionStep(
          stepNumber: 1,
          instruction: 'From your current location, look for the direction signs',
          instructionMalayalam: 'നിങ്ങളുടെ നിലവിലെ സ്ഥലത്ത് നിന്ന്, ദിശ അടയാളങ്ങൾ നോക്കുക',
          landmark: 'Direction board with department names',
          landmarkMalayalam: 'വിഭാഗങ്ങളുടെ പേരുകളുള്ള ദിശ ബോർഡ്',
          icon: Icons.signpost,
          distanceMeters: 10,
        ),
        LandmarkDirectionStep(
          stepNumber: 2,
          instruction: 'Follow the colored floor lines - look for signs to $destination',
          instructionMalayalam: 'നിറമുള്ള നില രേഖകൾ പിന്തുടരുക - ${_translateToMalayalam(destination)} ലേക്കുള്ള അടയാളങ്ങൾ നോക്കുക',
          landmark: 'Color-coded pathway markers',
          landmarkMalayalam: 'നിറം കൊണ്ട് അടയാളപ്പെടുത്തിയ പാത മാർക്കറുകൾ',
          icon: Icons.straight,
          distanceMeters: 50,
        ),
        LandmarkDirectionStep(
          stepNumber: 3,
          instruction: isWheelchairFriendly 
              ? 'Use the elevator or ramp - avoid stairs'
              : 'Continue following the signs',
          instructionMalayalam: isWheelchairFriendly 
              ? 'എലിവേറ്റർ അല്ലെങ്കിൽ റാമ്പ് ഉപയോഗിക്കുക - പടികൾ ഒഴിവാക്കുക'
              : 'അടയാളങ്ങൾ പിന്തുടർന്ന് തുടരുക',
          landmark: isWheelchairFriendly 
              ? 'Wheelchair accessible elevator' 
              : 'Information desk for assistance',
          landmarkMalayalam: isWheelchairFriendly 
              ? 'വീൽചെയർ പ്രാപ്യമായ എലിവേറ്റർ' 
              : 'സഹായത്തിനുള്ള വിവര ഡെസ്ക്',
          icon: isWheelchairFriendly ? Icons.accessible : Icons.info,
          distanceMeters: 40,
        ),
        LandmarkDirectionStep(
          stepNumber: 4,
          instruction: 'Ask staff if needed - they can guide you to $destination',
          instructionMalayalam: 'ആവശ്യമെങ്കിൽ ജീവനക്കാരോട് ചോദിക്കുക - അവർ നിങ്ങളെ ${_translateToMalayalam(destination)} ലേക്ക് നയിക്കും',
          landmark: 'Staff members in hospital uniform',
          landmarkMalayalam: 'ആശുപത്രി യൂണിഫോമിലുള്ള ജീവനക്കാർ',
          icon: Icons.support_agent,
          distanceMeters: 20,
        ),
        LandmarkDirectionStep(
          stepNumber: 5,
          instruction: 'You have arrived at $destination',
          instructionMalayalam: 'നിങ്ങൾ ${_translateToMalayalam(destination)} ൽ എത്തിച്ചേർന്നു',
          landmark: 'Department entrance with name board',
          landmarkMalayalam: 'പേര് ബോർഡുള്ള വിഭാഗ പ്രവേശന കവാടം',
          icon: Icons.location_on,
          distanceMeters: 30,
        ),
      ],
    );
  }

  static String _translateToMalayalam(String text) {
    // Common hospital terms translation map
    const translations = {
      'Main Entrance': 'പ്രധാന പ്രവേശന കവാടം',
      'Emergency': 'എമർജൻസി',
      'Pharmacy': 'ഫാർമസി',
      'OPD': 'ഒപിഡി',
      'ICU': 'ഐസിയു',
      'Radiology': 'റേഡിയോളജി',
      'Canteen': 'കാന്റീൻ',
      'Block A': 'ബ്ലോക്ക് എ',
      'Block B': 'ബ്ലോക്ക് ബി',
      'Block C': 'ബ്ലോക്ക് സി',
      'Block D': 'ബ്ലോക്ക് ഡി',
      'Laboratory': 'ലബോറട്ടറി',
      'X-Ray': 'എക്സ്-റേ',
      'Cardiology': 'കാർഡിയോളജി',
      'Pediatrics': 'പീഡിയാട്രിക്സ്',
      'Maternity': 'മെറ്റേണിറ്റി',
      'Surgery': 'സർജറി',
      'General Ward': 'ജനറൽ വാർഡ്',
      'Reception': 'റിസപ്ഷൻ',
      'Parking': 'പാർക്കിംഗ്',
      'Elevator': 'എലിവേറ്റർ',
      'Stairs': 'പടികൾ',
      'Toilet': 'ടോയ്‌ലറ്റ്',
      'Waiting Area': 'കാത്തിരിപ്പ് സ്ഥലം',
    };
    
    // Check for exact match
    if (translations.containsKey(text)) {
      return translations[text]!;
    }
    
    // Check for partial match
    for (final entry in translations.entries) {
      if (text.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    // Return original with Malayalam transliteration indicator
    return text;
  }
}
