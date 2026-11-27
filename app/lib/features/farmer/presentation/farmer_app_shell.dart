import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../community/presentation/community_screen.dart';
import '../../community/presentation/messages_screen.dart';

import '../../irrigation/presentation/irrigation_screen.dart';
import '../../irrigation/presentation/device_management_screen.dart';
import '../../authentication/data/auth_providers.dart';
import '../../authentication/presentation/auth_screen.dart';
import 'derja_voice_screen.dart';
import 'farmer_home_screen.dart';
import 'farm_api_service.dart';
import '../../weather/presentation/weather_screen.dart';
import '../../diagnosis/data/presentation/diagnosis_screen.dart';

const Color _forest = Color(0xFF183F32);
const Color _green = Color(0xFF527B58);
const Color _cream = Color(0xFFF7F6EF);
const Color _muted = Color(0xFF59665C);
const Color _lightGreen = Color(0xFFE5EEE4);

class FarmerAppShell extends StatefulWidget {
  const FarmerAppShell({super.key});

  @override
  State<FarmerAppShell> createState() => _FarmerAppShellState();
}

class _FarmerAppShellState extends State<FarmerAppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _railExpanded = true;

  void _selectPage(int index) {
    if (index < 0 || index >= 11) return;
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  List<Widget> _pages(String languageCode) => [
    FarmerHomeScreen(onNavigate: _selectPage),
    const _FarmsPage(),
    IrrigationScreen(key: ValueKey('irrigation-$languageCode')),
    _AssistantPage(onNavigate: _selectPage),
    const DiagnosisScreen(),
    const WeatherScreen(),
    const CommunityScreen(),
    const MessagesScreen(),
    const DeviceManagementScreen(),
    const _ProfilePage(),
    const _SettingsPage(),
  ];

  List<_ShellDestination> _destinations(AppLocalizations l10n) => [
    _ShellDestination(Icons.home_outlined, Icons.home_rounded, l10n.home),
    _ShellDestination(
      Icons.agriculture_outlined,
      Icons.agriculture_rounded,
      l10n.farms,
    ),
    _ShellDestination(
      Icons.water_drop_outlined,
      Icons.water_drop_rounded,
      l10n.irrigation,
    ),
    _ShellDestination(
      Icons.graphic_eq_rounded,
      Icons.graphic_eq_rounded,
      l10n.assistant,
    ),
    _ShellDestination(
      Icons.biotech_outlined,
      Icons.biotech_rounded,
      l10n.diagnosis,
    ),
    _ShellDestination(
      Icons.wb_sunny_outlined,
      Icons.wb_sunny_rounded,
      l10n.weather,
    ),
    _ShellDestination(
      Icons.groups_outlined,
      Icons.groups_rounded,
      l10n.community,
    ),
    _ShellDestination(
      Icons.chat_bubble_outline_rounded,
      Icons.chat_rounded,
      l10n.messages,
    ),
    _ShellDestination(
      Icons.devices_other_outlined,
      Icons.devices_rounded,
      _deviceManagementLabel(l10n),
    ),
  ];

  String _deviceManagementLabel(AppLocalizations l10n) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'fr':
        return 'Appareils';
      case 'ar':
        return 'الأجهزة';
      default:
        return 'Devices';
    }
  }

  Widget _sidebar(AppLocalizations l10n, {required bool extended}) {
    final destinations = _destinations(l10n);
    return NavigationRail(
      extended: extended,
      minWidth: 76,
      minExtendedWidth: 228,
      selectedIndex: _selectedIndex < 9 ? _selectedIndex : null,
      onDestinationSelected: _selectPage,
      backgroundColor: Colors.white,
      indicatorColor: _lightGreen,
      selectedLabelTextStyle: const TextStyle(
        color: _forest,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: _muted,
        fontWeight: FontWeight.w500,
      ),
      selectedIconTheme: const IconThemeData(color: _forest),
      unselectedIconTheme: const IconThemeData(color: _green),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: extended
            ? Row(
                children: [
                  const Icon(Icons.eco_rounded, color: _forest, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'AETHERA',
                    style: TextStyle(
                      color: _forest,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              )
            : const Icon(Icons.eco_rounded, color: _forest, size: 29),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Divider(indent: 12, endIndent: 12),
          if (extended) ...[
            SizedBox(
              width: 220,
              child: ListTile(
                selected: _selectedIndex == 9,
                selectedTileColor: _lightGreen,
                leading: const CircleAvatar(
                  backgroundColor: _lightGreen,
                  child: Icon(Icons.person_rounded, color: _forest),
                ),
                title: Text(
                  l10n.profile,
                  style: const TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => _selectPage(9),
              ),
            ),
            SizedBox(
              width: 220,
              child: ListTile(
                selected: _selectedIndex == 10,
                selectedTileColor: _lightGreen,
                leading: const Icon(Icons.settings_outlined, color: _green),
                title: Text(
                  l10n.settings,
                  style: const TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => _selectPage(10),
              ),
            ),
          ] else ...[
            IconButton(
              tooltip: l10n.profile,
              onPressed: () => _selectPage(9),
              icon: const CircleAvatar(
                backgroundColor: _lightGreen,
                child: Icon(Icons.person_rounded, color: _forest),
              ),
            ),
            IconButton(
              tooltip: l10n.settings,
              onPressed: () => _selectPage(10),
              icon: const Icon(Icons.settings_outlined, color: _green),
            ),
          ],
          IconButton(
            tooltip: extended ? l10n.collapseSidebar : l10n.expandSidebar,
            onPressed: () => setState(() => _railExpanded = !_railExpanded),
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? (extended
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded)
                  : (extended
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded),
              color: _green,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
      destinations: [
        for (final item in destinations)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
      ],
    );
  }

  Widget _mobileDrawer(AppLocalizations l10n) {
    final destinations = _destinations(l10n);
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: _lightGreen,
                    child: Icon(Icons.eco_rounded, color: _forest),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AETHERA',
                    style: TextStyle(
                      color: _forest,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final item = destinations[index];
                  final selected = _selectedIndex == index;
                  return ListTile(
                    selected: selected,
                    selectedTileColor: _lightGreen,
                    leading: Icon(
                      selected ? item.selectedIcon : item.icon,
                      color: selected ? _forest : _green,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: selected ? _forest : _muted,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                    onTap: () => _selectPage(index),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              selected: _selectedIndex == 9,
              selectedTileColor: _lightGreen,
              leading: const CircleAvatar(
                backgroundColor: _lightGreen,
                child: Icon(Icons.person_rounded, color: _forest),
              ),
              title: Text(
                l10n.profile,
                style: const TextStyle(
                  color: _forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => _selectPage(9),
            ),
            ListTile(
              selected: _selectedIndex == 10,
              selectedTileColor: _lightGreen,
              leading: const Icon(Icons.settings_outlined, color: _green),
              title: Text(
                l10n.settings,
                style: const TextStyle(
                  color: _forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => _selectPage(10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = _pages(Localizations.localeOf(context).languageCode);
    return Theme(
      data: AppTheme.lightTheme.copyWith(
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: _lightGreen,
          height: 70,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected) ? _forest : _green,
              fontSize: 10,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? _forest : _green,
              size: 22,
            ),
          ),
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _cream,
        drawer: wide ? null : _mobileDrawer(l10n),
        body: Row(
          children: [
            if (wide) _sidebar(l10n, extended: _railExpanded),
            Expanded(
              child: Stack(
                children: [
                  if (wide)
                    IndexedStack(index: _selectedIndex, children: pages)
                  else
                    Padding(
                      // Reserve a dedicated menu row so the hamburger never covers
                      // screen headers, refresh buttons, titles, or controls.
                      padding: const EdgeInsets.only(top: 58),
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: pages,
                      ),
                    ),
                  if (!wide)
                    PositionedDirectional(
                      top: 7,
                      start: 10,
                      child: SafeArea(
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: IconButton(
                            tooltip: l10n.openNavigation,
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            icon: const Icon(
                              Icons.menu_rounded,
                              color: _forest,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE6EAE3))),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      _QuickNavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: l10n.home,
                        active: _selectedIndex == 0,
                        onTap: () => _selectPage(0),
                      ),
                      _QuickNavItem(
                        icon: Icons.agriculture_outlined,
                        activeIcon: Icons.agriculture_rounded,
                        label: l10n.farms,
                        active: _selectedIndex == 1,
                        onTap: () => _selectPage(1),
                      ),
                      _QuickNavItem(
                        icon: Icons.water_drop_outlined,
                        activeIcon: Icons.water_drop_rounded,
                        label: l10n.irrigation,
                        active: _selectedIndex == 2,
                        onTap: () => _selectPage(2),
                      ),
                      _QuickNavItem(
                        icon: Icons.graphic_eq_rounded,
                        activeIcon: Icons.graphic_eq_rounded,
                        label: l10n.assistant,
                        active: _selectedIndex == 3,
                        onTap: () => _selectPage(3),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _QuickNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _QuickNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _forest : _muted;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: active ? _lightGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    active ? activeIcon : icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
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

class _ShellDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _ShellDestination(this.icon, this.selectedIcon, this.label);
}

// --------------------------------------------------
// KEEP THE REST OF YOUR FILE BELOW THIS LINE
// Starting with: // SHARED PAGE HEADER
// --------------------------------------------------

// --------------------------------------------------
// SHARED PAGE HEADER
// --------------------------------------------------

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 25, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AETHERA',
            style: TextStyle(
              color: _green,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: _forest,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 13)),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// FARMS PAGE
// --------------------------------------------------

class _FarmsPage extends StatefulWidget {
  const _FarmsPage();

  @override
  State<_FarmsPage> createState() => _FarmsPageState();
}

class _FarmsPageState extends State<_FarmsPage> {
  final FarmApiService _api = FarmApiService();

  List<Farm> _farms = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final farms = await _api.getMyFarms();

      if (!mounted) return;

      setState(() {
        _farms = farms;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = AppLocalizations.of(context)!.farmLoadError;
        _loading = false;
      });
    }
  }

  Future<void> _addFarm() async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final areaController = TextEditingController();
    final soilController = TextEditingController();
    final irrigationController = TextEditingController();

    try {
      final values = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              AppLocalizations.of(context)!.addFarm,
              style: TextStyle(color: _forest, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _farmField(
                        nameController,
                        AppLocalizations.of(context)!.farmName,
                        required: true,
                      ),
                      _farmField(
                        locationController,
                        AppLocalizations.of(context)!.location,
                        required: true,
                        hint: AppLocalizations.of(context)!.locationExample,
                      ),
                      _farmField(
                        areaController,
                        AppLocalizations.of(context)!.areaHectares,
                        number: true,
                        hint: AppLocalizations.of(context)!.areaExample,
                      ),
                      _farmField(
                        soilController,
                        AppLocalizations.of(context)!.soilType,
                        hint: AppLocalizations.of(context)!.soilExample,
                      ),
                      _farmField(
                        irrigationController,
                        AppLocalizations.of(context)!.irrigationType,
                        hint: AppLocalizations.of(context)!.irrigationExample,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: const TextStyle(color: _muted),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  final areaText = areaController.text.trim();

                  Navigator.pop(dialogContext, {
                    'name': nameController.text.trim(),
                    'location': locationController.text.trim(),
                    'area': areaText.isEmpty ? null : double.parse(areaText),
                    'soil': _optionalValue(soilController.text),
                    'irrigation': _optionalValue(irrigationController.text),
                  });
                },
                child: Text(AppLocalizations.of(context)!.saveFarm),
              ),
            ],
          );
        },
      );

      if (values == null || !mounted) return;

      setState(() => _saving = true);

      try {
        final farm = await _api.createFarm(
          Farm(
            id: '',
            name: values['name'] as String,
            location: values['location'] as String,
            areaHectares: values['area'] as double?,
            soilType: values['soil'] as String?,
            irrigationType: values['irrigation'] as String?,
          ),
        );

        if (!mounted) return;

        setState(() {
          _farms.insert(0, farm);
          _saving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.farmAdded)),
        );
      } catch (e) {
        if (!mounted) return;

        setState(() => _saving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.farmSaveError(e.toString()),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      nameController.dispose();
      locationController.dispose();
      areaController.dispose();
      soilController.dispose();
      irrigationController.dispose();
    }
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _farmField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: _forest),
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: _muted),
          hintStyle: const TextStyle(color: _muted),
          filled: true,
          fillColor: _cream,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDCE3D9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (required && text.length < 2) {
            return AppLocalizations.of(context)!.enterTwoChars;
          }

          if (number && text.isNotEmpty) {
            final parsed = double.tryParse(text);

            if (parsed == null || parsed <= 0) {
              return AppLocalizations.of(context)!.enterPositiveNumber;
            }
          }

          return null;
        },
      ),
    );
  }

  void _showFarmDetails(Farm farm) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          farm.name,
          style: const TextStyle(color: _forest, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _farmDetail(AppLocalizations.of(context)!.location, farm.location),
            _farmDetail(
              AppLocalizations.of(context)!.area,
              farm.areaHectares == null
                  ? AppLocalizations.of(context)!.notSpecified
                  : '${farm.areaHectares} ${AppLocalizations.of(context)!.hectares}',
            ),
            _farmDetail(
              AppLocalizations.of(context)!.soilType,
              farm.soilType ?? AppLocalizations.of(context)!.notSpecified,
            ),
            _farmDetail(
              AppLocalizations.of(context)!.irrigationType,
              farm.irrigationType ?? AppLocalizations.of(context)!.notSpecified,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context)!.close,
              style: const TextStyle(color: _forest),
            ),
          ),
        ],
      ),
    );
  }

  Widget _farmDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _forest,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 85),
        const Icon(Icons.agriculture_rounded, size: 65, color: _green),
        const SizedBox(height: 18),
        Center(
          child: Text(
            AppLocalizations.of(context)!.noFarms,
            style: TextStyle(
              color: _forest,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              AppLocalizations.of(context)!.addFirstFarm,
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _farmList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
      itemCount: _farms.length,
      itemBuilder: (context, index) {
        final farm = _farms[index];

        return Card(
          color: Colors.white,
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            onTap: () => _showFarmDetails(farm),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const CircleAvatar(
              backgroundColor: _lightGreen,
              child: Icon(Icons.agriculture_rounded, color: _forest),
            ),
            title: Text(
              farm.name,
              style: const TextStyle(
                color: _forest,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              farm.location,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
            trailing: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: _forest,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _addFarm,
        backgroundColor: _forest,
        foregroundColor: Colors.white,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add),
        label: Text(
          _saving
              ? AppLocalizations.of(context)!.save
              : AppLocalizations.of(context)!.addFarm,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              title: AppLocalizations.of(context)!.yourFarms,
              subtitle: AppLocalizations.of(context)!.manageFarms,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _forest),
                    )
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 48,
                              color: _muted,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _forest),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: _loadFarms,
                              style: FilledButton.styleFrom(
                                backgroundColor: _forest,
                              ),
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                AppLocalizations.of(context)!.tryAgain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFarms,
                      child: _farms.isEmpty ? _emptyState() : _farmList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// ASSISTANT PAGE
// --------------------------------------------------

class _AssistantPage extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _AssistantPage({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _PageHeader(
              title: AppLocalizations.of(context)!.assistant,
              subtitle: AppLocalizations.of(context)!.fieldDescription,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: SizedBox(
                height: 218,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=1200&auto=format&fit=crop&q=85',
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFF315B43)),
                      errorWidget: (_, __, ___) =>
                          Container(color: const Color(0xFF315B43)),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: .12),
                            const Color(0xFF102D23).withValues(alpha: .92),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.fieldIntelligence,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.fieldTagline,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            AppLocalizations.of(context)!.fieldDescription,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _VoiceAssistantCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DerjaVoiceScreen()),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              AppLocalizations.of(context)!.exploreTools,
              style: TextStyle(
                color: _forest,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _AssistantActionTile(
              icon: Icons.wb_sunny_rounded,
              title: AppLocalizations.of(context)!.weather,
              subtitle: AppLocalizations.of(context)!.weatherOutlookSubtitle,
              onTap: () => onNavigate(5),
            ),
            const SizedBox(height: 10),
            _AssistantActionTile(
              icon: Icons.document_scanner_rounded,
              title: AppLocalizations.of(context)!.diagnosis,
              subtitle: AppLocalizations.of(context)!.diagnosisSubtitle,
              onTap: () => onNavigate(4),
            ),
            const SizedBox(height: 10),
            _AssistantActionTile(
              icon: Icons.water_drop_rounded,
              title: AppLocalizations.of(context)!.irrigation,
              subtitle: AppLocalizations.of(context)!.irrigationSubtitle,
              onTap: () => onNavigate(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceAssistantCard extends StatelessWidget {
  final VoidCallback onTap;
  const _VoiceAssistantCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE5EEE4),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _forest,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.talkToAethera,
                      style: TextStyle(
                        color: _forest,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.voiceAssistantDescription,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: _forest),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AssistantActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: _lightGreen,
                child: Icon(icon, color: _forest),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _forest,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: _green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsPage extends ConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final language = settings.locale.languageCode;
    final languageLabel = language == 'fr'
        ? l10n.french
        : language == 'ar'
        ? l10n.arabic
        : l10n.english;
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 36),
          children: [
            Text(
              l10n.settings,
              style: const TextStyle(
                color: _forest,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(l10n.preferences, style: const TextStyle(color: _muted)),
            const SizedBox(height: 24),
            _SettingsGroup(
              title: l10n.preferences,
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: _green),
                  title: Text(l10n.language),
                  subtitle: Text(languageLabel),
                  trailing: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                  ),
                  onTap: () => _chooseLanguage(context, ref, language, l10n),
                ),
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: _green),
                  title: Text(l10n.theme),
                  subtitle: Text(_themeLabel(settings.themeMode, l10n)),
                  trailing: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                  ),
                  onTap: () =>
                      _chooseTheme(context, ref, settings.themeMode, l10n),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode, AppLocalizations l10n) => switch (mode) {
    ThemeMode.light => l10n.light,
    ThemeMode.dark => l10n.dark,
    _ => l10n.system,
  };

  Future<void> _chooseLanguage(
    BuildContext context,
    WidgetRef ref,
    String current,
    AppLocalizations l10n,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.chooseLanguage),
        children: [
          for (final entry in {
            'en': l10n.english,
            'fr': l10n.french,
            'ar': l10n.arabic,
          }.entries)
            RadioListTile<String>(
              value: entry.key,
              groupValue: current,
              title: Text(entry.value),
              onChanged: (value) => Navigator.pop(ctx, value),
            ),
        ],
      ),
    );
    if (selected != null)
      await ref.read(appSettingsProvider.notifier).setLanguage(selected);
  }

  Future<void> _chooseTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
    AppLocalizations l10n,
  ) async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.chooseTheme),
        children: [
          for (final entry in [
            (ThemeMode.system, l10n.system),
            (ThemeMode.light, l10n.light),
            (ThemeMode.dark, l10n.dark),
          ])
            RadioListTile<ThemeMode>(
              value: entry.$1,
              groupValue: current,
              title: Text(entry.$2),
              onChanged: (value) => Navigator.pop(ctx, value),
            ),
        ],
      ),
    );
    if (selected != null)
      await ref.read(appSettingsProvider.notifier).setTheme(selected);
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
          child: Text(
            title,
            style: const TextStyle(
              color: _green,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        ...children,
      ],
    ),
  );
}

