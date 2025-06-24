import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'view/login.dart';
import 'view/user/userhomepage.dart';
import 'services/auth_service.dart';
import 'view/user/searchpage.dart';
import 'view/my_recipes/my_recipes_page.dart';
import 'view/user/userprofilepage.dart';
import 'view_models/recipe_form_page_vm.dart';
import 'view_models/theme_view_model.dart';
import 'view/user/ai.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://sfkimpdnpxghevcpxvnj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNma2ltcGRucHhnaGV2Y3B4dm5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg2Nzk0NjAsImV4cCI6MjA2NDI1NTQ2MH0.CSBv7uodAcyco-UaoC4OFSEqQE-z9gXG0ygH49FnnpQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Register the clear login info function
    AuthService.clearLoginInfo();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeFormViewModel()),
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<ThemeViewModel>(create: (_) => ThemeViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeViewModel.themeMode,
            home: const SplashScreenWrapper(),
          );
        },
      ),
    );
  }
}

class SplashScreenWrapper extends StatelessWidget {
  const SplashScreenWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen.gif(
      useImmersiveMode: true,
      gifPath: 'assets/gif/recipe.gif',
      gifWidth: 269,
      gifHeight: 474,
      nextScreen: const AuthWrapper(),
      duration: const Duration(milliseconds: 3515),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.currentUser == null) {
          return LoginPage();
        }
        return const MainScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const UserHomePage(),
    const SearchPage(),
    MyRecipesPage(),
    ChatScreen(),
    UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'My Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'Chat Bot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

/*class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Waiting for connection
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        // 2. User is logged in
        if (snapshot.hasData) {
          return MainPage();
        }
        // 3. User is NOT logged in
        return LoginPage();
      },
    );
  }
}*/
