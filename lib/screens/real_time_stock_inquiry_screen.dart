import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/parts_service.dart';
import '../models/part.dart';
import '../screens/part_details_screen.dart';


class RealTimeStockInquiryScreen extends StatefulWidget {
  const RealTimeStockInquiryScreen({super.key});

  @override
  State<RealTimeStockInquiryScreen> createState() => _RealTimeStockInquiryScreenState();
}

class _RealTimeStockInquiryScreenState extends State<RealTimeStockInquiryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Part> _searchResults = [];
  final List<String> _recentSearches = [];
  bool _isSearching = false;
  String _selectedFilter = 'All';
  String _selectedSortBy = 'Name';
  String _selectedStockFilter = 'All Stock';
  final List<String> _filters = ['All', 'Brake', 'Engine', 'Transmission', 'Suspension'];
  final List<String> _sortOptions = ['Name', 'Part Number', 'Stock Level', 'Price', 'Location'];
  final List<String> _stockFilters = ['All Stock', 'In Stock', 'Low Stock', 'Out of Stock'];

  @override
  void initState() {
    super.initState();
    _loadAllParts();
  }

  void _loadAllParts() async {
    setState(() {
      _isSearching = true;
    });

    final partsService = context.read<PartsService>();
    await partsService.fetchParts();

    setState(() {
      _searchResults = partsService.parts;
      _isSearching = false;
    });
  }

  void _searchParts(String query) async {
    if (query.isEmpty) {
      _loadAllParts();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final partsService = context.read<PartsService>();
      final results = await partsService.searchParts(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;

        // Add to recent searches if not empty and not already exists
        if (query.isNotEmpty && !_recentSearches.contains(query)) {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showErrorMessage('Error searching: $e');
    }
  }

  List<Part> _getFilteredAndSortedResults() {
    List<Part> filteredResults = _searchResults;

    // Apply category filter
    if (_selectedFilter != 'All') {
      filteredResults = filteredResults
          .where((part) => part.category.toLowerCase().contains(_selectedFilter.toLowerCase()))
          .toList();
    }

    // Apply stock filter
    switch (_selectedStockFilter) {
      case 'In Stock':
        filteredResults = filteredResults.where((part) => part.quantity > 0).toList();
        break;
      case 'Low Stock':
        filteredResults = filteredResults.where((part) => part.quantity > 0 && part.quantity < 5).toList();
        break;
      case 'Out of Stock':
        filteredResults = filteredResults.where((part) => part.quantity == 0).toList();
        break;
    }

    // Apply sorting
    switch (_selectedSortBy) {
      case 'Name':
        filteredResults.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Part Number':
        filteredResults.sort((a, b) => a.partNumber.compareTo(b.partNumber));
        break;
      case 'Stock Level':
        filteredResults.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case 'Price':
        filteredResults.sort((a, b) => a.pricing.compareTo(b.pricing));
        break;
      case 'Location':
        filteredResults.sort((a, b) => a.location.compareTo(b.location));
        break;
    }

    return filteredResults;
  }

  @override
  Widget build(BuildContext context) {
    final filteredResults = _getFilteredAndSortedResults();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Real-time Stock Inquiry'),
        backgroundColor: const Color(0xFF2C2C2C),
        actions: [
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Main Search Bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name, part number, or category',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _loadAllParts();
                      },
                      icon: const Icon(Icons.clear, color: Colors.grey),
                    )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF2C2C2C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _searchParts,
                ),

                const SizedBox(height: 12),

                // Recent Searches
                if (_recentSearches.isNotEmpty)
                  SizedBox(
                    height: 35,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentSearches.length,
                      itemBuilder: (context, index) {
                        final search = _recentSearches[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              _searchController.text = search;
                              _searchParts(search);
                            },
                            child: Chip(
                              label: Text(search),
                              backgroundColor: const Color(0xFF2C2C2C),
                              labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                              deleteIcon: const Icon(Icons.close, size: 16, color: Colors.grey),
                              onDeleted: () {
                                setState(() {
                                  _recentSearches.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Filter and Sort Bar
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Category Filter
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: const Color(0xFF2C2C2C),
                          selectedColor: const Color(0xFF2196F3),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Sort Button
                IconButton(
                  onPressed: _showSortBottomSheet,
                  icon: const Icon(Icons.sort, color: Color(0xFF2196F3)),
                ),
              ],
            ),
          ),

          // Results Count and Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredResults.length} parts found',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                if (_isSearching)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Color(0xFF2196F3),
                      strokeWidth: 2,
                    ),
                  ),
                const Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.grey, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Live Data',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results List
          Expanded(
            child: _isSearching
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2196F3),
              ),
            )
                : filteredResults.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredResults.length,
              itemBuilder: (context, index) {
                final part = filteredResults[index];
                return _buildRealTimeStockCard(part);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeStockCard(Part part) {
    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PartDetailsScreen(part: part),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Real-time indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              part.partNumber,
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          part.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'RM ${part.pricing.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  part.category,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Real-time Stock and Location Info
              Row(
                children: [
                  // Real-time Stock Level
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStockLevelColor(part.quantity).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStockLevelColor(part.quantity).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.inventory,
                                color: _getStockLevelColor(part.quantity),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Current Stock',
                                style: TextStyle(
                                  color: _getStockLevelColor(part.quantity),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${part.quantity} units',
                            style: TextStyle(
                              color: _getStockLevelColor(part.quantity),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getStockStatusText(part.quantity),
                            style: TextStyle(
                              color: _getStockLevelColor(part.quantity),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Location Information
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.grey,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Location',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (part.warehouseBay != null && part.shelfNumber != null) ...[
                            Text(
                              'Bay: ${part.warehouseBay}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Shelf: ${part.shelfNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Not Assigned',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        // Navigate to issue form
                        _showMessage('Issue form coming soon');
                      },
                      icon: const Icon(Icons.output, size: 16),
                      label: const Text('Issue Part', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        // Navigate to request form
                        _showMessage('Request form coming soon');
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('Request', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        _showStockHistory(part);
                      },
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('History', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No parts found',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search criteria',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              _loadAllParts();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Show All Parts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'received':
        color = Colors.green;
        break;
      case 'damaged':
        color = Colors.red;
        break;
      case 'returned':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStockLevelColor(int quantity) {
    if (quantity == 0) return Colors.red;
    if (quantity < 5) return Colors.orange;
    if (quantity < 10) return Colors.yellow;
    return Colors.green;
  }

  String _getStockStatusText(int quantity) {
    if (quantity == 0) return 'Out of Stock';
    if (quantity < 5) return 'Low Stock';
    if (quantity < 10) return 'Limited Stock';
    return 'In Stock';
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Options',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock Level Filter
                  const Text(
                    'Stock Level',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    children: _stockFilters.map((filter) =>
                        Container(
                          margin: const EdgeInsets.only(right: 8, bottom: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: _selectedStockFilter == filter,
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedStockFilter = filter;
                              });
                              setState(() {
                                _selectedStockFilter = filter;
                              });
                            },
                            backgroundColor: const Color(0xFF1A1A1A),
                            selectedColor: const Color(0xFF2196F3),
                            labelStyle: TextStyle(
                              color: _selectedStockFilter == filter ? Colors.white : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = 'All';
                              _selectedSortBy = 'Name';
                              _selectedStockFilter = 'All Stock';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Reset Filters'),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Replace the _showSortBottomSheet method in your real_time_stock_inquiry_screen.dart
// with this modern version that eliminates all warnings:

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort Results By',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Modern approach using ListTile with custom radio-like UI
              ..._sortOptions.map((option) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: _selectedSortBy == option
                      ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedSortBy == option
                            ? const Color(0xFF2196F3)
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: _selectedSortBy == option
                        ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    )
                        : null,
                  ),
                  title: Text(
                    option,
                    style: TextStyle(
                      color: _selectedSortBy == option
                          ? const Color(0xFF2196F3)
                          : Colors.white,
                      fontWeight: _selectedSortBy == option
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedSortBy = option;
                    });
                    Navigator.pop(context);
                  },
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  void _showStockHistory(Part part) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(
          'Stock History - ${part.partNumber}',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Stock history feature will be available in future updates.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2C2C2C),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}