import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_tarot_jp/routers/app_router.dart';
import 'package:mystic_tarot_jp/themes/theme.dart';
import 'package:mystic_tarot_jp/core/l10n/localization_service.dart';
import 'package:mystic_tarot_jp/themes/dynamic_tokens.dart';

class MysticTarotApp extends ConsumerWidget {
  const MysticTarotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final strings = ref.watch(appStringsProvider);
    final lang = ref.watch(localizationServiceProvider);
    final dt = ref.watch(dynamicTokensProvider);
    final baseTheme = AppTheme.lightTheme;
    final theme = baseTheme.copyWith(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: dt.primaryColor,
        selectionHandleColor: dt.primaryColor,
        selectionColor: dt.primaryColor.withOpacity(0.28),
      ),
    );
    
    return MaterialApp.router(
      title: strings.appName,
      theme: theme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
        Locale('en', 'US'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
      ],
      locale: lang.locale,
    );
  }
} 