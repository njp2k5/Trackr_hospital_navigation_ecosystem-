import 'package:flutter/material.dart';
import 'package:hospital_nav_app/screens/hospital_detail_screen.dart';

// Light theme color palette
class AppColors {
  static const Color primary = Color(0xFF2563EB); // Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF0891B2); // Cyan/Teal
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color accent1 = Color(0xFFEF4444); // Red
  static const Color accent2 = Color(0xFF8B5CF6); // Purple
  static const Color accent3 = Color(0xFFF97316); // Orange
  static const Color accent4 = Color(0xFF10B981); // Green
  static const Color accent5 = Color(0xFFEC4899); // Pink
}

class HospitalSearchScreen extends StatefulWidget {
  const HospitalSearchScreen({super.key});

  @override
  State<HospitalSearchScreen> createState() => _HospitalSearchScreenState();
}

class _HospitalSearchScreenState extends State<HospitalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int? _selectedPopularIndex;

  final List<String> _allHospitals = const [
    'City General Hospital',
    'Sunrise Medical Center',
    'Green Valley Clinic',
    "St. Mary's Hospital",
    'Mercy Healthcare',
    'Apollo Hospital',
    'St Thomas Medical College',
    'MedLife Multi-Speciality',
    'Riverbend Children Hospital',
    'Downtown Orthopedic Institute',
    'Wellness Heart Center',
  ];

  List<String> get _popularHospitals => const [
        'Apollo Hospital',
        'St Thomas Medical College',
        'City General Hospital',
        'Sunrise Medical Center',
        'Mercy Healthcare',
      ];

  List<String> get _filtered {
    if (_query.trim().isEmpty) return const [];
    final q = _query.toLowerCase();
    return _allHospitals
        .where((h) => h.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
        if (_query.isNotEmpty) _selectedPopularIndex = null;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectHospital(String name) {
    FocusScope.of(context).unfocus();

    if (name == 'St Thomas Medical College') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HospitalDetailScreen(
            hospitalName: name,
            imagePath: 'assets/images/st_thomas_hospital.jpeg',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: $name'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _LightSearchBar(
              controller: _searchController,
              hintText: 'Search hospitals...',
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _query.isEmpty
                    ? _PopularSection(
                        hospitals: _popularHospitals,
                        selectedIndex: _selectedPopularIndex,
                        onSelected: (index, name) {
                          setState(() {
                            _selectedPopularIndex = index;
                          });
                          _selectHospital(name);
                        },
                      )
                    : _SearchResults(
                        results: _filtered,
                        onTap: _selectHospital,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightSearchBar extends StatelessWidget {
  const _LightSearchBar({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Find Hospital',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune, color: AppColors.primary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                        onPressed: () => controller.clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularSection extends StatelessWidget {
  const _PopularSection({
    required this.hospitals,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> hospitals;
  final int? selectedIndex;
  final void Function(int index, String name) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Popular Hospitals',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Quick access to frequently visited hospitals',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(hospitals.length, (i) {
            final name = hospitals[i];
            final selected = selectedIndex == i;
            return _HospitalCard(
              name: name,
              index: i,
              isSelected: selected,
              onTap: () => onSelected(i, name),
            );
          }),
        ],
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  const _HospitalCard({
    required this.name,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  static const List<Color> _accentColors = [
    AppColors.primary,
    AppColors.accent2,
    AppColors.accent3,
    AppColors.accent4,
    AppColors.accent5,
  ];

  static const List<IconData> _icons = [
    Icons.local_hospital,
    Icons.medical_services,
    Icons.health_and_safety,
    Icons.healing,
    Icons.emergency,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _accentColors[index % _accentColors.length];
    final icon = _icons[index % _icons.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? color.withOpacity(0.15) : Colors.black.withOpacity(0.04),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade600, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '4.${5 + index % 5}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on, color: AppColors.textSecondary, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '${(index + 1) * 2}.${index}km',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.results,
    required this.onTap,
  });

  final List<String> results;
  final void Function(String name) onTap;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No hospitals found',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term or browse\nthe popular hospitals',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final name = results[index];
        return _SearchResultCard(
          name: name,
          index: index,
          onTap: () => onTap(name),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.name,
    required this.index,
    required this.onTap,
  });

  final String name;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to view details',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
