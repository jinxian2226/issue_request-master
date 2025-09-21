import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/stock_alerts_screen.dart';

class StockAlertWidget extends StatelessWidget {
  const StockAlertWidget({super.key});

  /// FIXED: Uses efficient database queries - only fetches parts needing attention
  Future<Map<String, List<Map<String, dynamic>>>> _getStockAlerts() async {
    try {
      final supabase = Supabase.instance.client;

      Map<String, List<Map<String, dynamic>>> alerts = {
        'low_stock': <Map<String, dynamic>>[],
        'out_of_stock': <Map<String, dynamic>>[],
      };

      // FIXED Query 1: Out of stock parts ONLY (quantity = 0)
      final outOfStockResponse = await supabase
          .from('parts')
          .select('id, part_number, name, category, quantity, pricing, warehouse_bay, shelf_number')
          .eq('quantity', 0);

      alerts['out_of_stock'] = outOfStockResponse.cast<Map<String, dynamic>>();

      // FIXED Query 2: Low stock parts ONLY (quantity < 10 and quantity > 0)
      final lowStockResponse = await supabase
          .from('parts')
          .select('id, part_number, name, category, quantity, pricing, warehouse_bay, shelf_number')
          .lt('quantity', 10)
          .gt('quantity', 0);

      alerts['low_stock'] = lowStockResponse.cast<Map<String, dynamic>>();

      // Debug information (only in debug mode)
      if (kDebugMode) {
        debugPrint('STOCK ALERTS SUMMARY:');
        debugPrint('- Out of stock: ${alerts['out_of_stock']!.length}');
        debugPrint('- Low stock: ${alerts['low_stock']!.length}');
      }

      return alerts;
    } catch (e) {
      debugPrint('Stock alerts error: $e');
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
                Icons.warning_amber,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Stock Alerts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // FIXED: Navigate to StockAlertsScreen instead of RealTimeStockInquiryScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StockAlertsScreen(),
                    ),
                  );
                },
                child: const Text(
                  'View All Alerts',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Alert Cards
          FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: _getStockAlerts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2196F3),
                    strokeWidth: 2,
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorAlert(snapshot.error.toString());
              }

              if (!snapshot.hasData) {
                return _buildErrorAlert('No data available');
              }

              final alerts = snapshot.data!;
              final outOfStockParts = alerts['out_of_stock'] ?? <Map<String, dynamic>>[];
              final lowStockParts = alerts['low_stock'] ?? <Map<String, dynamic>>[];

              // FIXED: Only check for out of stock and low stock
              if (outOfStockParts.isEmpty && lowStockParts.isEmpty) {
                return _buildEmptyAlert();
              }

              return Column(
                children: [
                  // Out of Stock Alert (HIGHEST PRIORITY)
                  if (outOfStockParts.isNotEmpty)
                    _buildAlertCard(
                      context,
                      'Out of Stock Alert',
                      '${outOfStockParts.length} parts are completely out of stock',
                      Icons.error,
                      Colors.red,
                      outOfStockParts.take(2).toList(),
                          () => _showAlertDetails(context, 'Out of Stock Parts', outOfStockParts),
                    ),

                  if (outOfStockParts.isNotEmpty && lowStockParts.isNotEmpty)
                    const SizedBox(height: 8),

                  // Low Stock Alert
                  if (lowStockParts.isNotEmpty)
                    _buildAlertCard(
                      context,
                      'Low Stock Warning',
                      '${lowStockParts.length} parts running low on stock',
                      Icons.warning,
                      Colors.orange,
                      lowStockParts.take(2).toList(),
                          () => _showAlertDetails(context, 'Low Stock Parts', lowStockParts),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAlert() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'All parts are well-stocked',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorAlert(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Error loading alerts: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      List<Map<String, dynamic>> sampleParts,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            if (sampleParts.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...sampleParts.map((part) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${part['name']} (${part['part_number']}) - Qty: ${part['quantity']}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  void _showAlertDetails(BuildContext context, String title, List<Map<String, dynamic>> parts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // FIXED: Navigate to StockAlertsScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StockAlertsScreen(),
                      ),
                    );
                  },
                  child: const Text('View All Alerts'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: parts.length,
                itemBuilder: (context, index) {
                  final part = parts[index];
                  final pricing = part['pricing'] as num?;
                  return Card(
                    color: const Color(0xFF2C2C2C),
                    child: ListTile(
                      title: Text(
                        part['name'] as String? ?? 'Unknown Part',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Part #: ${part['part_number']} | Qty: ${part['quantity']} | Category: ${part['category']}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        'RM ${pricing?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}