import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'view/login.dart';
import 'view/main_page.dart';
import 'view/user/userhomepage.dart';
import 'services/auth_service.dart';
import 'view_models/home_view_model.dart';
import 'view/recipe/recipe_list_page.dart';
import 'view/user/searchpage.dart';
import 'view/my_recipes/my_recipes_page.dart';
import 'view/user/userprofilepage.dart';
import 'view/recipe/edit_recipe_page.dart';
import 'view_models/recipe_form_page_vm.dart';
import 'view_models/theme_view_model.dart';
import 'view/user/ai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://sfkimpdnpxghevcpxvnj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNma2ltcGRucHhnaGV2Y3B4dm5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg2Nzk0NjAsImV4cCI6MjA2NDI1NTQ2MH0.CSBv7uodAcyco-UaoC4OFSEqQE-z9gXG0ygH49FnnpQ',
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
            theme: ThemeData(
              primarySwatch: Colors.green,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.light,
              ),
              brightness: Brightness.light,
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              appBarTheme: const AppBarTheme(
                elevation: 0,
                centerTitle: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
              ),
              scaffoldBackgroundColor: Colors.white,
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Colors.white,
                selectedItemColor: Colors.green,
                unselectedItemColor: Colors.grey,
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.green,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.dark,
              ),
              brightness: Brightness.dark,
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.grey[850],
              ),
              appBarTheme: AppBarTheme(
                elevation: 0,
                centerTitle: true,
                backgroundColor: Colors.grey[900],
                foregroundColor: Colors.white,
              ),
              scaffoldBackgroundColor: Colors.grey[900],
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: Colors.grey[850],
                selectedItemColor: Colors.green,
                unselectedItemColor: Colors.grey[400],
              ),
            ),
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
