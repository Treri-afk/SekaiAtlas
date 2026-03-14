import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/map.dart';
import 'pages/photo.dart';
import 'pages/groupe.dart';
import 'pages/login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

late final String webClientId;

Future<void> main() async {
  await dotenv.load(fileName: ".env");
 
  String SUPABASE_URL = dotenv.env['SUPABASE_URL']!;
  String ANON_KEY = dotenv.env['ANON_KEY']!;
  webClientId = dotenv.env['WEB_CLIENT_ID_GOOGLE_CLOUD']!;
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: ANON_KEY,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}

// Vérifie si l'utilisateur est connecté et redirige vers la bonne page
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Écoute les changements d'état d'authentification
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {});
    });
  }

  @override
  //Widget build(BuildContext context) {
  //  final session = Supabase.instance.client.auth.currentSession;
  //  if (session == null) {
  //    return const LoginPage();
  //  }
  //  return const MyHomePage(title: 'Flutter Demo Home Page');
  //}

   Widget build(BuildContext context) {
    // TODO : réactive ça quand tu veux la reconnexion automatique
    final session = Supabase.instance.client.auth.currentSession;
     if (session != null) {
      return const MyHomePage(title: 'Flutter Demo Home Page');
    }
    return const LoginPage();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: const Color.fromARGB(255, 23, 252, 164),
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_camera_outlined),
            label: 'Photo',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Groupes',
          ),
        ],
      ),
      body: <Widget>[
        MapPage(),
        TakePictureScreen(),
        GroupePage(),
      ][currentPageIndex],
    );
  }
}