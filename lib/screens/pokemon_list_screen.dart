// lib/screens/pokemon_list_screen.dart

import 'package:flutter/material.dart';
import '../services/pokeapi_service.dart';
import '../widgets/pokemon_card.dart'; // Gunakan PokemonCard yang baru
// import '../models/pokemon.dart'; // Tidak perlu jika PokemonCard menangani detail fetch

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({Key? key}) : super(key: key);

  @override
  _PokemonListScreenState createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  final PokeApiService _pokeApiService = PokeApiService();
  List<Map<String, dynamic>> _pokemonList = []; // Menyimpan list item {'name': ..., 'url': ...}
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _offset = 0;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchInitialPokemon();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialPokemon() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final initialList = await _pokeApiService.fetchPokemonList(limit: _limit, offset: 0);
      setState(() {
        _pokemonList = initialList;
        _offset = _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error (e.g., show a snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat Pokémon: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchMorePokemon() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final morePokemon = await _pokeApiService.fetchPokemonList(limit: _limit, offset: _offset);
      setState(() {
        _pokemonList.addAll(morePokemon);
        _offset += _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat lebih banyak Pokémon: ${e.toString()}')),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore) {
      _fetchMorePokemon();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokedex Flutter'),
        backgroundColor: Colors.redAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchInitialPokemon,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _pokemonList.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _pokemonList.length) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final pokemonItem = _pokemonList[index];
                  return PokemonCard(
                    pokemonListItem: pokemonItem,
                    pokeApiService: _pokeApiService,
                  );
                },
              ),
            ),
    );
  }
}