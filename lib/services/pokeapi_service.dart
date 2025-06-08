// lib/services/pokeapi_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokeApiService {
  final String baseUrl = 'https://pokeapi.co/api/v2/';

  Future<List<Map<String, dynamic>>> fetchPokemonList({int limit = 20, int offset = 0}) async {
    final response = await http.get(Uri.parse('${baseUrl}pokemon?limit=$limit&offset=$offset'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // PokeAPI mengembalikan daftar 'results' yang berisi nama dan URL detail
      List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(data['results']);
      return results;
    } else {
      throw Exception('Failed to load Pokemon list');
    }
  }

  Future<Pokemon> fetchPokemonDetails(String url) async {
    // Bisa juga menggunakan ID: final response = await http.get(Uri.parse('${baseUrl}pokemon/$id/'));
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Pokemon.fromJson(data);
    } else {
      throw Exception('Failed to load Pokemon details for $url');
    }
  }
}