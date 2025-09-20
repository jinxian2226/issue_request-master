import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/real_time_stock_inquiry_screen.dart';

class StockAlertWidget extends StatelessWidget {
  const StockAlertWidget({super.key});

  // Direct Supabase query for stock alerts
  Future<Map<String, List<Map<String, dynamic>>>> _getStockAlerts() async {
    try {
      final supabase = Supabase.instance.client;

      // Get parts data for alerts
      final response = await supabase
          .from('parts')
          .select('id, part_number, name, category, quantity, pricing, warehouse_bay, shelf_number');

      print('Stock alerts query response: ${response.length} parts found');

      Map<String, List<Map<String, dynamic>>> alerts = {
        'low_stock': [],
        'out_of_stock': [],
        'no_location': [],
        'high_value_low_stock': [],
      };

      for (var part in response) {
        final quantity = part['quantity'] ?? 0;
        final pricing = (part['pricing'] ?? 0.0).toDouble();
        final warehouseBay = part['warehouse_bay'];
        final shelfNumber = part['shelf_number'];

        // Out of stock alert (quantity = 0)
        if (quantity == 0) {
          alerts['out_of_stock']!.add(part);
        }

        // Low stock alert (quantity < 5 but > 0)
        else if (quantity < 5 && quantity > 0) {
          alerts['low_stock']!.add(part);
        }

        // No location assigned
        if (warehouseBay == null || shelfNumber == null) {
          alerts['no_location']!.add(part);
        }

        // High value parts with low stock (price > 100 and quantity < 3)
        if (pricing > 100 && quantity < 3) {
          alerts['high_value_low_stock']!.add(part);
        }
      }

      print('Alerts found:');
      print('- Out of stock: ${alerts['out_of_stock']!.length}');
      print('- Low stock: ${alerts['low_stock']!.length}');
      print('- No location: ${alerts['no_location']!.length}');
      print('- High value low stock: ${alerts['high_value_low_stock']!.length}');

      return alerts;
    } catch (e) {
      print('Stock alerts error: $e');
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RealTimeStockInquiryScreen(),
                    ),
                  );
                },
                child: const Text(
                  'View All',
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
              final outOfStockParts = alerts['out_of_stock'] ?? [];
              final lowStockParts = alerts['low_stock'] ?? [];
              final noLocationParts = alerts['no_location'] ?? [];
              final highValueLowStock = alerts['high_value_low_stock'] ?? [];

              // FIXED: Check for ALL types of alerts including out of stock
              if (outOfStockParts.isEmpty && lowStockParts.isEmpty &&
                  noLocationParts.isEmpty && highValueLowStock.isEmpty) {
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

                  if (outOfStockParts.isNotEmpty &&
                      (highValueLowStock.isNotEmpty || lowStockParts.isNotEmpty))
                    const SizedBox(height: 8),

                  // Critical Alerts (High Value Low Stock)
                  if (highValueLowStock.isNotEmpty)
                    _buildAlertCard(
                      context,
                      'Critical Stock Alert',
                      '${highValueLowStock.length} high-value parts need immediate attention',
                      Icons.priority_high,
                      Colors.red,
                      highValueLowStock.take(2).toList(),
                          () => _showAlertDetails(context, 'High Value Low Stock', highValueLowStock),
                    ),

                  if (highValueLowStock.isNotEmpty && lowStockParts.isNotEmpty)
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

                  if ((outOfStockParts.isNotEmpty || lowStockParts.isNotEmpty || highValueLowStock.isNotEmpty) &&
                      noLocationParts.isNotEmpty)
                    const SizedBox(height: 8),

                  // Location Missing Alert (LOWEST PRIORITY)
                  if (noLocationParts.isNotEmpty)
                    _buildAlertCard(
                      context,
                      'Location Missing',
                      '${noLocationParts.length} parts need location assignment',
                      Icons.location_off,
                      Colors.blue,
                      noLocationParts.take(2).toList(),
                          () => _showAlertDetails(context, 'Parts Without Location', noLocationParts),
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
              'All parts are well-stocked and properly located',
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(height: 8),
          const Text(
            'Unable to load alerts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            error,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 14,
                  ),
                ],
              ),

              // Sample Parts Preview
              if (sampleParts.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...sampleParts.map((part) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 28), // Align with icon
                      Expanded(
                        child: Text(
                          '${part['part_number']} - ${part['name']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          part['quantity'] == 0 ? 'OUT' : '${part['quantity']} left',
                          style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDetails(BuildContext context, String title, List<Map<String, dynamic>> parts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
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

                  // Header
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RealTimeStockInquiryScreen(),
                            ),
                          );
                        },
                        child: const Text('View in Search'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${parts.length} parts require attention',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Parts List
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: parts.length,
                      itemBuilder: (context, index) {
                        final part = parts[index];
                        return Card(
                          color: const Color(0xFF1A1A1A),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              part['part_number'],
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  part['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Stock: ${part['quantity']}',
                                      style: TextStyle(
                                        color: part['quantity'] == 0
                                            ? Colors.red
                                            : part['quantity'] < 5
                                            ? Colors.orange
                                            : Colors.green,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Location: ${_getLocation(part)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'RM ${(part['pricing'] ?? 0.0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  part['category'] ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              // Navigate to part details if needed
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getLocation(Map<String, dynamic> part) {
    final warehouseBay = part['warehouse_bay'];
    final shelfNumber = part['shelf_number'];

    if (warehouseBay != null && shelfNumber != null) {
      return '$warehouseBay - $shelfNumber';
    }
    return 'No location';
  }
}