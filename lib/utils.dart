import 'package:kchat/firebase_options.dart';
import 'package:kchat/services/auth_service.dart';
import 'package:kchat/services/bot_service.dart';
import 'package:kchat/services/chat_service.dart';
import 'package:kchat/services/cloud_service.dart';
import 'package:kchat/services/media_service.dart';
import 'package:kchat/services/activeUser_service.dart';
import 'package:kchat/services/navigation_service.dart';
import 'package:kchat/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> setupSupabase() async {
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
}

Future<void> setupFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> registerServices() async {
  final GetIt getIt = GetIt.instance;

  getIt.registerSingleton<AuthService>(AuthService());

  getIt.registerSingleton<NavigationService>(NavigationService());

  getIt.registerSingleton<MediaService>(MediaService());

  getIt.registerSingleton<CloudService>(CloudService());

  getIt.registerSingleton<ChatService>(ChatService());

  getIt.registerSingleton<NotificationService>(NotificationService());

  getIt.registerSingleton<ActiveUserService>(ActiveUserService());

  getIt.registerSingleton<BotService>(BotService());
}
