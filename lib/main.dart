import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'core/monetization_config.dart';
import 'core/ad_service.dart';
import 'core/iap_service.dart';
import 'core/auth_service.dart';
import 'core/dps_engine.dart';
import 'core/audio_player_service.dart';
import 'core/preset_repository.dart';
import 'ui/screens/auth_gate_screen.dart';
import 'ui/screens/home_player_screen.dart';
import 'ui/screens/dps_studio_screen.dart';
import 'ui/screens/community_presets_screen.dart';
import 'ui/screens/profile_settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase conditionally
  if (MonetizationConfig.firebaseEnabled) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[Main] Firebase init error: $e');
    }
  }

  // Initialize background audio notifications & foreground service
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.squareinfosoft.auramix.channel.audio',
      androidNotificationChannelName: 'AuraMix DSP Sound Engine',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );
  } catch (e) {
    debugPrint('[Main] JustAudioBackground init error: $e');
  }

  // Audio session configuration for background & high-fidelity playback
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  } catch (e) {
    debugPrint('[Main] AudioSession error: $e');
  }

  // Set system UI overlay colors for futuristic dark cockpit feel
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090A13),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize core services
  await IAPService.instance.initialize();
  await AuthService.instance.initialize();
  await AdService.instance.initialize();
  await DPSEngine.instance.initialize();
  await AudioPlayerService.instance.initialize();
  await PresetRepository.instance.initialize();

  runApp(const AuraMixApp());
}

class AuraMixApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  const AuraMixApp({super.key});

  @override
  State<AuraMixApp> createState() => _AuraMixAppState();
}

class _AuraMixAppState extends State<AuraMixApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AuraMixApp.navigatorKey,
      title: 'AuraMix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: ValueListenableBuilder(
        valueListenable: AuthService.instance.currentUserNotifier,
        builder: (context, user, _) {
          if (user == null) {
            return AuthGateScreen(
              onAuthenticated: () => setState(() {}),
            );
          }
          return MainShell(
            onSignOut: () => setState(() {}),
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onSignOut;

  const MainShell({super.key, required this.onSignOut});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePlayerScreen(
        onOpenDPSStudio: () => setState(() => _selectedIndex = 1),
      ),
      const DPSStudioScreen(),
      const CommunityPresetsScreen(),
      ProfileSettingsScreen(onSignOut: widget.onSignOut),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F1C),
          border: Border(
            top: BorderSide(color: Colors.white.withAlpha(18), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(160),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.play_circle_filled_rounded,
                  label: 'Player',
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavBarItem(
                  icon: Icons.equalizer_rounded,
                  label: 'DPS Studio',
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _NavBarItem(
                  icon: Icons.language_rounded,
                  label: 'Community',
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _NavBarItem(
                  icon: Icons.person_rounded,
                  label: 'Pilot VIP',
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonCyan.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? Border.all(color: AppTheme.neonCyan.withAlpha(90), width: 1.2) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.neonCyan.withAlpha(60),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.neonCyan : Colors.white54,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.neonCyan : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
