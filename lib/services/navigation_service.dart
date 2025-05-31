import 'package:kchat/pages/ai_chat_page.dart';
import 'package:kchat/pages/group_chat_page.dart';
import 'package:kchat/pages/home_page.dart';
import 'package:kchat/pages/login_page.dart';
import 'package:kchat/pages/profile_page.dart';
import 'package:kchat/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:kchat/splash/splash_screen.dart';
import '../pages/notification_page.dart';

class NavigationService {
  late GlobalKey<NavigatorState> _navigatorKey;
  final Map<String, Widget Function(BuildContext)> _routes = {
    "/login": (context) => const Login(),
    "/home": (context) => const Home(),
    "/splash": (context) => const SplashScreen(),
    "/register": (context) => const RegisterPage(),
    "/profile": (context) => const ProfilePage(),
    "/notification": (context) => const NotificationPage(),
    "/aichatpage": (context) => const AIChatPage(),
    "/groupchat": (context) => const GroupChatPage(),
  };

  GlobalKey<NavigatorState>? get navigatorKey {
    return _navigatorKey;
  }

  Map<String, Widget Function(BuildContext)> get routes {
    return _routes;
  }

  NavigationService() {
    _navigatorKey = GlobalKey<NavigatorState>();
  }

  void pushNamed(String routeName) {
    _navigatorKey.currentState?.pushNamed(routeName);
  }

  void pushReplacementNamed(String routeName) {
    _navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  void goBack() {
    _navigatorKey.currentState?.pop();
  }

  void push(MaterialPageRoute route) {
    _navigatorKey.currentState?.push(route);
  }
}
