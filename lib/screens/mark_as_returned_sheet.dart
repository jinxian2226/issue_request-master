import 'package:flutter/material.dart';

class ReturnFormResult {
  final String returnType;       // Vendor Return | Customer Return
  final String reason;           // from list below
  final int quantity;
  final String? notes;

  ReturnFormResult({
    required this.returnType,
    required this.reason,
    required this.quantity,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'returnType': returnType,
    'reason': reason,
    'quantity': quantity,
    'notes': notes,
  };
}

class MarkAsReturnedSheet extends StatefulWidget {
  final String sku;
  final String name;
  final String imageUrl;
  final int availableQty;

  const MarkAsReturnedSheet({
    super.key,
    required this.sku,
    required this.name,
    required this.imageUrl,
    required this.availableQty,
  });

  @override
  State<MarkAsReturnedSheet> createState() => _MarkAsReturnedSheetState();
}

class _MarkAsReturnedSheetState extends State<MarkAsReturnedSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  String _returnType = 'Vendor Return';
  String _reason = 'Defective Product';
  int _qty = 1;

  final _reasons = const [
    'Defective Product',
    'Wrong Part Ordered',
    'Damaged In Transit',
    'Excess Inventory',
    'Other Reason',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(12, 8, 12, viewInsets + 12),
        child: SingleChildScrollView(
          controller: controller,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Mark as Returned',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('Complete the form to process a return',
                    style: TextStyle(color: Colors.grey[400])),

                const SizedBox(height: 12),

                // Part header
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Image.network(widget.imageUrl, width: 50, height: 50),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Text('Qty:',
                                    style: TextStyle(color: Colors.grey)),
                                const SizedBox(width: 4),
                                Text('${widget.availableQty} units',
                                    style:
                                    const TextStyle(color: Colors.lightBlue)),
                              ],
                            ),
                            Text('SKU: ${widget.sku}',
                                style: const TextStyle(
                                    color: Colors.lightBlue, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _sectionTitle('Return Type'),
                Row(
                  children: [
                    Expanded(
                      child: _pill(
                        label: 'Vendor Return',
                        selected: _returnType == 'Vendor Return',
                        onTap: () => setState(() => _returnType = 'Vendor Return'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _pill(
                        label: 'Customer Return',
                        selected: _returnType == 'Customer Return',
                        onTap: () => setState(() => _returnType = 'Customer Return'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _sectionTitle('Return Reason'),
                Column(
                  children: _reasons.map((r) {
                    return RadioListTile<String>(
                      value: r,
                      groupValue: _reason,
                      onChanged: (v) => setState(() => _reason = v!),
                      title: Text(r),
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.lightBlue,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                _sectionTitle('Return Quantity'),
                _qtyStepper(context),

                const SizedBox(height: 16),

                _sectionTitle('Notes (Optional)'),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add any additional details about this return...',
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (_qty <= 0) return;
                      if (_qty > widget.availableQty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Quantity exceeds available (${widget.availableQty}).'),
                          ),
                        );
                        return;
                      }
                      final result = ReturnFormResult(
                        returnType: _returnType,
                        reason: _reason,
                        quantity: _qty,
                        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
                      );
                      Navigator.of(context).pop(result);
                    },
                    child: const Text('Submit Return'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _qtyStepper(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _stepButton(
            icon: Icons.remove,
            onTap: () => setState(() => _qty = (_qty - 1).clamp(0, 9999)),
          ),
          Expanded(
            child: Center(
              child: Text('$_qty',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          _stepButton(
            icon: Icons.add,
            onTap: () => setState(() => _qty = (_qty + 1).clamp(0, 9999)),
          ),
          const SizedBox(width: 8),
          Text('of ${widget.availableQty} units',
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _stepButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon),
      ),
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.lightBlue : const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(label)),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  );
}
