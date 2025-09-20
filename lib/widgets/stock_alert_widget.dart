import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/parts_service.dart';
import '../models/part.dart';
import '../screens/part_details_screen.dart';
import '../screens/real_time_stock_inquiry_screen.dart';

class StockAlertWidget extends StatelessWidget {
  const StockAlertWidget({super.key});

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
          Consumer<PartsService>(
            builder: (context, partsService, child) {
              return FutureBuilder<Map<String, List<Part>>>(
                future: _getPartsNeedingAttention(partsService),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2196F3),
                        strokeWidth: 2,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.hasError) {
                    return _buildEmptyAlert();
                  }

                  final attentionParts = snapshot.data!;
                  final lowStockParts = attentionParts['low_stock'] ?? [];
                  final noLocationParts = attentionParts['no_location'] ?? [];
                  final highValueLowStock = attentionParts['high_value_low_stock'] ?? [];

                  if (lowStockParts.isEmpty && noLocationParts.isEmpty && highValueLowStock.isEmpty) {
                    return _buildEmptyAlert();
                  }

                  return Column(
                    children: [
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

                      if (highValueLowStock.isNotEmpty) const SizedBox(height: 8),

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

                      if (lowStockParts.isNotEmpty && noLocationParts.isNotEmpty)
                        const SizedBox(height: 8),

                      // Location Missing Alert
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
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, List<Part>>> _getPartsNeedingAttention(PartsService partsService) async {
    await partsService.fetchParts();
    final parts = partsService.parts;

    Map<String, List<Part>> attentionParts = {
      'low_stock': [],
      'no_location': [],
      'high_value_low_stock': [],
    };

    for (Part part in parts) {
      // Low stock alert
      if (part.quantity < 5 && part.quantity > 0) {
        attentionParts['low_stock']!.add(part);
      }

      // No location assigned
      if (part.warehouseBay == null || part.shelfNumber == null) {
        attentionParts['no_location']!.add(part);
      }

      // High value parts with low stock
      if (part.pricing > 100 && part.quantity < 3) {
        attentionParts['high_value_low_stock']!.add(part);
      }
    }

    return attentionParts;
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

  Widget _buildAlertCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      List<Part> sampleParts,
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
                          '${part.partNumber} - ${part.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (title.contains('Stock'))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${part.quantity} left',
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

  void _showAlertDetails(BuildContext context, String title, List<Part> parts) {
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
                              part.partNumber,
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
                                  part.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Stock: ${part.quantity}',
                                      style: TextStyle(
                                        color: part.quantity == 0
                                            ? Colors.red
                                            : part.quantity < 5
                                            ? Colors.orange
                                            : Colors.green,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Location: ${part.location}',
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
                                  'RM ${part.pricing.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  part.category,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PartDetailsScreen(part: part),
                                ),
                              );
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
}