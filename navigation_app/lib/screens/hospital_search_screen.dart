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

  // Filter state
  Set<String> _activeFilters = {};

  // Available filter categories
  static const List<Map<String, dynamic>> _filterCategories = [
    {'name': 'Multi-Speciality', 'icon': Icons.local_hospital},
    {'name': 'Children', 'icon': Icons.child_care},
    {'name': 'Cardiac', 'icon': Icons.favorite},
    {'name': 'Orthopedic', 'icon': Icons.accessibility_new},
    {'name': 'General', 'icon': Icons.medical_services},
    {'name': 'Teaching', 'icon': Icons.school},
  ];

  // Hospital data with categories
  final List<Map<String, dynamic>> _allHospitalsData = const [
    {
      'name': 'City General Hospital',
      'categories': ['General', 'Multi-Speciality'],
    },
    {
      'name': 'Sunrise Medical Center',
      'categories': ['General', 'Multi-Speciality'],
    },
    {
      'name': 'Green Valley Clinic',
      'categories': ['General'],
    },
    {
      "name": "St. Mary's Hospital",
      'categories': ['General', 'Cardiac'],
    },
    {
      'name': 'Mercy Healthcare',
      'categories': ['Multi-Speciality', 'Cardiac'],
    },
    {
      'name': 'Apollo Hospital',
      'categories': ['Multi-Speciality', 'Cardiac', 'Orthopedic'],
    },
    {
      'name': 'St Thomas Medical College',
      'categories': ['Teaching', 'Multi-Speciality', 'General'],
    },
    {
      'name': 'MedLife Multi-Speciality',
      'categories': ['Multi-Speciality'],
    },
    {
      'name': 'Riverbend Children Hospital',
      'categories': ['Children'],
    },
    {
      'name': 'Downtown Orthopedic Institute',
      'categories': ['Orthopedic'],
    },
    {
      'name': 'Wellness Heart Center',
      'categories': ['Cardiac'],
    },
  ];

  List<String> get _popularHospitals => const [
    'Apollo Hospital',
    'St Thomas Medical College',
    'City General Hospital',
    'Sunrise Medical Center',
    'Mercy Healthcare',
  ];

  List<String> get _allHospitals =>
      _allHospitalsData.map((h) => h['name'] as String).toList();

  List<String> get _filtered {
    // Start with all hospitals
    var results = _allHospitalsData.toList();

    // Apply category filters if any are active
    if (_activeFilters.isNotEmpty) {
      results = results.where((h) {
        final categories = h['categories'] as List<String>;
        return _activeFilters.any((filter) => categories.contains(filter));
      }).toList();
    }

    // Apply text search if query is not empty
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      results = results
          .where((h) => (h['name'] as String).toLowerCase().contains(q))
          .toList();
    }

    // If no filters and no query, return empty (show popular)
    if (_activeFilters.isEmpty && _query.trim().isEmpty) {
      return const [];
    }

    return results.map((h) => h['name'] as String).toList();
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

  void _toggleFilter(String filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
      _selectedPopularIndex = null;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        categories: _filterCategories,
        activeFilters: _activeFilters,
        onToggle: (filter) {
          _toggleFilter(filter);
          Navigator.pop(context);
        },
        onClear: () {
          setState(() => _activeFilters.clear());
          Navigator.pop(context);
        },
      ),
    );
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

  bool get _hasActiveFilters => _activeFilters.isNotEmpty;
  bool get _showResults => _query.isNotEmpty || _activeFilters.isNotEmpty;

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
              onFilterTap: _showFilterBottomSheet,
              filterCount: _activeFilters.length,
            ),
            // Active filters chips
            if (_hasActiveFilters)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: AppColors.surface,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._activeFilters.map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              filter,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppColors.primary,
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                            onDeleted: () => _toggleFilter(filter),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      if (_activeFilters.length > 1)
                        TextButton(
                          onPressed: () =>
                              setState(() => _activeFilters.clear()),
                          child: const Text(
                            'Clear all',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showResults
                    ? _SearchResults(results: _filtered, onTap: _selectHospital)
                    : _PopularSection(
                        hospitals: _popularHospitals,
                        selectedIndex: _selectedPopularIndex,
                        onSelected: (index, name) {
                          setState(() {
                            _selectedPopularIndex = index;
                          });
                          _selectHospital(name);
                        },
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
    this.onFilterTap,
    this.filterCount = 0,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onFilterTap;
  final int filterCount;

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
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.primary,
                  size: 20,
                ),
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
              GestureDetector(
                onTap: onFilterTap,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: filterCount > 0
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tune,
                        color: filterCount > 0
                            ? Colors.white
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    if (filterCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.accent1,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$filterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 15,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => controller.clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
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
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
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
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : Colors.black.withOpacity(0.04),
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
                          Icon(
                            Icons.star,
                            color: Colors.amber.shade600,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.${5 + index % 5}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on,
                            color: AppColors.textSecondary,
                            size: 15,
                          ),
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
                  child: Icon(Icons.arrow_forward_ios, color: color, size: 16),
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
  const _SearchResults({required this.results, required this.onTap});

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
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                  child: const Icon(
                    Icons.local_hospital,
                    color: AppColors.primary,
                    size: 24,
                  ),
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

/// Filter bottom sheet for hospital categories
class _FilterBottomSheet extends StatelessWidget {
  const _FilterBottomSheet({
    required this.categories,
    required this.activeFilters,
    required this.onToggle,
    required this.onClear,
  });

  final List<Map<String, dynamic>> categories;
  final Set<String> activeFilters;
  final void Function(String filter) onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filter by Category',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (activeFilters.isNotEmpty)
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Clear all'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Filter grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categories.map((category) {
                final name = category['name'] as String;
                final icon = category['icon'] as IconData;
                final isActive = activeFilters.contains(name);

                return GestureDetector(
                  onTap: () => onToggle(name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: isActive ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
