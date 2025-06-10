// lib/widgets/pokemon_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pokemon.dart';
import '../screens/pokemon_detail_screen.dart';
import '../services/pokeapi_service.dart';

class PokemonCard extends StatefulWidget {
  final Map<String, dynamic> pokemonListItem;
  final PokeApiService pokeApiService;

  const PokemonCard({
    Key? key,
    required this.pokemonListItem,
    required this.pokeApiService,
  }) : super(key: key);

  @override
  State<PokemonCard> createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _extractIdFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.pathSegments[uri.pathSegments.length - 2];
  }

  Color _getTypeColor(int pokemonId) {
    // Simplified type color based on ID ranges
    final colors = [
      Colors.green.shade400,    // Grass
      Colors.red.shade400,      // Fire  
      Colors.blue.shade400,     // Water
      Colors.yellow.shade400,   // Electric
      Colors.purple.shade400,   // Poison
      Colors.brown.shade400,    // Ground
      Colors.pink.shade400,     // Fairy
      Colors.indigo.shade400,   // Psychic
      Colors.orange.shade400,   // Fighting
      Colors.grey.shade400,     // Normal
    ];
    return colors[pokemonId % colors.length];
  }

  List<Color> _getGradientColors(int pokemonId) {
    final baseColor = _getTypeColor(pokemonId);
    return [
      baseColor.withOpacity(0.3),
      baseColor.withOpacity(0.1),
      Colors.white.withOpacity(0.8),
    ];
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final String pokemonName = widget.pokemonListItem['name'] ?? 'Unknown';
    final String pokemonId = _extractIdFromUrl(widget.pokemonListItem['url'] ?? '');
    final int id = int.tryParse(pokemonId) ?? 0;
    final String imageUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png';
    
    final String heroTag = 'pokemon-$pokemonId';
    final gradientColors = _getGradientColors(id);

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 200 + (id % 10) * 50),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: Material(
                      elevation: _isPressed ? 2 : 8,
                      borderRadius: BorderRadius.circular(20),
                      shadowColor: gradientColors[0].withOpacity(0.3),
                      child: GestureDetector(
                        onTapDown: _onTapDown,
                        onTapUp: _onTapUp,
                        onTapCancel: _onTapCancel,
                        onTap: () async {
                          try {
                            HapticFeedback.mediumImpact();
                            final Pokemon detailedPokemon = await widget.pokeApiService
                                .fetchPokemonDetails(widget.pokemonListItem['url']);
                            
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      PokemonDetailScreen(
                                    pokemon: detailedPokemon,
                                    heroTag: heroTag,
                                  ),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SlideTransition(
                                      position: animation.drive(
                                        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                                            .chain(CurveTween(curve: Curves.easeInOut)),
                                      ),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text('Gagal memuat detail: ${e.toString()}')),
                                    ],
                                  ),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Decorative circles
                              Positioned(
                                top: -20,
                                right: -20,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -30,
                                left: -30,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                              ),
                              
                              // Pokemon ID Badge
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '#${pokemonId.padLeft(3, '0')}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                          color: Colors.black26,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Pokemon Image
                              Positioned(
                                top: 20,
                                left: 0,
                                right: 0,
                                child: Hero(
                                  tag: heroTag,
                                  child: Container(
                                    height: 100,
                                    padding: const EdgeInsets.all(8),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.catching_pokemon,
                                          color: Colors.grey.shade400,
                                          size: 40,
                                        ),
                                      ),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            padding: const EdgeInsets.all(8),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                gradientColors[0],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              // Pokemon Name Section
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, -2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        pokemonName[0].toUpperCase() + pokemonName.substring(1),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 3,
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: gradientColors[0],
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Tap feedback overlay
                              if (_isPressed)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}