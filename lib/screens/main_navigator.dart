import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/parts_service.dart';
import '../services/stock_inquiry_service.dart';
import 'home_screen.dart';
import 'real_time_stock_inquiry_screen.dart';
import 'work_order_tracking_screen.dart';
import 'settings_screen.dart';
import 'delivery_tracking_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize all services
      context.read<PartsService>().fetchParts();
    });
  }

  // List of all main screens
  final List<Widget> _screens = [
    const HomeContent(), // Home content (index 0)
    const RealTimeStockInquiryScreen(), // Search (index 1)
    const SizedBox(), // Reports - handled by bottom sheet (index 2)
    const WorkOrderTrackingScreen(), // Tasks (index 3)
    const SettingsScreen(), // Profile (index 4)
  ];

  void _onBottomNavTap(int index) {
    if (index == 2) {
      // Show reports bottom sheet instead of switching to a screen
      _showReportsBottomSheet();
      // Don't change the selected index for reports
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _showReportsBottomSheet() {
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
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Reports & Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildReportOption(
                'Stock Level Report',
                'View current stock levels and trends',
                Icons.bar_chart,
                    () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 1; // Switch to Search tab for reports
                  });
                },
              ),

              _buildReportOption(
                'Low Stock Alerts',
                'Parts that need attention',
                Icons.warning,
                    () {
                  Navigator.pop(context);
                  _showLowStockParts();
                },
              ),

              _buildReportOption(
                'Delivery Tracking',
                'Track sent parts and deliveries',
                Icons.local_shipping,
                    () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeliveryTrackingScreen(),
                    ),
                  );
                },
              ),

              _buildReportOption(
                'Inventory Valuation',
                'Total inventory value by category',
                Icons.monetization_on,
                    () {
                  Navigator.pop(context);
                  _showInventoryValuation();
                },
              ),

              _buildReportOption(
                'Part Location Report',
                'Parts by warehouse location',
                Icons.location_on,
                    () {
                  Navigator.pop(context);
                  _showMessage('Location report feature coming soon');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2196F3)),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }

  void _showLowStockParts() async {
    try {
      final stockService = context.read<StockInquiryService>();
      final lowStockParts = await stockService.getLowStockAlerts();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Low Stock Alert',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: lowStockParts.isEmpty
                ? const Center(
              child: Text(
                'No low stock alerts',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: lowStockParts.length,
              itemBuilder: (context, index) {
                final part = lowStockParts[index];
                return ListTile(
                  title: Text(
                    part.partNumber,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    part.name,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${part.quantity} left',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showMessage('Error loading low stock parts: $e');
    }
  }

  void _showInventoryValuation() async {
    try {
      final stockService = context.read<StockInquiryService>();
      final valuation = await stockService.getStockValuationByCategory();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Inventory Valuation',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: valuation.isEmpty
                ? const Center(
              child: Text(
                'No valuation data available',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: valuation.entries.length,
              itemBuilder: (context, index) {
                final entry = valuation.entries.elementAt(index);
                return ListTile(
                  title: Text(
                    entry.key,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  trailing: Text(
                    'RM ${entry.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showMessage('Error loading inventory valuation: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2C2C2C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF2C2C2C),
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}