import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/real_time_stock_inquiry_screen.dart';

class StockInquiryDashboardWidget extends StatelessWidget {
  const StockInquiryDashboardWidget({super.key});

  // FIXED: Direct Supabase query with correct threshold (quantity < 10)
  Future<Map<String, dynamic>> _getDashboardData() async {
    try {
      final supabase = Supabase.instance.client;

      // Simple query to get all parts data
      final response = await supabase
          .from('parts')
          .select('quantity, pricing, warehouse_bay, shelf_number');

      if (kDebugMode) {
        debugPrint('Dashboard query response: ${response.length} parts found');
      }

      if (response.isEmpty) {
        return {
          'total_parts': 0,
          'in_stock_parts': 0,
          'low_stock_parts': 0,
          'out_of_stock_parts': 0,
          'total_inventory_value': 0.0,
          'stock_health_percentage': 0.0,
          'location_completion_percentage': 0.0,
          'last_updated': DateTime.now(),
        };
      }

      final totalParts = response.length;
      int inStockParts = 0;
      int lowStockParts = 0;
      int outOfStockParts = 0;
      double totalValue = 0.0;
      int partsWithLocation = 0;

      for (var part in response) {
        final quantity = part['quantity'] ?? 0;
        final pricing = (part['pricing'] ?? 0.0).toDouble();
        final warehouseBay = part['warehouse_bay'];
        final shelfNumber = part['shelf_number'];

        // Calculate totals
        totalValue += quantity * pricing;

        // FIXED: Stock categorization with threshold 10
        if (quantity == 0) {
          outOfStockParts++;
        } else if (quantity < 10) { // CHANGED: from < 5 to < 10
          lowStockParts++;
          inStockParts++; // Low stock items are still "in stock"
        } else {
          inStockParts++;
        }

        // Location tracking
        if (warehouseBay != null && shelfNumber != null) {
          partsWithLocation++;
        }
      }

      final stockHealthPercentage = totalParts > 0 ? (inStockParts / totalParts * 100) : 0.0;
      final locationCompletionPercentage = totalParts > 0 ? (partsWithLocation / totalParts * 100) : 0.0;

      if (kDebugMode) {
        debugPrint('Dashboard calculations:');
        debugPrint('- Total parts: $totalParts');
        debugPrint('- Out of stock: $outOfStockParts');
        debugPrint('- Low stock (< 10): $lowStockParts');
        debugPrint('- In stock: $inStockParts');
      }

      return {
        'total_parts': totalParts,
        'in_stock_parts': inStockParts,
        'low_stock_parts': lowStockParts,
        'out_of_stock_parts': outOfStockParts,
        'total_inventory_value': totalValue,
        'stock_health_percentage': stockHealthPercentage,
        'location_completion_percentage': locationCompletionPercentage,
        'last_updated': DateTime.now(),
      };
    } catch (e) {
      debugPrint('Dashboard error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.dashboard_outlined,
                color: Color(0xFF2196F3),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Stock Inquiry Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RealTimeStockInquiryScreen(),
                    ),
                  );
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Dashboard Content
          FutureBuilder<Map<String, dynamic>>(
            future: _getDashboardData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              if (!snapshot.hasData) {
                return _buildErrorState('No data available');
              }

              final dashboardData = snapshot.data!;
              return _buildDashboardContent(context, dashboardData);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2196F3),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'Unable to load dashboard data',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          Text(
            error,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, Map<String, dynamic> data) {
    final totalParts = data['total_parts'] ?? 0;
    final inStockParts = data['in_stock_parts'] ?? 0;
    final lowStockParts = data['low_stock_parts'] ?? 0;
    final outOfStockParts = data['out_of_stock_parts'] ?? 0;
    final totalValue = data['total_inventory_value'] ?? 0.0;
    final stockHealthPercentage = data['stock_health_percentage'] ?? 0.0;
    final locationCompletionPercentage = data['location_completion_percentage'] ?? 0.0;
    final lastUpdated = data['last_updated'] as DateTime? ?? DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Top row - Total Parts and In Stock
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Parts',
                  totalParts.toString(),
                  Icons.inventory,
                  const Color(0xFF2196F3),
                  100, // Always 100% for total
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'In Stock',
                  inStockParts.toString(),
                  Icons.check_circle,
                  Colors.green,
                  totalParts > 0 ? (inStockParts / totalParts * 100) : 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Bottom row - Low Stock and Out of Stock
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Low Stock (<10)',
                  lowStockParts.toString(),
                  Icons.warning,
                  Colors.orange,
                  totalParts > 0 ? (lowStockParts / totalParts * 100) : 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Out of Stock',
                  outOfStockParts.toString(),
                  Icons.error,
                  Colors.red,
                  totalParts > 0 ? (outOfStockParts / totalParts * 100) : 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Value and Health Indicators
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Total Inventory Value
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Inventory Value',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Text(
                      'RM ${totalValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stock Health Indicator
                _buildHealthIndicator(
                  'Stock Health',
                  stockHealthPercentage,
                  stockHealthPercentage >= 80 ? Colors.green :
                  stockHealthPercentage >= 60 ? Colors.orange : Colors.red,
                ),

                const SizedBox(height: 8),

                // Location Completion Indicator
                _buildHealthIndicator(
                  'Location Assigned',
                  locationCompletionPercentage,
                  locationCompletionPercentage >= 90 ? Colors.green :
                  locationCompletionPercentage >= 70 ? Colors.orange : Colors.red,
                ),

                const SizedBox(height: 8),

                // Last Updated
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.update, color: Colors.grey, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Updated ${_getTimeAgo(lastUpdated)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, double percentage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(String label, double percentage, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}