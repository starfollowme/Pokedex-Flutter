// lib/widgets/pokemon_card.dart

import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../screens/pokemon_detail_screen.dart';
import '../services/pokeapi_service.dart';

class PokemonCard extends StatelessWidget {
  final Map<String, dynamic> pokemonListItem;
  final PokeApiService pokeApiService;

  const PokemonCard({
    Key? key,
    required this.pokemonListItem,
    required this.pokeApiService,
  }) : super(key: key);

  String _extractIdFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.pathSegments[uri.pathSegments.length - 2];
  }

  @override
  Widget build(BuildContext context) {
    final String pokemonName = pokemonListItem['name'] ?? 'Unknown';
    final String pokemonId = _extractIdFromUrl(pokemonListItem['url'] ?? '');
    final String imageUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png';

    // Hero tag yang unik untuk transisi animasi
    final String heroTag = 'pokemon-$pokemonId';

    return Card(
      child: InkWell(
        onTap: () async {
          try {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            Pokemon detailedPokemon =
                await pokeApiService.fetchPokemonDetails(pokemonListItem['url']);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PokemonDetailScreen(
                  pokemon: detailedPokemon,
                  heroTag: heroTag,
                ),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memuat detail: ${e.toString()}')),
            );
          }
        },
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.grey.shade200.withOpacity(0.4),
                  ],
                ),
              ),
            ),
            // Pokemon Image
            Hero(
              tag: heroTag,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                height: 120,
                width: 120,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.error, color: Colors.red)),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
              ),
            ),
            // Pokemon ID
            Positioned(
              top: 8,
              right: 8,
              child: Text(
                '#$pokemonId',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            // Pokemon Name
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16.0),
                    bottomRight: Radius.circular(16.0),
                  ),
                ),
                child: Text(
                  pokemonName[0].toUpperCase() + pokemonName.substring(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}