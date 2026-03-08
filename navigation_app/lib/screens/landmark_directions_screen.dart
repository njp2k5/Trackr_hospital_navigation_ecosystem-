import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hospital_nav_app/services/landmark_directions_service.dart';

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
  static const Color malayalamAccent = Color(0xFFFF6B35);
}

class LandmarkDirectionsScreen extends StatefulWidget {
  final String source;
  final String destination;
  final bool isWheelchairFriendly;

  const LandmarkDirectionsScreen({
    super.key,
    required this.source,
    required this.destination,
    this.isWheelchairFriendly = false,
  });

  @override
  State<LandmarkDirectionsScreen> createState() => _LandmarkDirectionsScreenState();
}

class _LandmarkDirectionsScreenState extends State<LandmarkDirectionsScreen>
    with SingleTickerProviderStateMixin {
  final LandmarkDirectionsService _directionsService = LandmarkDirectionsService();
  final FlutterTts _flutterTts = FlutterTts();
  
  late LandmarkRoute _route;
  bool _isMalayalam = false;
  bool _isSpeaking = false;
  bool _isReadingAll = false;
  int _currentReadingStep = -1;
  double _speechRate = 0.5;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _loadRoute();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _initializeTTS() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      if (_isReadingAll && _currentReadingStep < _route.steps.length - 1) {
        // Continue to next step
        setState(() {
          _currentReadingStep++;
        });
        _speakStep(_currentReadingStep);
      } else {
        setState(() {
          _isSpeaking = false;
          _isReadingAll = false;
          _currentReadingStep = -1;
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
        _isReadingAll = false;
      });
      _showErrorSnackBar('Speech error: $msg');
    });
  }

  void _loadRoute() {
    _route = _directionsService.getDirections(
      source: widget.source,
      destination: widget.destination,
      isWheelchairFriendly: widget.isWheelchairFriendly,
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _setLanguage(bool isMalayalam) async {
    await _flutterTts.stop();
    setState(() {
      _isMalayalam = isMalayalam;
      _isSpeaking = false;
      _isReadingAll = false;
      _currentReadingStep = -1;
    });
    
    // Set TTS language
    if (isMalayalam) {
      // Try Malayalam, fallback to Hindi/English if not available
      final languages = await _flutterTts.getLanguages;
      if (languages.toString().toLowerCase().contains('ml')) {
        await _flutterTts.setLanguage('ml-IN');
      } else if (languages.toString().toLowerCase().contains('hi')) {
        await _flutterTts.setLanguage('hi-IN');
      } else {
        // Keep English but read Malayalam text
        await _flutterTts.setLanguage('en-IN');
      }
    } else {
      await _flutterTts.setLanguage('en-US');
    }
  }

  Future<void> _speakStep(int stepIndex) async {
    if (stepIndex < 0 || stepIndex >= _route.steps.length) return;
    
    final step = _route.steps[stepIndex];
    String textToSpeak;
    
    if (_isMalayalam) {
      textToSpeak = 'Step ${step.stepNumber}. ${step.instructionMalayalam}';
      if (step.landmarkMalayalam != null) {
        textToSpeak += '. Landmark: ${step.landmarkMalayalam}';
      }
    } else {
      textToSpeak = 'Step ${step.stepNumber}. ${step.instruction}';
      if (step.landmark != null) {
        textToSpeak += '. Look for: ${step.landmark}';
      }
    }
    
    setState(() {
      _isSpeaking = true;
      _currentReadingStep = stepIndex;
    });
    
    await _flutterTts.speak(textToSpeak);
  }

  Future<void> _readAllSteps() async {
    if (_isSpeaking) {
      await _stopSpeaking();
      return;
    }
    
    setState(() {
      _isReadingAll = true;
      _currentReadingStep = 0;
    });
    
    // Speak introduction
    String intro = _isMalayalam 
        ? 'മാർഗ്ഗ നിർദ്ദേശങ്ങൾ ${_route.sourceMalayalam} മുതൽ ${_route.destinationMalayalam} വരെ.'
        : 'Directions from ${_route.source} to ${_route.destination}.';
    
    await _flutterTts.speak(intro);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
      _isReadingAll = false;
      _currentReadingStep = -1;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildAppBar(),
              _buildRouteHeader(),
              _buildLanguageToggle(),
              _buildControlBar(),
              Expanded(
                child: _buildDirectionsList(),
              ),
              _buildBottomActions(),
            ],
          ),
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
                Text(
                  _isMalayalam ? 'ലാൻഡ്മാർക്ക് ദിശകൾ' : 'Landmark Directions',
                  style: const TextStyle(
                    color: _AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isMalayalam 
                      ? 'ശബ്ദ മാർഗ്ഗനിർദ്ദേശത്തോടെ'
                      : 'With voice guidance',
                  style: TextStyle(
                    color: _AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _AppColors.accent4.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: _AppColors.accent4, size: 16),
                const SizedBox(width: 4),
                Text(
                  '~${_route.estimatedTimeMinutes} min',
                  style: const TextStyle(
                    color: _AppColors.accent4,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                      _isMalayalam ? 'ഇവിടെ നിന്ന്' : 'FROM',
                      style: TextStyle(
                        color: _AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _isMalayalam ? _route.sourceMalayalam : _route.source,
                      style: const TextStyle(
                        color: _AppColors.textPrimary,
                        fontSize: 14,
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
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _AppColors.accent4,
                        _AppColors.primary,
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_route.totalDistanceMeters.toInt()}m • ${_route.steps.length} ${_isMalayalam ? "ഘട്ടങ്ങൾ" : "steps"}',
                  style: TextStyle(
                    color: _AppColors.textSecondary,
                    fontSize: 12,
                  ),
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
                      _isMalayalam ? 'ലക്ഷ്യസ്ഥാനം' : 'TO',
                      style: TextStyle(
                        color: _AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _isMalayalam ? _route.destinationMalayalam : _route.destination,
                      style: const TextStyle(
                        color: _AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _setLanguage(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isMalayalam ? _AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.language,
                      size: 18,
                      color: !_isMalayalam ? Colors.white : _AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'English',
                      style: TextStyle(
                        color: !_isMalayalam ? Colors.white : _AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _setLanguage(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isMalayalam ? _AppColors.malayalamAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.translate,
                      size: 18,
                      color: _isMalayalam ? Colors.white : _AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'മലയാളം',
                      style: TextStyle(
                        color: _isMalayalam ? Colors.white : _AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Read All Button
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _readAllSteps,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _isReadingAll ? _AppColors.accent1 : _AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isReadingAll ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isReadingAll 
                            ? (_isMalayalam ? 'നിർത്തുക' : 'Stop')
                            : (_isMalayalam ? 'എല്ലാം വായിക്കുക' : 'Read All'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Speech Rate Control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.speed,
                  color: _AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _adjustSpeechRate(-0.1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove, size: 16, color: _AppColors.primary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${(_speechRate * 2).toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: _AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _adjustSpeechRate(0.1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 16, color: _AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _adjustSpeechRate(double delta) {
    setState(() {
      _speechRate = (_speechRate + delta).clamp(0.2, 1.0);
    });
    _flutterTts.setSpeechRate(_speechRate);
  }

  Widget _buildDirectionsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _route.steps.length,
      itemBuilder: (context, index) {
        return _buildStepCard(_route.steps[index], index);
      },
    );
  }

  Widget _buildStepCard(LandmarkDirectionStep step, int index) {
    final isCurrentlyReading = _currentReadingStep == index;
    final instruction = _isMalayalam ? step.instructionMalayalam : step.instruction;
    final landmark = _isMalayalam ? step.landmarkMalayalam : step.landmark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentlyReading 
            ? (_isMalayalam ? _AppColors.malayalamAccent.withOpacity(0.1) : _AppColors.primary.withOpacity(0.1))
            : _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentlyReading 
              ? (_isMalayalam ? _AppColors.malayalamAccent : _AppColors.primary)
              : _AppColors.cardBorder,
          width: isCurrentlyReading ? 2 : 1,
        ),
        boxShadow: isCurrentlyReading 
            ? [
                BoxShadow(
                  color: (_isMalayalam ? _AppColors.malayalamAccent : _AppColors.primary).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _speakStep(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Header
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCurrentlyReading 
                            ? (_isMalayalam ? _AppColors.malayalamAccent : _AppColors.primary)
                            : _AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${step.stepNumber}',
                          style: TextStyle(
                            color: isCurrentlyReading ? Colors.white : _AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStepIconColor(step.icon).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        step.icon,
                        color: _getStepIconColor(step.icon),
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    if (step.distanceMeters != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${step.distanceMeters!.toInt()}m',
                          style: TextStyle(
                            color: _AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (step.floor != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _AppColors.accent2.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isMalayalam ? 'നില ${step.floor}' : 'Floor ${step.floor}',
                          style: TextStyle(
                            color: _AppColors.accent2,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    // Speak button
                    GestureDetector(
                      onTap: () {
                        if (_isSpeaking && _currentReadingStep == index) {
                          _stopSpeaking();
                        } else {
                          _speakStep(index);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCurrentlyReading && _isSpeaking
                              ? _AppColors.accent1.withOpacity(0.1)
                              : _AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCurrentlyReading && _isSpeaking 
                              ? Icons.stop 
                              : Icons.volume_up,
                          color: isCurrentlyReading && _isSpeaking
                              ? _AppColors.accent1
                              : _AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Instruction
                Text(
                  instruction,
                  style: TextStyle(
                    color: _AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                // Landmark
                if (landmark != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _AppColors.accent4.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _AppColors.accent4.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.place,
                          color: _AppColors.accent4,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isMalayalam ? 'ലാൻഡ്മാർക്ക്:' : 'Landmark:',
                                style: TextStyle(
                                  color: _AppColors.accent4,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                landmark,
                                style: TextStyle(
                                  color: _AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStepIconColor(IconData icon) {
    if (icon == Icons.turn_left || icon == Icons.turn_right) {
      return _AppColors.accent2;
    } else if (icon == Icons.location_on) {
      return _AppColors.accent1;
    } else if (icon == Icons.elevator || icon == Icons.accessible) {
      return _AppColors.secondary;
    } else if (icon == Icons.local_hospital || icon == Icons.medication) {
      return _AppColors.accent1;
    } else if (icon == Icons.restaurant) {
      return _AppColors.malayalamAccent;
    }
    return _AppColors.primary;
  }

  Widget _buildBottomActions() {
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
            // Share Button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _AppColors.cardBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isMalayalam 
                          ? 'ദിശകൾ പകർത്തി!' 
                          : 'Directions copied to clipboard!'),
                      backgroundColor: _AppColors.accent4,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                icon: const Icon(Icons.share, color: _AppColors.primary),
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(width: 12),
            // Read All Aloud Button
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _readAllSteps,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isReadingAll 
                            ? [_AppColors.accent1, _AppColors.accent1.withOpacity(0.8)]
                            : [
                                _isMalayalam ? _AppColors.malayalamAccent : _AppColors.primary, 
                                _isMalayalam ? _AppColors.malayalamAccent.withOpacity(0.8) : _AppColors.primaryLight
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (_isMalayalam ? _AppColors.malayalamAccent : _AppColors.primary).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isReadingAll ? Icons.stop_circle : Icons.record_voice_over,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isReadingAll 
                              ? (_isMalayalam ? 'വായന നിർത്തുക' : 'Stop Reading')
                              : (_isMalayalam ? 'ഉച്ചത്തിൽ വായിക്കുക' : 'Read Aloud'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
