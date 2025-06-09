// lib/widgets/pokemon_card.dart

import 'package:flutter/material.dart';
import 'dart:ui'; // Untuk ImageFilter.blur

import '../models/pokemon.dart'; // Pastikan model Pokemon Anda lengkap
import '../screens/pokemon_detail_screen.dart';
import '../services/pokeapi_service.dart';

/// Helper untuk mendapatkan warna berdasarkan tipe Pokemon.
/// Anda bisa memindahkannya ke file terpisah (misal: lib/utils/ui_helpers.dart)
Color getPokemonTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'grass':
      return Colors.green.shade400;
    case 'fire':
      return Colors.red.shade400;
    case 'water':
      return Colors.blue.shade400;
    case 'electric':
      return Colors.yellow.shade700;
    case 'psychic':
      return Colors.purple.shade400;
    case 'ice':
      return Colors.cyan.shade300;
    case 'dragon':
      return Colors.indigo.shade400;
    case 'dark':
      return Colors.brown.shade800;
    case 'fairy':
      return Colors.pink.shade300;
    case 'normal':
      return Colors.grey.shade500;
    case 'fighting':
      return Colors.orange.shade800;
    case 'flying':
      return Colors.lightBlue.shade300;
    case 'poison':
      return Colors.deepPurple.shade300;
    case 'ground':
      return Colors.brown.shade400;
    case 'rock':
      return Colors.brown.shade600;
    case 'bug':
      return Colors.lightGreen.shade500;
    case 'ghost':
      return Colors.deepPurple.shade700;
    case 'steel':
      return Colors.blueGrey.shade400;
    default:
      return Colors.grey.shade400;
  }
}

class PokemonCard extends StatelessWidget {
  final Map<String, dynamic> pokemonListItem; // Berisi 'name' dan 'url'
  final PokeApiService pokeApiService;

  const PokemonCard({
    Key? key,
    required this.pokemonListItem,
    required this.pokeApiService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Gunakan FutureBuilder untuk mengambil detail dan membangun UI secara dinamis
    return FutureBuilder<Pokemon>(
      future: pokeApiService.fetchPokemonDetails(pokemonListItem['url']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Tampilkan placeholder loading yang lebih baik
          return _buildLoadingPlaceholder();
        }
        if (snapshot.hasError) {
          // Tampilkan UI error yang informatif
          return _buildErrorPlaceholder(snapshot.error.toString());
        }
        if (snapshot.hasData) {
          final pokemon = snapshot.data!;
          // URL gambar dengan kualitas lebih tinggi
          final imageUrl =
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${pokemon.id}.png';
          final cardColor = getPokemonTypeColor(pokemon.types.first);

          // Build UI kartu yang sudah final dengan data lengkap
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PokemonDetailScreen(pokemon: pokemon),
                ),
              );
            },
            child: Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              shadowColor: cardColor.withOpacity(0.5),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                children: [
                  // --- Background Pattern (Pokeball) ---
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Opacity(
                      opacity: 0.2,
                      child: Image.asset(
                        'assets/pokeball.png', // PASTIKAN ANDA PUNYA GAMBAR INI DI assets/
                        width: 120,
                        height: 120,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  // --- Pokemon Image ---
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Hero(
                      tag: 'pokemon-${pokemon.id}', // Hero animation tag
                      child: Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        // Loading dan error builder untuk gambar utama
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : const SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0,)));
                        },
                        errorBuilder: (context, error, stackTrace) {
                           // Fallback ke sprite lama jika official artwork gagal
                           final fallbackUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemon.id}.png';
                           return Image.network(fallbackUrl, width: 90, height: 90, fit: BoxFit.contain);
                        },
                      ),
                    ),
                  ),

                  // --- Pokemon ID ---
                  Positioned(
                    top: 10,
                    right: 15,
                    child: Text(
                      '#${pokemon.id.toString().padLeft(3, '0')}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                  
                  // --- Pokemon Name & Types ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pokemon.name[0].toUpperCase() +
                              pokemon.name.substring(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Row untuk menampilkan badge tipe
                        ...pokemon.types.map((type) => TypeBadge(type: type)).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        // State default jika tidak ada data
        return _buildLoadingPlaceholder();
      },
    );
  }

  /// Widget untuk placeholder saat loading
  Widget _buildLoadingPlaceholder() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.shade300,
      child: const SizedBox(height: 130), // Sesuaikan tinggi dengan kartu asli
    );
  }

  /// Widget untuk placeholder saat terjadi error
  Widget _buildErrorPlaceholder(String error) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.red.shade200,
      child: SizedBox(
        height: 130,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 30),
              const SizedBox(height: 8),
              Text(
                'Gagal Memuat Data',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget custom untuk "badge" tipe Pokemon
class TypeBadge extends StatelessWidget {
  final String type;

  const TypeBadge({Key? key, required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type[0].toUpperCase() + type.substring(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
