import 'package:flutter/material.dart';

import '../../models/festivalsDetail_model.dart';
import '../apis/getFestivals.dart';
import '../model/festivalsModel.dart';

// Import your model

class FestivalProvider extends ChangeNotifier {
  List<FestivalResource> _resourceFestivals = [];
  int _totalFestivals = 0;
  int _totalAttendees = 0;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoadingMore = false;
  bool _isLoading = false;
  List<FestivalResource> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  List<FestivalResource> get resourceFestivals => _resourceFestivals;
  int get totalFestivals => _totalFestivals;
  int get totalAttendees => _totalAttendees;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoading => _isLoading;
  bool get hasMore => _currentPage < _lastPage;
  List<FestivalResource> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;

  /// Fetch festivals (page 1 replaces list; page > 1 appends).
  Future<void> fetchFestivals(BuildContext context, {int page = 1}) async {
    if (page == 1) _isLoading = true;
    notifyListeners();

    final response = await getFestivalCollection(context, page: page);

    if (response != null) {
      _currentPage = response.currentPage;
      _lastPage = response.lastPage;
      if (page == 1) {
        _resourceFestivals = response.data;
      } else {
        _resourceFestivals = [..._resourceFestivals, ...response.data];
      }
    }

    if (page == 1) _isLoading = false;
    notifyListeners();
  }

  /// Load next page and append to list.
  Future<void> loadMore(BuildContext context) async {
    if (_isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    final response = await getFestivalCollection(context, page: _currentPage + 1);

    if (response != null) {
      _currentPage = response.currentPage;
      _lastPage = response.lastPage;
      _resourceFestivals = [..._resourceFestivals, ...response.data];
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Server-side search. Call when user types in search field (debounce in UI).
  Future<void> searchFestivals(BuildContext context, String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      _searchError = null;
      notifyListeners();
      return;
    }
    _isSearching = true;
    _searchError = null;
    notifyListeners();

    final response = await getFestivalCollection(context, page: 1, search: query.trim());

    if (response != null) {
      _searchResults = response.data;
      _searchError = null;
    } else {
      _searchResults = [];
      _searchError = 'Search failed. Please try again.';
    }

    _isSearching = false;
    notifyListeners();
  }

  /// Clear search state (e.g. when user clears search field).
  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    _searchError = null;
    notifyListeners();
  }
}
