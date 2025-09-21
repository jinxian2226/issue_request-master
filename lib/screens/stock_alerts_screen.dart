import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockAlertsScreen extends StatefulWidget {
  const StockAlertsScreen({super.key});

  @override
  State<StockAlertsScreen> createState() => _StockAlertsScreenState();
}

class _StockAlertsScreenState extends State<StockAlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<Map<String, dynamic>>> _alerts = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Changed from 4 to 2
    _loadStockAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loads only parts that need attention using efficient database queries
  Future<void> _loadStockAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;

      Map<String, List<Map<String, dynamic>>> alerts = {
        'out_of_stock': <Map<String, dynamic>>[],
        'low_stock': <Map<String, dynamic>>[],
      };

      // Query 1: Out of stock parts (quantity = 0)
      final outOfStockResponse = await supabase
          .from('parts')
          .select('id, part_number, name, category, quantity, pricing, warehouse_bay, shelf_number, status, updated_at')
          .eq('quantity', 0)
          .order('updated_at', ascending: false);

      alerts['out_of_stock'] = outOfStockResponse.cast<Map<String, dynamic>>();

      // Query 2: Low stock parts (quantity < 10 and quantity > 0)
      final lowStockResponse = await supabase
          .from('parts')
          .select('id, part_number, name, category, quantity, pricing, warehouse_bay, shelf_number, status, updated_at')
          .lt('quantity', 10)
          .gt('quantity', 0)
          .order('quantity'); // Order by quantity ascending (lowest first)

      alerts['low_stock'] = lowStockResponse.cast<Map<String, dynamic>>();

      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });

      if (kDebugMode) {
        debugPrint('STOCK ALERTS LOADED:');
        debugPrint('- Out of stock: ${alerts['out_of_stock']!.length}');
        debugPrint('- Low stock: ${alerts['low_stock']!.length}');
      }

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading stock alerts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAlerts = _alerts.values.fold(0, (sum, list) => sum + list.length);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stock Alerts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (!_isLoading)
              Text(
                '$totalAlerts parts need attention',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadStockAlerts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Alerts',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2196F3),
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: [
            Tab(
              child: _buildTabTitle('Out of Stock', _alerts['out_of_stock']?.length ?? 0, Colors.red),
            ),
            Tab(
              child: _buildTabTitle('Low Stock', _alerts['low_stock']?.length ?? 0, Colors.orange),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF2196F3)),
      )
          : _error != null
          ? _buildErrorWidget()
          : totalAlerts == 0
          ? _buildEmptyState()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsList('out_of_stock', 'Out of Stock Parts', Colors.red),
          _buildAlertsList('low_stock', 'Low Stock Parts', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildTabTitle(String title, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Alerts',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStockAlerts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text(
              'All Good!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'All parts are well-stocked and properly located.\nNo alerts at this time.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(String alertType, String title, Color color) {
    final parts = _alerts[alertType] ?? [];

    if (parts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(
              'No ${title.toLowerCase()} found',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'All parts in this category are in good condition.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStockAlerts,
      color: const Color(0xFF2196F3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: parts.length,
        itemBuilder: (context, index) {
          final part = parts[index];
          return _buildPartCard(part, color);
        },
      ),
    );
  }

  Widget _buildPartCard(Map<String, dynamic> part, Color alertColor) {
    final quantity = part['quantity'] ?? 0;
    final pricing = (part['pricing'] ?? 0.0).toDouble();
    final warehouseBay = part['warehouse_bay'];
    final shelfNumber = part['shelf_number'];

    // Determine priority based on conditions
    String priorityText = 'Normal';
    Color priorityColor = Colors.grey;
    IconData priorityIcon = Icons.info;

    if (quantity == 0) {
      priorityText = 'URGENT';
      priorityColor = Colors.red;
      priorityIcon = Icons.error;
    } else if (quantity < 10) {
      priorityText = 'LOW STOCK';
      priorityColor = Colors.orange;
      priorityIcon = Icons.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: const Color(0xFF2C2C2C),
        elevation: 2,
        child: InkWell(
          onTap: () {
            // Navigate to part details
            _showPartDetails(part);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            part['name'] ?? 'Unknown Part',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Part #: ${part['part_number'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: priorityColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(priorityIcon, color: priorityColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            priorityText,
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Info Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Quantity',
                        quantity.toString(),
                        quantity == 0 ? Colors.red : quantity < 5 ? Colors.orange : Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Price',
                        'RM ${pricing.toStringAsFixed(2)}',
                        pricing > 100 ? Colors.red : Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Category',
                        part['category'] ?? 'N/A',
                        Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Location info
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      warehouseBay != null && shelfNumber != null
                          ? 'Bay: $warehouseBay, Shelf: $shelfNumber'
                          : 'Location not assigned',
                      style: TextStyle(
                        color: warehouseBay != null && shelfNumber != null
                            ? Colors.grey
                            : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showPartDetails(Map<String, dynamic> part) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Part Details Header
              Text(
                part['name'] ?? 'Unknown Part',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Part Number: ${part['part_number'] ?? 'N/A'}',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 24),

              // Detailed Info
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailRow('Category', part['category'] ?? 'N/A'),
                    _buildDetailRow('Quantity', '${part['quantity'] ?? 0}'),
                    _buildDetailRow('Price', 'RM ${((part['pricing'] ?? 0.0) as num).toStringAsFixed(2)}'),
                    _buildDetailRow('Warehouse Bay', part['warehouse_bay'] ?? 'Not assigned'),
                    _buildDetailRow('Shelf Number', part['shelf_number'] ?? 'Not assigned'),
                    _buildDetailRow('Status', part['status'] ?? 'N/A'),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement edit functionality
                              Navigator.pop(context);
                              _showMessage('Edit functionality coming soon');
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Part'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement issue functionality
                              Navigator.pop(context);
                              _showMessage('Issue part functionality coming soon');
                            },
                            icon: const Icon(Icons.output),
                            label: const Text('Issue Part'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF2196F3),
        ),
      );
    }
  }
}