import 'package:flutter/material.dart';
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
  final _service = PartsService();

  bool _loading = false;

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
      // If it's different, change this line.
      final parts = await _service.searchParts(q); // returns List<Part>

      setState(() {
        _results = parts;
        // Auto-select the first result
        // _part = parts.isNotEmpty ? parts.first : null;
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
    setState(() {
      _part = Part(
        id: _part!.id,
        partNumber: _part!.partNumber,
        name: _part!.name,
        category: _part!.category,
        quantity: _part!.quantity + result.units,
        status: 'received',
        warehouseBay: _part!.warehouseBay,
        shelfNumber: _part!.shelfNumber,
        pricing: _part!.pricing,
        createdAt: _part!.createdAt,
        updatedAt: DateTime.now(),
      );
    });


    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Received saved (local only).')),
    );
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

    final newQty = (_part!.quantity - result.quantity).clamp(0, 1 << 31);
    setState(() {
      _part = Part(
        id: _part!.id,
        partNumber: _part!.partNumber,
        name: _part!.name,
        category: _part!.category,
        quantity: newQty,
        status: 'damaged',
        warehouseBay: _part!.warehouseBay,
        shelfNumber: _part!.shelfNumber,
        pricing: _part!.pricing,
        createdAt: _part!.createdAt,
        updatedAt: DateTime.now(),
      );
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Damage recorded (local only).')),
    );
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

    final newQty = (_part!.quantity - result.quantity).clamp(0, 1 << 31);
    setState(() {
      _part = Part(
        id: _part!.id,
        partNumber: _part!.partNumber,
        name: _part!.name,
        category: _part!.category,
        quantity: newQty,
        status: 'returned',
        warehouseBay: _part!.warehouseBay,
        shelfNumber: _part!.shelfNumber,
        pricing: _part!.pricing,
        createdAt: _part!.createdAt,
        updatedAt: DateTime.now(),
      );
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Return submitted (local only).')),
    );
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
      body: Padding(
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
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text("Search"),
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
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(child: CircularProgressIndicator()),
              ),

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
                      trailing: Text(
                        "Qty: ${p.quantity}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        setState(() => _part = p);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: "Scan"),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle), label: "Received"),
          BottomNavigationBarItem(
              icon: Icon(Icons.warning), label: "Issues"),
        ],
      ),
    );
  }

  // ---------- Small widgets ----------

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
          Text(
            status.isEmpty ? '—' : status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              color: status == 'damaged'
                  ? Colors.redAccent
                  : status == 'returned'
                  ? Colors.amber
                  : Colors.greenAccent,
              fontWeight: FontWeight.w600,
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
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