class _ProfilePage extends ConsumerWidget {
  const _ProfilePage();
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logoutQuestion),
        content: Text(AppLocalizations.of(context)!.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _forest),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppLocalizations.of(context)!.logout),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(authApiServiceProvider).logout();
    } finally {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context)!;

    final languageName = switch (settings.locale.languageCode) {
      'fr' => l10n.french,
      'ar' => l10n.arabic,
      _ => l10n.english,
    };

    void showInfo(String title, String message) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            title,
            style: const TextStyle(color: _forest, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: const TextStyle(color: _muted, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                AppLocalizations.of(context)!.close,
                style: const TextStyle(color: _forest),
              ),
            ),
          ],
        ),
      );
    }

    Future<void> showLanguageDialog() async {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            l10n.chooseLanguage,
            style: const TextStyle(color: _forest, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageOption(
                dialogContext,
                ref,
                'en',
                l10n.english,
                settings.locale.languageCode,
              ),
              _languageOption(
                dialogContext,
                ref,
                'fr',
                l10n.french,
                settings.locale.languageCode,
              ),
              _languageOption(
                dialogContext,
                ref,
                'ar',
                l10n.arabic,
                settings.locale.languageCode,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              title: l10n.profile,
              subtitle: l10n.manageAccountPreferences,
            ),
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: _lightGreen,
                    child: Icon(Icons.person_rounded, size: 45, color: _forest),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'AETHERA Farmer',
                    style: TextStyle(
                      color: _forest,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    l10n.farmerAccount,
                    style: const TextStyle(color: _muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _profileItem(
              Icons.person_outline,
              l10n.personalInformation,
              context: context,
              onTap: () => showInfo(
                l10n.personalInformation,
                l10n.personalInformationMessage,
              ),
            ),
            _profileItem(
              Icons.language,
              l10n.language,
              context: context,
              trailingText: languageName,
              onTap: showLanguageDialog,
            ),
            _profileItem(
              Icons.help_outline,
              l10n.helpSupport,
              context: context,
              onTap: () => showInfo(l10n.helpSupport, l10n.helpSupportMessage),
            ),
            _profileItem(
              Icons.logout_rounded,
              l10n.logout,
              context: context,
              onTap: () => _logout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(
    BuildContext dialogContext,
    WidgetRef ref,
    String code,
    String label,
    String selectedCode,
  ) {
    final selected = selectedCode == code;

    return ListTile(
      onTap: () async {
        await ref.read(appSettingsProvider.notifier).setLanguage(code);

        if (dialogContext.mounted) {
          Navigator.pop(dialogContext);
        }
      },
      title: Text(label, style: const TextStyle(color: _forest)),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? _green : _muted,
      ),
    );
  }

  Widget _profileItem(
    IconData icon,
    String title, {
    required BuildContext context,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22),
      leading: Icon(icon, color: _green),
      title: Text(
        title,
        style: const TextStyle(color: _forest, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          const SizedBox(width: 8),
          Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left
                : Icons.chevron_right,
            color: _muted,
          ),
        ],
      ),
    );
  }
}
