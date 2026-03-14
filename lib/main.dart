import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/map.dart';
import 'pages/photo.dart';
import 'pages/groupe.dart';
import 'pages/login.dart';

late final String webClientId;

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final anonKey     = dotenv.env['ANON_KEY']!;
  webClientId       = dotenv.env['WEB_CLIENT_ID_GOOGLE_CLOUD']!;

  await Supabase.initialize(url: supabaseUrl, anonKey: anonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SekaiAtlas',
      debugShowCheckedModeBanner: false,
      theme: RpgTheme.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null ? const MyHomePage() : const LoginPage();
  }
}

// ─────────────────────────────────────────────
//  HOME
// ─────────────────────────────────────────────
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  // Page photo (index 1) par défaut
  int _currentIndex = 1;

  static const _pages = <Widget>[
    MapPage(),
    TakePictureScreen(),
    GroupePage(),
  ];

  // Données des onglets
  static const _tabs = [
    _TabData(icon: Icons.map_outlined,      activeIcon: Icons.map,          label: 'Carte'),
    _TabData(icon: Icons.photo_camera_outlined, activeIcon: Icons.photo_camera, label: 'Photo'),
    _TabData(icon: Icons.people_outline,    activeIcon: Icons.people,       label: 'Guilde'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _RpgNavBar(
        currentIndex: _currentIndex,
        tabs: _tabs,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  RPG NAV BAR
// ─────────────────────────────────────────────
class _TabData {
  final IconData icon, activeIcon;
  final String label;
  const _TabData({required this.icon, required this.activeIcon, required this.label});
}

class _RpgNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabData> tabs;
  final ValueChanged<int> onTap;

  const _RpgNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBgCard2,
        border: Border(top: BorderSide(color: kPrimary.withOpacity(0.25), width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final selected = i == currentIndex;
              // Le bouton central (Photo) est mis en avant
              final isCenter = i == 1;
              return Expanded(
                child: isCenter
                    ? _CenterTab(
                        tab: tabs[i],
                        selected: selected,
                        onTap: () => onTap(i),
                      )
                    : _SideTab(
                        tab: tabs[i],
                        selected: selected,
                        onTap: () => onTap(i),
                      ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Onglet latéral (Map / Guilde) ─────────────
class _SideTab extends StatelessWidget {
  final _TabData tab;
  final bool selected;
  final VoidCallback onTap;
  const _SideTab({required this.tab, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kPrimary.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? tab.activeIcon : tab.icon,
                key: ValueKey(selected),
                color: selected ? kPrimary : kTextMid,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? kPrimary : kTextMid,
                letterSpacing: 0.3,
              ),
            ),
            // Indicateur actif
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: selected ? 20 : 0,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Onglet central (Photo) mis en avant ───────
class _CenterTab extends StatelessWidget {
  final _TabData tab;
  final bool selected;
  final VoidCallback onTap;
  const _CenterTab({required this.tab, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton surélevé
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kPrimary, kPrimaryLt],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kBgCard, kBgCard2],
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? kPrimary : kBorder,
                width: selected ? 2 : 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              selected ? tab.activeIcon : tab.icon,
              color: selected ? Colors.white : kTextMid,
              size: 26,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              color: selected ? kPrimary : kTextMid,
              letterSpacing: 0.3,
            ),
          ),
          // Indicateur (transparent pour garder l'alignement)
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}