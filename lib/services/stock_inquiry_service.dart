
// Fixed version of stock_inquiry_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/part.dart';

class StockInquiryService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<String> _searchHistory = [];
  DateTime? _lastStockCheck;
  final Map<String, DateTime> _partLastUpdated = {};

  List<String> get searchHistory => _searchHistory;
  DateTime? get lastStockCheck => _lastStockCheck;

  // FIXED: Real-time stock inquiry
  Future<List<Part>> getRealTimeStock({
    String? query,
    String? category,
    int? minStock,
    int? maxStock,
    double? minPrice,
    double? maxPrice,
    String? status,
    String? warehouseBay,
    String? shelfNumber,
  }) async {
    try {
      var queryBuilder = _supabase.from('parts').select();

      // Text search across multiple fields
      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.or(
            'name.ilike.%$query%,part_number.ilike.%$query%,category.ilike.%$query%'
        );
        _addToSearchHistory(query);
      }

      // Category filter
      if (category != null && category != 'All') {
        queryBuilder = queryBuilder.ilike('category', '%$category%');
      }

      // Stock level filters
      if (minStock != null) {
        queryBuilder = queryBuilder.gte('quantity', minStock);
      }
      if (maxStock != null) {
        queryBuilder = queryBuilder.lte('quantity', maxStock);
      }

      // Price filters
      if (minPrice != null) {
        queryBuilder = queryBuilder.gte('pricing', minPrice);
      }
      if (maxPrice != null) {
        queryBuilder = queryBuilder.lte('pricing', maxPrice);
      }

      // Status filter
      if (status != null && status != 'All') {
        queryBuilder = queryBuilder.eq('status', status.toLowerCase());
      }

      // Location filters
      if (warehouseBay != null) {
        queryBuilder = queryBuilder.eq('warehouse_bay', warehouseBay);
      }

      if (shelfNumber != null) {
        queryBuilder = queryBuilder.eq('shelf_number', shelfNumber);
      }

      // FIXED: Proper type casting
      final response = await queryBuilder.order('name') as List;

      final results = response
          .map<Part>((json) => Part.fromJson(json as Map<String, dynamic>))
          .toList();

      _lastStockCheck = DateTime.now();
      notifyListeners();

      return results;
    } catch (e) {
      print('Error in getRealTimeStock: $e'); // Add debugging
      throw Exception('Error getting real-time stock: $e');
    }
  }

  // FIXED: Get parts by stock status
  Future<Map<String, List<Part>>> getPartsByStockStatus() async {
    try {
      final response = await _supabase
          .from('parts')
          .select()
          .order('name') as List;

      final allParts = response
          .map<Part>((json) => Part.fromJson(json as Map<String, dynamic>))
          .toList();

      Map<String, List<Part>> categorizedParts = {
        'out_of_stock': [],
        'low_stock': [],
        'normal_stock': [],
        'high_stock': [],
      };

      for (Part part in allParts) {
        if (part.quantity == 0) {
          categorizedParts['out_of_stock']!.add(part);
        } else if (part.quantity < 5) {
          categorizedParts['low_stock']!.add(part);
        } else if (part.quantity < 20) {
          categorizedParts['normal_stock']!.add(part);
        } else {
          categorizedParts['high_stock']!.add(part);
        }
      }

      return categorizedParts;
    } catch (e) {
      print('Error in getPartsByStockStatus: $e');
      throw Exception('Error categorizing stock: $e');
    }
  }

  // FIXED: Get dashboard data with better error handling
  Future<Map<String, dynamic>> getStockInquiryDashboard() async {
    try {
      final allParts = await getRealTimeStock();

      final totalParts = allParts.length;
      final inStockParts = allParts.where((part) => part.quantity > 0).length;
      final lowStockParts = allParts.where((part) => part.quantity > 0 && part.quantity < 5).length;
      final outOfStockParts = allParts.where((part) => part.quantity == 0).length;
      final totalValue = allParts.fold(0.0, (sum, part) => sum + (part.pricing * part.quantity));

      // Get location statistics
      final partsWithLocation = allParts.where((part) =>
      part.warehouseBay != null && part.shelfNumber != null).length;
      final partsWithoutLocation = totalParts - partsWithLocation;

      return {
        'total_parts': totalParts,
        'in_stock_parts': inStockParts,
        'low_stock_parts': lowStockParts,
        'out_of_stock_parts': outOfStockParts,
        'total_inventory_value': totalValue,
        'parts_with_location': partsWithLocation,
        'parts_without_location': partsWithoutLocation,
        'stock_health_percentage': totalParts > 0 ? (inStockParts / totalParts * 100) : 0,
        'location_completion_percentage': totalParts > 0 ? (partsWithLocation / totalParts * 100) : 0,
        'last_updated': DateTime.now(),
      };
    } catch (e) {
      print('Error in getStockInquiryDashboard: $e');
      throw Exception('Error getting dashboard data: $e');
    }
  }

  // FIXED: Low stock alerts
  Future<List<Part>> getLowStockAlerts({int threshold = 5}) async {
    try {
      final response = await _supabase
          .from('parts')
          .select()
          .lt('quantity', threshold)
          .gt('quantity', 0)
          .order('quantity') as List;

      return response
          .map<Part>((json) => Part.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error in getLowStockAlerts: $e');
      throw Exception('Error getting low stock alerts: $e');
    }
  }

  // FIXED: Stock valuation by category
  Future<Map<String, double>> getStockValuationByCategory() async {
    try {
      final response = await _supabase
          .from('parts')
          .select('category, quantity, pricing') as List;

      final parts = response
          .map<Part>((json) => Part.fromJson(json as Map<String, dynamic>))
          .toList();

      Map<String, double> valuationMap = {};

      for (Part part in parts) {
        final category = part.category;
        final value = part.quantity * part.pricing;

        if (!valuationMap.containsKey(category)) {
          valuationMap[category] = 0;
        }
        valuationMap[category] = valuationMap[category]! + value;
      }

      return valuationMap;
    } catch (e) {
      print('Error in getStockValuationByCategory: $e');
      throw Exception('Error calculating stock valuation: $e');
    }
  }

  // Search history management
  void _addToSearchHistory(String query) {
    if (query.trim().isEmpty) return;

    _searchHistory.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
    _searchHistory.insert(0, query.trim());

    // Keep only last 10 searches
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.take(10).toList();
    }

    notifyListeners();
  }

  void clearSearchHistory() {
    _searchHistory.clear();
    notifyListeners();
  }
}
