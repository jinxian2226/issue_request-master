import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/parts_service.dart';
import '../models/part.dart';
import '../models/auth_service.dart';
import 'mark_as_received_sheet.dart';
import 'mark_as_damaged_sheet.dart';
import 'mark_as_returned_sheet.dart';

class PartMarkingScreen extends StatefulWidget {
  const PartMarkingScreen({super.key});

  @override
  State<PartMarkingScreen> createState() => _PartMarkingScreenState();
}

class _PartMarkingScreenState extends State<PartMarkingScreen> {
  final _searchCtrl = TextEditingController();

  bool _loading = false;
  bool _updating = false;

  List<Part> _results = [];
  Part? _part;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _part = null;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final partsService = context.read<PartsService>();
      final parts = await partsService.searchParts(q);

      setState(() {
        _results = parts;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMarkAsReceived() async {
    if (_part == null) return;

    final result = await showModalBottomSheet<ReceivedFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkAsReceivedSheet(
        sku: _part!.partNumber,
        name: _part!.name,
        imageUrl: "https://cdn-icons-png.flaticon.com/512/609/609361.png",
        expectedUnits: _part!.quantity,
        tierLabel: _part!.category,
      ),
    );

    if (result == null) return;

    setState(() => _updating = true);

    try {
      final partsService = context.read<PartsService>();
      final authService = context.read<AuthService>();

      await partsService.markAsReceived(
        partId: _part!.id,
        quantityReceived: result.units,
        packageType: result.packageType,
        condition: result.condition,
        location: result.location,
        notes: result.notes,
        photoPath: result.photoPath,
        performedBy: authService.currentUser ?? 'Unknown User', // Use actual user
      );

      // Refresh the part data
      final updatedParts = await partsService.searchParts(_part!.partNumber);
      if (updatedParts.isNotEmpty) {
        setState(() {
          _part = updatedParts.first;
          // Update results if the part is in the list
          final index = _results.indexWhere((p) => p.id == _part!.id);
          if (index != -1) {
            _results[index] = _part!;
          }
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully marked ${result.units} units as received'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking as received: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _openMarkAsDamaged() async {
    if (_part == null) return;

    final result = await showModalBottomSheet<DamagedFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkAsDamagedSheet(
        sku: _part!.partNumber,
        name: _part!.name,
        imageUrl: "https://cdn-icons-png.flaticon.com/512/609/609361.png",
        stock: _part!.quantity,
      ),
    );

    if (result == null) return;

    setState(() => _updating = true);

    try {
      final partsService = context.read<PartsService>();
      final authService = context.read<AuthService>();

      await partsService.markAsDamaged(
        partId: _part!.id,
        quantityDamaged: result.quantity,
        damageType: result.damageType,
        cause: result.cause,
        situation: result.situation,
        description: result.description,
        photos: result.photos,
        performedBy: authService.currentUser ?? 'Unknown User', // Use actual user
      );

      // Refresh the part data
      final updatedParts = await partsService.searchParts(_part!.partNumber);
      if (updatedParts.isNotEmpty) {
        setState(() {
          _part = updatedParts.first;
          // Update results if the part is in the list
          final index = _results.indexWhere((p) => p.id == _part!.id);
          if (index != -1) {
            _results[index] = _part!;
          }
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully marked ${result.quantity} units as damaged'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking as damaged: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _openMarkAsReturned() async {
    if (_part == null) return;

    final result = await showModalBottomSheet<ReturnFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkAsReturnedSheet(
        sku: _part!.partNumber,
        name: _part!.name,
        imageUrl: "https://cdn-icons-png.flaticon.com/512/609/609361.png",
        availableQty: _part!.quantity,
      ),
    );

    if (result == null) return;

    setState(() => _updating = true);

    try {
      final partsService = context.read<PartsService>();
      final authService = context.read<AuthService>();

      await partsService.markAsReturned(
        partId: _part!.id,
        quantityReturned: result.quantity,
        returnType: result.returnType,
        reason: result.reason,
        notes: result.notes,
        performedBy: authService.currentUser ?? 'Unknown User', // Use actual user
      );

      // Refresh the part data
      final updatedParts = await partsService.searchParts(_part!.partNumber);
      if (updatedParts.isNotEmpty) {
        setState(() {
          _part = updatedParts.first;
          // Update results if the part is in the list
          final index = _results.indexWhere((p) => p.id == _part!.id);
          if (index != -1) {
            _results[index] = _part!;
          }
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully processed return for ${result.quantity} units'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing return: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  // ------------------------------- UI --------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Parts Status Management"),
        backgroundColor: const Color(0xFF2C2C2C),
        centerTitle: true,
        actions: [
          // Show current user
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          authService.currentUser ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.search, color: Color(0xFF2196F3), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Search Parts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Enter part number or name",
                                hintStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.inventory, color: Colors.grey),
                                filled: true,
                                fillColor: const Color(0xFF1A1A1A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onSubmitted: (_) => _search(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _loading ? null : _search,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: _loading
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text("Search"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Selected Part Display
                if (_part != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Selected Part',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _partHeaderCard(_part!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.settings, color: Color(0xFF2196F3), size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Update Part Status",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _statusButton("Mark as Received", Colors.green, Icons.input, _openMarkAsReceived),
                        const SizedBox(height: 8),
                        _statusButton("Mark as Damaged", Colors.red, Icons.warning, _openMarkAsDamaged),
                        const SizedBox(height: 8),
                        _statusButton("Mark as Returned", Colors.orange, Icons.undo, _openMarkAsReturned),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Search Results
                if (!_loading && _results.isNotEmpty) ...[
                  const Text(
                    "Search Results",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final p = _results[i];
                        final isSelected = _part?.id == p.id;
                        return Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2196F3).withOpacity(0.1)
                                : const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2196F3)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(p.status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.inventory,
                                color: _getStatusColor(p.status),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  "SKU: ${p.partNumber}",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  "Category: ${p.category}",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  "Location: ${p.location}",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStockColor(p.quantity).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getStockColor(p.quantity),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    "${p.quantity} units",
                                    style: TextStyle(
                                      color: _getStockColor(p.quantity),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(p.status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getStatusColor(p.status),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    p.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(p.status),
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() => _part = p);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ] else if (_loading) ...[
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2196F3)),
                          SizedBox(height: 16),
                          Text(
                            'Searching parts...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (_searchCtrl.text.isNotEmpty && _results.isEmpty) ...[
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No parts found',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try searching with different keywords',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Search for parts to manage status',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Enter part number or name above',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Loading overlay when updating
          if (_updating)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2196F3)),
                    SizedBox(height: 16),
                    Text(
                      'Updating part status...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------- Helper methods ----------

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'received':
        return Colors.blue;
      case 'damaged':
        return Colors.red;
      case 'returned':
        return Colors.orange;
      case 'out_of_stock':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getStockColor(int quantity) {
    if (quantity == 0) return Colors.red;
    if (quantity < 5) return Colors.orange;
    if (quantity < 10) return Colors.yellow;
    return Colors.green;
  }

  Widget _partHeaderCard(Part part) {
    final name = part.name;
    final sku = part.partNumber;
    final qty = part.quantity;
    final category = part.category;
    final status = part.status;
    final pricing = part.pricing;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory,
              color: _getStatusColor(status),
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                  ),
                ),
                const SizedBox(height: 4),
                Text("SKU: $sku", style: const TextStyle(color: Colors.lightBlue, fontSize: 12)),
                Text("Category: $category", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text("Price: RM ${pricing.toStringAsFixed(2)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStockColor(qty).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getStockColor(qty), width: 1),
                      ),
                      child: Text(
                        "$qty units",
                        style: TextStyle(
                          color: _getStockColor(qty),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getStatusColor(status), width: 1),
                      ),
                      child: Text(
                        status.isEmpty ? '—' : status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
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
    );
  }

  Widget _statusButton(String text, Color color, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _updating ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}