import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/parts_service.dart';
import '../models/part.dart';
import '../screens/real_time_stock_inquiry_screen.dart';
import '../screens/part_details_screen.dart';

class QuickStockCheckWidget extends StatefulWidget {
  const QuickStockCheckWidget({super.key});

  @override
  State<QuickStockCheckWidget> createState() => _QuickStockCheckWidgetState();
}

class _QuickStockCheckWidgetState extends State<QuickStockCheckWidget> {
  final TextEditingController _quickSearchController = TextEditingController();
  List<Part> _quickResults = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void dispose() {
    _quickSearchController.dispose();
    super.dispose();
  }

  Future<void> _quickSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _showResults = false;
        _quickResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      final partsService = context.read<PartsService>();
      final results = await partsService.searchParts(query);

      setState(() {
        _quickResults = results.take(5).toList(); // Show only first 5 results
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _quickResults = [];
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Search Header
          Row(
            children: [
              const Icon(
                Icons.speed,
                color: Color(0xFF2196F3),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Stock Check',
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

          // Quick Search Input
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _showResults
                    ? const Color(0xFF2196F3).withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: TextField(
              controller: _quickSearchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type part number or name...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _quickSearchController.text.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _quickSearchController.clear();
                    setState(() {
                      _showResults = false;
                      _quickResults = [];
                    });
                  },
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _quickSearch,
            ),
          ),

          // Quick Results
          if (_showResults) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                ),
              ),
              child: _isSearching
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFF2196F3),
                    strokeWidth: 2,
                  ),
                ),
              )
                  : _quickResults.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No parts found',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              )
                  : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: _quickResults.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Color(0xFF1A1A1A),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final part = _quickResults[index];
                  return _buildQuickResultItem(part);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickResultItem(Part part) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PartDetailsScreen(part: part),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Part Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.partNumber,
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    part.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    part.category,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Stock Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStockLevelColor(part.quantity).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStockLevelColor(part.quantity).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${part.quantity} units',
                    style: TextStyle(
                      color: _getStockLevelColor(part.quantity),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'RM ${part.pricing.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.grey,
                      size: 10,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      part.location,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 12,
            ),
          ],
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
}