// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/pokemon_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Pokedex AI',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true, // Opsional, untuk tema Material 3
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent).copyWith(
          error: Colors.orangeAccent, // Contoh kustomisasi warna error
        ),
        cardTheme: CardTheme( // Tema global untuk Card
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 2.0,
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        )
      ),
      home: const PokemonListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}