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
      // Mengembalikan ke tema terang yang ceria
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        
        // Skema warna cerah berbasis merah
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
          brightness: Brightness.light,
        ),

        // Latar belakang utama aplikasi
        scaffoldBackgroundColor: Colors.white,

        // Tema AppBar yang berwarna
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white, // Warna untuk ikon dan judul
          elevation: 2,
        ),

        // Tema Card untuk latar belakang terang
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Colors.grey.shade200, width: 1)
          ),
          clipBehavior: Clip.antiAlias,
        ),

        // Tema untuk text field (search bar)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIconColor: Colors.grey.shade600,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      home: const PokemonListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}