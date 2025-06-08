// lib/widgets/pokemon_card.dart

import 'package:flutter/material.dart';
import '../models/pokemon.dart'; // Jika Anda memiliki model Pokemon yang sudah lengkap
import '../screens/pokemon_detail_screen.dart';
import '../services/pokeapi_service.dart';

class PokemonCard extends StatelessWidget {
  final Map<String, dynamic> pokemonListItem; // Berisi 'name' dan 'url'
  final PokeApiService pokeApiService;

  const PokemonCard({
    Key? key,
    required this.pokemonListItem,
    required this.pokeApiService,
  }) : super(key: key);

  // Fungsi untuk mengambil ID dari URL
  String _extractIdFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.pathSegments[uri.pathSegments.length - 2];
  }

  @override
  Widget build(BuildContext context) {
    final String pokemonName = pokemonListItem['name'] ?? 'Unknown';
    final String pokemonId = _extractIdFromUrl(pokemonListItem['url'] ?? '');
    final String imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$pokemonId.png';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () async {
          try {
            // Ambil detail lengkap sebelum navigasi
            Pokemon detailedPokemon = await pokeApiService.fetchPokemonDetails(pokemonListItem['url']);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PokemonDetailScreen(pokemon: detailedPokemon),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memuat detail: ${e.toString()}')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Image.network(
                imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.error, size: 70),
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  pokemonName[0].toUpperCase() + pokemonName.substring(1),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '#$pokemonId',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}