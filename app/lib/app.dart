import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'features/auth/login_page.dart';

class ColonelApp extends StatelessWidget {
  const ColonelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: red,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CP POS 6.5',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: bg,
        fontFamily: 'sans-serif-condensed',
        visualDensity: VisualDensity.standard,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(fontWeight: FontWeight.w500),
          bodySmall: TextStyle(fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontWeight: FontWeight.w800),
          titleMedium: TextStyle(fontWeight: FontWeight.w800),
          titleSmall: TextStyle(fontWeight: FontWeight.w700),
          labelLarge: TextStyle(fontWeight: FontWeight.w700),
          labelMedium: TextStyle(fontWeight: FontWeight.w700),
          labelSmall: TextStyle(fontWeight: FontWeight.w700),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: red, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: red,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: ink,
            side: const BorderSide(color: line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: red.withValues(alpha: .12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? red : inkMuted,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? red : inkMuted,
              size: selected ? 25 : 23,
            );
          }),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: red.withValues(alpha: .12),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: ink),
        ),
        dividerTheme: const DividerThemeData(
          color: line,
          space: 1,
          thickness: 1,
        ),
      ),
      home: const LoginPage(),
    );
  }
}
