import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/parts_service.dart';
import '../models/part.dart';
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
      await partsService.markAsReceived(
        partId: _part!.id,
        quantityReceived: result.units,
        packageType: result.packageType,
        condition: result.condition,
        location: result.location,
        notes: result.notes,
        photoPath: result.photoPath,
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
      await partsService.markAsDamaged(
        partId: _part!.id,
        quantityDamaged: result.quantity,
        damageType: result.damageType,
        cause: result.cause,
        situation: result.situation,
        description: result.description,
        photos: result.photos,
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
      await partsService.markAsReturned(
        partId: _part!.id,
        quantityReturned: result.quantity,
        returnType: result.returnType,
        reason: result.reason,
        notes: result.notes,
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
      appBar: AppBar(
        title: const Text("Quick Part Status"),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: "Enter part number",
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : _search,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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

                const SizedBox(height: 16),

                if (_part != null) ...[
                  _partHeaderCard(_part!),
                  const SizedBox(height: 16),
                  const Text(
                    "Update Part Status",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _statusButton("Mark as Received", Colors.blue, _openMarkAsReceived),
                  const SizedBox(height: 8),
                  _statusButton("Mark as Damaged", Colors.red, _openMarkAsDamaged),
                  const SizedBox(height: 8),
                  _statusButton("Mark as Returned", Colors.grey, _openMarkAsReturned),
                  const SizedBox(height: 16),
                ],

                // Results
                if (!_loading)
                  Expanded(
                    child: _results.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = _results[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text("SKU: ${p.partNumber}"),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Qty: ${p.quantity}",
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                p.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(p.status),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() => _part = p);
                          },
                        );
                      },
                    ),
                  ),

                if (_loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
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
                    CircularProgressIndicator(),
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
      case 'received':
        return Colors.green;
      case 'damaged':
        return Colors.red;
      case 'returned':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _partHeaderCard(Part part) {
    final name = part.name;
    final sku = part.partNumber;
    final qty = part.quantity;
    final category = part.category;
    final status = part.status ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Image.network(
            "https://cdn-icons-png.flaticon.com/512/609/609361.png",
            height: 60,
            width: 60,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text("SKU: $sku"),
                Text("Category: $category"),
                const SizedBox(height: 2),
                Text("Qty: $qty", style: const TextStyle(color: Colors.green)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _statusButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _updating ? null : onPressed,
        child: Text(text),
      ),
    );
  }
}