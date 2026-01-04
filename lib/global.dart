import 'package:flutter/material.dart';

// Tüm uygulamadan erişilebilen Tema Kontrolcüsü
final ValueNotifier<ThemeMode> temaModu = ValueNotifier(ThemeMode.system);