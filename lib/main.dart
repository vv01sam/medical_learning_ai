import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medical_learning_ai/generated/app_localizations.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/learning_session_screen.dart';
import 'screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebaseの初期化
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Initialization failed: ${e.toString()}");
    runApp(ErrorApp(message: "Initialization failed: ${e.toString()}"));
    return;
  }

  final remoteConfig = FirebaseRemoteConfig.instance;

  // Remote Configの設定
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: Duration(seconds: 10),
    minimumFetchInterval: Duration(hours: 1),
  ));

  // デフォルト値を設定
  await remoteConfig.setDefaults(<String, dynamic>{
    'api_key': 'default_value',
  });

  // リモート設定を取得
  try {
    await remoteConfig.fetchAndActivate();
    print("Remote Config fetched and activated successfully");
  } catch (e) {
    print("Remote Config fetch failed: $e");
  }

  String apiKey = remoteConfig.getString('api_key');
  print("API Key: $apiKey");

  // 現在のユーザーを取得
  firebase_auth.User? currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

  // Load saved language or use device locale
  final prefs = await SharedPreferences.getInstance();
  final savedLanguageCode = prefs.getString('language_code');
  
  // デバイスの言語設定を優先
  Locale initialLocale = WidgetsBinding.instance.window.locales.first;
  
  // サポートされている言語のリスト
  final supportedLanguages = ['en', 'ja'];
  
  // デバイスの言語がサポートされていない場合のみ、保存された言語を使用
  if (!supportedLanguages.contains(initialLocale.languageCode) && savedLanguageCode != null) {
    initialLocale = Locale(savedLanguageCode);
  }

  print("Initial locale: $initialLocale");

  final authService = AuthService();
  final bool shouldAutoLogin = await authService.shouldAutoLogin();

  runApp(MyApp(
    apiKey: apiKey,
    vertexAI: FirebaseVertexAI.instance,
    initialLocale: initialLocale,
    initialRoute: shouldAutoLogin ? '/home' : '/login'
  ));
}

class ErrorApp extends StatelessWidget {
  final String message;

  ErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(message),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final String apiKey;
  final FirebaseVertexAI vertexAI;
  final Locale initialLocale;
  final String initialRoute;

  MyApp({
    required this.apiKey,
    required this.vertexAI,
    required this.initialLocale,
    required this.initialRoute
  });

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }
  

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en'),
        Locale('ja'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        print("Resolving locale: $locale");
        print("Supported locales: $supportedLocales");
        
        if (locale == null) {
          print("Locale is null, returning first supported locale");
          return supportedLocales.first;
        }
        
        // デバイスの言語がサポートされている場合はそれを使用
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            print("Matched supported locale: $supportedLocale");
            return supportedLocale;
          }
        }
        
        // サポートされていない場合はデフォルト（英語）を使用
        print("No matching locale found, returning default locale (English)");
        return Locale('en');
      },
      theme: ThemeData(
        primaryColor: Color(0xFF4897D8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF4897D8),
          primary: Color(0xFF4897D8),
          secondary: Color(0xFFFFDB5C),
          tertiary: Color(0xFFF8A055),
          error: Color(0xFFFA6E59),
          background: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32.0,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'RoundedMplus1c',
          ),
          titleLarge: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'RoundedMplus1c',
          ),
          bodyMedium: TextStyle(
            fontSize: 16.0,
            color: Colors.black54,
            fontFamily: 'RoundedMplus1c',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFA6E59),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            elevation: 5,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'RoundedMplus1c',
          ),
          iconTheme: IconThemeData(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 5,
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF8A055),
          size: 28,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFDB5C),
          foregroundColor: Colors.black87,
        ),
      ),
      initialRoute: widget.initialRoute,
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/learning_session': (context) =>
            LearningSessionScreen(deckId: 'defaultDeckId'),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}