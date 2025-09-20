import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stock_inquiry_service.dart';
import '../screens/real_time_stock_inquiry_screen.dart';

class StockInquiryDashboardWidget extends StatelessWidget {
  const StockInquiryDashboardWidget({super.key});

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
          ChangeNotifierProvider(
            create: (context) => StockInquiryService(),
            child: Consumer<StockInquiryService>(
              builder: (context, stockService, child) {
                return FutureBuilder<Map<String, dynamic>>(
                  future: stockService.getStockInquiryDashboard(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return _buildErrorState();
                    }

                    final dashboardData = snapshot.data!;
                    return _buildDashboardContent(context, dashboardData);
                  },
                );
              },
            ),
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

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Unable to load dashboard data',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          Text(
            'Please check your connection',
            style: TextStyle(color: Colors.grey, fontSize: 12),
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
    final lastUpdated = data['last_updated'] as DateTime?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real-time indicator
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Real-time Data',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (lastUpdated != null)
                Text(
                  'Updated ${_getTimeAgo(lastUpdated)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Main Statistics Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Parts',
                  totalParts.toString(),
                  Icons.inventory,
                  Colors.blue,
                  null,
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

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Low Stock',
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
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'View Stock Alerts',
                  Icons.notifications,
                  Colors.orange,
                      () => _navigateToStockAlerts(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'Location Report',
                  Icons.location_on,
                  Colors.blue,
                      () => _navigateToLocationReport(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color color,
      double? percentage,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
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
          if (percentage != null) ...[
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 9,
              ),
            ),
          ],
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
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
          ),
        ),
      ),
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

  void _navigateToStockAlerts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RealTimeStockInquiryScreen(),
      ),
    );
  }

  void _navigateToLocationReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Location Report',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Location report feature will be available in future updates.',
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
}