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

  // Real-time stock inquiry - Get current stock levels
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

      final response = await queryBuilder.order('name');

      final results = response // FIXED: Removed unnecessary cast (response as List)
          .map<Part>((json) => Part.fromJson(json))
          .toList();

      _lastStockCheck = DateTime.now();
      notifyListeners();

      return results;
    } catch (e) {
      throw Exception('Error getting real-time stock: $e');
    }
  }

  // Get current stock level for specific part
  Future<int?> getCurrentStockLevel(String partId) async {
    try {
      final response = await _supabase
          .from('parts')
          .select('quantity')
          .eq('id', partId)
          .single();

      return response['quantity'] as int;
    } catch (e) {
      return null;
    }
  }

  // Check if stock data is fresh (less than 5 minutes old)
  bool isStockDataFresh(String partId) {
    final lastUpdated = _partLastUpdated[partId];
    if (lastUpdated == null) return false;

    return DateTime.now().difference(lastUpdated).inMinutes < 5;
  }

  // Get parts by stock status
  Future<Map<String, List<Part>>> getPartsByStockStatus() async {
    try {
      final response = await _supabase
          .from('parts')
          .select()
          .order('name');

      final allParts = response // FIXED: Removed unnecessary cast
          .map<Part>((json) => Part.fromJson(json))
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
      throw Exception('Error categorizing stock: $e');
    }
  }

  // Get parts by location with real-time stock
  Future<Map<String, List<Part>>> getPartsByLocation() async {
    try {
      final response = await _supabase
          .from('parts')
          .select()
          .not('warehouse_bay', 'is', null)
          .order('warehouse_bay');

      final parts = response // FIXED: Removed unnecessary cast
          .map<Part>((json) => Part.fromJson(json))
          .toList();

      Map<String, List<Part>> locationMap = {};

      for (Part part in parts) {
        final location = part.location;
        if (!locationMap.containsKey(location)) {
          locationMap[location] = [];
        }
        locationMap[location]!.add(part);
      }

      return locationMap;
    } catch (e) {
      throw Exception('Error getting parts by location: $e');
    }
  }

  // Get stock valuation by category
  Future<Map<String, double>> getStockValuationByCategory() async {
    try {
      final response = await _supabase
          .from('parts')
          .select('category, quantity, pricing');

      final parts = response // FIXED: Removed unnecessary cast
          .map<Part>((json) => Part.fromJson(json))
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
      throw Exception('Error calculating stock valuation: $e');
    }
  }

  // Get low stock alerts with thresholds
  Future<List<Part>> getLowStockAlerts({int threshold = 5}) async {
    try {
      final response = await _supabase
          .from('parts')
          .select()
          .lt('quantity', threshold)
          .gt('quantity', 0)
          .order('quantity');

      return response // FIXED: Removed unnecessary cast
          .map<Part>((json) => Part.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error getting low stock alerts: $e');
    }
  }

  // Get out of stock parts
  Future<List<Part>> getOutOfStockParts() async {
    try {
      final response = await _supabase
          .from('parts')
          .select()
          .eq('quantity', 0)
          .order('name');

      return response // FIXED: Removed unnecessary cast
          .map<Part>((json) => Part.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error getting out of stock parts: $e');
    }
  }

  // Get parts without location assigned
  Future<List<Part>> getPartsWithoutLocation() async {
    try {
      final response = await _supabase
          .from('parts')
          .select()
          .isFilter('warehouse_bay', null)
          .order('name');

      return response // FIXED: Removed unnecessary cast
          .map<Part>((json) => Part.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error getting parts without location: $e');
    }
  }

  // Get high value parts with low stock
  Future<List<Part>> getHighValueLowStockParts({
    double minValue = 100.0,
    int maxStock = 3
  }) async {
    try {
      final response = await _supabase
          .from('parts')
          .select()
          .gte('pricing', minValue)
          .lte('quantity', maxStock)
          .order('pricing', ascending: false);

      return response // FIXED: Removed unnecessary cast
          .map<Part>((json) => Part.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error getting high value low stock parts: $e');
    }
  }

  // Real-time stock movement tracking
  Future<List<Map<String, dynamic>>> getRecentStockMovements({int limit = 10}) async {
    try {
      // This would typically come from a stock movements table
      // For now, we'll get recent part issues
      final response = await _supabase
          .from('part_issues')
          .select('*, parts!inner(*)')
          .order('issued_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response); // FIXED: Explicit type conversion
    } catch (e) {
      throw Exception('Error getting stock movements: $e');
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

  void removeFromSearchHistory(String query) {
    _searchHistory.remove(query);
    notifyListeners();
  }

  // Get stock inquiry dashboard data
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
      throw Exception('Error getting dashboard data: $e');
    }
  }

  // Advanced search with multiple filters
  Future<List<Part>> advancedStockSearch({
    String? query,
    List<String>? categories,
    Map<String, dynamic>? stockRange,
    Map<String, dynamic>? priceRange,
    List<String>? statuses,
    List<String>? locations,
    String? sortBy,
    bool ascending = true,
  }) async {
    try {
      var queryBuilder = _supabase.from('parts').select();

      // Text search
      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.or(
            'name.ilike.%$query%,part_number.ilike.%$query%,category.ilike.%$query%'
        );
        _addToSearchHistory(query);
      }

      // Multiple categories
      if (categories != null && categories.isNotEmpty && !categories.contains('All')) {
        queryBuilder = queryBuilder.inFilter('category', categories);
      }

      // Stock range
      if (stockRange != null) {
        if (stockRange['min'] != null) {
          queryBuilder = queryBuilder.gte('quantity', stockRange['min']);
        }
        if (stockRange['max'] != null) {
          queryBuilder = queryBuilder.lte('quantity', stockRange['max']);
        }
      }

      // Price range
      if (priceRange != null) {
        if (priceRange['min'] != null) {
          queryBuilder = queryBuilder.gte('pricing', priceRange['min']);
        }
        if (priceRange['max'] != null) {
          queryBuilder = queryBuilder.lte('pricing', priceRange['max']);
        }
      }

      // Multiple statuses
      if (statuses != null && statuses.isNotEmpty && !statuses.contains('All')) {
        queryBuilder = queryBuilder.inFilter('status', statuses);
      }

      // Multiple locations
      if (locations != null && locations.isNotEmpty) {
        // This would need to be adapted based on how locations are stored
        queryBuilder = queryBuilder.inFilter('warehouse_bay', locations);
      }

      // Sorting
      String orderColumn = 'name';
      switch (sortBy) {
        case 'Part Number':
          orderColumn = 'part_number';
          break;
        case 'Stock Level':
          orderColumn = 'quantity';
          break;
        case 'Price':
          orderColumn = 'pricing';
          break;
        case 'Category':
          orderColumn = 'category';
          break;
        case 'Location':
          orderColumn = 'warehouse_bay';
          break;
      }

      final response = await queryBuilder.order(orderColumn, ascending: ascending);

      return response // FIXED: Removed unnecessary cast
          .map<Part>((json) => Part.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error in advanced search: $e');
    }
  }

  // Get suggested parts based on search patterns
  Future<List<Part>> getSuggestedParts({int limit = 5}) async {
    try {
      // For now, return popular/frequently accessed parts
      // This could be enhanced with actual analytics
      final response = await _supabase
          .from('parts')
          .select()
          .gt('quantity', 0)
          .order('quantity', ascending: false)
          .limit(limit);

      return response // FIXED: Removed unnecessary cast
          .map<Part>((json) => Part.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Batch stock check for multiple parts
  Future<Map<String, Map<String, dynamic>>> batchStockCheck(List<String> partIds) async {
    try {
      final response = await _supabase
          .from('parts')
          .select('id, part_number, name, quantity, pricing, warehouse_bay, shelf_number, status')
          .inFilter('id', partIds);

      Map<String, Map<String, dynamic>> stockInfo = {};

      for (var item in response) {
        stockInfo[item['id']] = {
          'part_number': item['part_number'],
          'name': item['name'],
          'current_stock': item['quantity'],
          'price': item['pricing'],
          'location': item['warehouse_bay'] != null && item['shelf_number'] != null
              ? '${item['warehouse_bay']} - ${item['shelf_number']}'
              : 'No location',
          'status': item['status'],
          'stock_status': item['quantity'] == 0
              ? 'out_of_stock'
              : item['quantity'] < 5
              ? 'low_stock'
              : 'in_stock',
          'last_checked': DateTime.now().toIso8601String(),
        };
      }

      return stockInfo;
    } catch (e) {
      throw Exception('Error in batch stock check: $e');
    }
  }

  // Export stock data (returns formatted data for export)
  Future<List<Map<String, dynamic>>> exportStockData({
    String? category,
    String? stockStatus,
  }) async {
    try {
      final parts = await getRealTimeStock(
        category: category,
      );

      List<Map<String, dynamic>> exportData = [];

      for (Part part in parts) {
        // Filter by stock status if specified
        if (stockStatus != null) {
          bool includeInExport = false;
          switch (stockStatus) {
            case 'in_stock':
              includeInExport = part.quantity > 0;
              break;
            case 'low_stock':
              includeInExport = part.quantity > 0 && part.quantity < 5;
              break;
            case 'out_of_stock':
              includeInExport = part.quantity == 0;
              break;
            default:
              includeInExport = true;
          }

          if (!includeInExport) continue;
        }

        exportData.add({
          'Part Number': part.partNumber,
          'Name': part.name,
          'Category': part.category,
          'Current Stock': part.quantity,
          'Price (RM)': part.pricing.toStringAsFixed(2),
          'Total Value (RM)': (part.quantity * part.pricing).toStringAsFixed(2),
          'Location': part.location,
          'Status': part.status,
          'Last Updated': part.updatedAt.toIso8601String(),
        });
      }

      return exportData;
    } catch (e) {
      throw Exception('Error exporting stock data: $e');
    }
  }
}