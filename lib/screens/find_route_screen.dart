import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hospital_nav_app/services/image_hash_service.dart';
import 'package:hospital_nav_app/screens/route_display_screen.dart';
import 'package:hospital_nav_app/screens/landmark_directions_screen.dart';

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
  static const Color accent2 = Color(0xFF8B5CF6);
}

class FindRouteScreen extends StatefulWidget {
  const FindRouteScreen({super.key});

  @override
  State<FindRouteScreen> createState() => _FindRouteScreenState();
}

class _FindRouteScreenState extends State<FindRouteScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _currentLocationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ImageHashService _hashService = ImageHashService();
  
  // Current location state
  File? _selectedCurrentLocationImage;
  bool _isProcessingCurrentLocation = false;
  MatchResult? _currentLocationMatchResult;
  String _currentLocation = 'Unknown';
  
  bool _wheelchairFriendly = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _hashService.initialize();
    } catch (e) {
      // Service initialization failed - will work without reference images
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _currentLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedCurrentLocationImage = File(pickedFile.path);
          _isProcessingCurrentLocation = true;
          _currentLocationMatchResult = null;
        });
        await _processCurrentLocationImage();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _processCurrentLocationImage() async {
    if (_selectedCurrentLocationImage == null) return;

    try {
      final result = await _hashService.matchImage(_selectedCurrentLocationImage!);
      
      setState(() {
        _currentLocationMatchResult = result;
        _isProcessingCurrentLocation = false;
        if (result != null) {
          _currentLocation = result.referenceImage.destinationName;
          _currentLocationController.text = _currentLocation;
        }
      });

      if (result != null) {
        _showSuccessSnackBar(
          'Current location detected: ${result.referenceImage.destinationName} (${result.similarity}% match)',
        );
      } else {
        _showInfoSnackBar('Could not identify location. Please enter current location manually.');
      }
    } catch (e) {
      setState(() {
        _isProcessingCurrentLocation = false;
      });
      _showErrorSnackBar('Error processing image');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Upload Current Location Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: _AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _ImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: _AppColors.accent2,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _findRoute() {
    final destination = _destinationController.text.trim();
    final currentLoc = _currentLocationController.text.trim();
    
    if (destination.isEmpty) {
      _showErrorSnackBar('Please enter a destination');
      return;
    }
    
    if (currentLoc.isEmpty && _currentLocation == 'Unknown') {
      _showErrorSnackBar('Please enter your current location or upload an image');
      return;
    }

    final finalCurrentLocation = currentLoc.isNotEmpty ? currentLoc : _currentLocation;
    
    // Navigate to route display screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RouteDisplayScreen(
          currentLocation: finalCurrentLocation,
          destination: destination,
          isWheelchairFriendly: _wheelchairFriendly,
        ),
      ),
    );
  }

  void _showLandmarkDirections() {
    final destination = _destinationController.text.trim();
    final currentLoc = _currentLocationController.text.trim();
    
    if (destination.isEmpty) {
      _showErrorSnackBar('Please enter a destination');
      return;
    }
    
    if (currentLoc.isEmpty && _currentLocation == 'Unknown') {
      _showErrorSnackBar('Please enter your current location or upload an image');
      return;
    }

    final finalCurrentLocation = currentLoc.isNotEmpty ? currentLoc : _currentLocation;
    
    // Navigate to landmark directions screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LandmarkDirectionsScreen(
          source: finalCurrentLocation,
          destination: destination,
          isWheelchairFriendly: _wheelchairFriendly,
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _AppColors.accent4,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _AppColors.accent1,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Location Section
                    _buildSectionHeader('Your Current Location'),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your location or upload an image to detect it',
                      style: TextStyle(
                        color: _AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCurrentLocationCard(),
                    const SizedBox(height: 24),
                    // Destination Section
                    _buildSectionHeader('Enter Destination'),
                    const SizedBox(height: 12),
                    _buildDestinationInput(),
                    const SizedBox(height: 24),
                    // Route Options
                    _buildRouteOptions(),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Action Buttons
      bottomNavigationBar: _buildBottomBar(),
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
            child: Text(
              'Find Route',
              style: TextStyle(
                color: _AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, color: _AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.accent4.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _AppColors.accent4.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current location display header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _AppColors.accent4.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.my_location, color: _AppColors.accent4, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Location',
                      style: TextStyle(
                        color: _AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentLocation,
                      style: TextStyle(
                        color: _currentLocation == 'Unknown' 
                            ? _AppColors.accent1 
                            : _AppColors.accent4,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _currentLocation == 'Unknown'
                      ? _AppColors.accent1.withOpacity(0.1)
                      : _AppColors.accent4.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: _currentLocation == 'Unknown'
                          ? _AppColors.accent1
                          : _AppColors.accent4,
                      size: 6,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentLocation == 'Unknown' ? 'Not Set' : 'Set',
                      style: TextStyle(
                        color: _currentLocation == 'Unknown'
                            ? _AppColors.accent1
                            : _AppColors.accent4,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Text input for current location
          TextField(
            controller: _currentLocationController,
            style: const TextStyle(color: _AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Type your current location...',
              hintStyle: TextStyle(color: _AppColors.textSecondary.withOpacity(0.6)),
              prefixIcon: const Icon(Icons.edit_location_alt, color: _AppColors.accent4, size: 20),
              suffixIcon: _currentLocationController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: _AppColors.textSecondary, size: 18),
                      onPressed: () {
                        setState(() {
                          _currentLocationController.clear();
                          _currentLocation = 'Unknown';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: _AppColors.background,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _AppColors.accent4, width: 1.5),
              ),
            ),
            onChanged: (value) {
              setState(() {
                if (value.trim().isNotEmpty) {
                  _currentLocation = value.trim();
                } else {
                  _currentLocation = 'Unknown';
                }
              });
            },
          ),
          const SizedBox(height: 12),
          // Image upload for current location
          _buildCurrentLocationImageUpload(),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationImageUpload() {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(),
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: _AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedCurrentLocationImage != null
                ? _AppColors.accent4
                : _AppColors.cardBorder,
            width: _selectedCurrentLocationImage != null ? 1.5 : 1,
          ),
        ),
        child: _selectedCurrentLocationImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      _selectedCurrentLocationImage!,
                      fit: BoxFit.cover,
                    ),
                    if (_isProcessingCurrentLocation)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Detecting location...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCurrentLocationImage = null;
                            _currentLocationMatchResult = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _AppColors.accent4.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo,
                      color: _AppColors.accent4,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload image to detect location',
                        style: TextStyle(
                          color: _AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Camera or Gallery',
                        style: TextStyle(
                          color: _AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: _AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationInput() {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _destinationController,
        style: const TextStyle(color: _AppColors.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'e.g., Emergency Department, Pharmacy',
          hintStyle: TextStyle(color: _AppColors.textSecondary.withOpacity(0.6)),
          prefixIcon: const Icon(Icons.location_on, color: _AppColors.primary),
          suffixIcon: _destinationController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: _AppColors.textSecondary),
                  onPressed: () {
                    setState(() {
                      _destinationController.clear();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: _AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _AppColors.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildRouteOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Options',
            style: TextStyle(
              color: _AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Wheelchair Friendly Toggle
          InkWell(
            onTap: () {
              setState(() {
                _wheelchairFriendly = !_wheelchairFriendly;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _wheelchairFriendly 
                    ? _AppColors.primary.withOpacity(0.1) 
                    : _AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _wheelchairFriendly 
                      ? _AppColors.primary 
                      : _AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.accessible,
                    color: _wheelchairFriendly 
                        ? _AppColors.primary 
                        : _AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wheelchair Friendly Route',
                          style: TextStyle(
                            color: _wheelchairFriendly 
                                ? _AppColors.primary 
                                : _AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Uses elevators and ramps only',
                          style: TextStyle(
                            color: _AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _wheelchairFriendly,
                    onChanged: (value) {
                      setState(() {
                        _wheelchairFriendly = value;
                      });
                    },
                    activeColor: _AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Landmark-Based Directions Option
          InkWell(
            onTap: _showLandmarkDirections,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.signpost,
                      color: Color(0xFFFF6B35),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Get Landmark-Based Directions',
                          style: TextStyle(
                            color: Color(0xFFFF6B35),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Step-by-step with landmarks • Voice guidance • Malayalam',
                          style: TextStyle(
                            color: _AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFFF6B35),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Wheelchair Route Quick Button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _AppColors.cardBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _wheelchairFriendly = !_wheelchairFriendly;
                  });
                  _showInfoSnackBar(
                    _wheelchairFriendly 
                        ? 'Wheelchair friendly route enabled' 
                        : 'Standard route enabled',
                  );
                },
                icon: Icon(
                  Icons.accessible,
                  color: _wheelchairFriendly 
                      ? _AppColors.primary 
                      : _AppColors.textSecondary,
                ),
                padding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(width: 12),
            // Find Route Button
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _findRoute,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_AppColors.primary, _AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.navigation, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Find Route',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
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
      ),
    );
  }
}

class _ImageSourceOption extends StatelessWidget {
  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: _AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 4.0;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(start, end),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RouteResultSheet extends StatelessWidget {
  const _RouteResultSheet({
    required this.currentLocation,
    required this.destination,
    required this.isWheelchairFriendly,
    this.matchResult,
  });

  final String currentLocation;
  final String destination;
  final bool isWheelchairFriendly;
  final MatchResult? matchResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Route Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // From
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _AppColors.accent4.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location, color: _AppColors.accent4, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FROM',
                            style: TextStyle(
                              color: _AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            currentLocation,
                            style: const TextStyle(
                              color: _AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 30,
                        color: _AppColors.primary.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                // To
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: _AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TO',
                            style: TextStyle(
                              color: _AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            destination,
                            style: const TextStyle(
                              color: _AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (matchResult != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              matchResult!.referenceImage.floor,
                              style: TextStyle(
                                color: _AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Route Info
          Row(
            children: [
              Expanded(
                child: _RouteInfoCard(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: '~150m',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RouteInfoCard(
                  icon: Icons.schedule,
                  label: 'Est. Time',
                  value: isWheelchairFriendly ? '4 min' : '2 min',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isWheelchairFriendly)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _AppColors.accent4.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.accessible, color: _AppColors.accent4, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Wheelchair accessible route via elevator',
                      style: TextStyle(
                        color: _AppColors.accent4,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          // Start Navigation Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Starting navigation...'),
                    backgroundColor: _AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation),
                  SizedBox(width: 8),
                  Text(
                    'Start Navigation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RouteInfoCard extends StatelessWidget {
  const _RouteInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: _AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: _AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
