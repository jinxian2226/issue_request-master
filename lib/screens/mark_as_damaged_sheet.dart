import 'package:flutter/material.dart';

class DamagedFormResult {
  final String damageType;
  final String cause;
  final int quantity;
  final String situation;
  final String? description;
  final List<String>? photos;

  DamagedFormResult({
    required this.damageType,
    required this.cause,
    required this.quantity,
    required this.situation,
    this.description,
    this.photos,
  });

  Map<String, dynamic> toJson() => {
    'damageType': damageType,
    'cause': cause,
    'quantity': quantity,
    'situation': situation,
    'description': description,
    'photos': photos,
  };
}

class MarkAsDamagedSheet extends StatefulWidget {
  final String sku;
  final String name;
  final String imageUrl;
  final int stock;

  const MarkAsDamagedSheet({
    super.key,
    required this.sku,
    required this.name,
    required this.imageUrl,
    required this.stock,
  });

  @override
  State<MarkAsDamagedSheet> createState() => _MarkAsDamagedSheetState();
}

class _MarkAsDamagedSheetState extends State<MarkAsDamagedSheet> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController(text: "1");
  final _descCtrl = TextEditingController();

  String _damageType = 'Physical Damage';
  String _cause = 'Shipping/Transit Damage';
  String _situation = 'Noticed during receiving';
  final List<String> _photos = [];

  final _damageTypes = const [
    'Physical Damage',
    'Water Damage',
    'Packaging Issue',
    'Defective'
  ];
  final _causes = const [
    'Shipping/Transit Damage',
    'Manufacturing Defect',
    'Improper Storage',
    'Other'
  ];
  final _situations = const [
    'Noticed during receiving',
    'Damaged in warehouse',
    'Customer return',
    'Quality control inspection'
  ];

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
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
                  const Text("Mark as Damaged",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),

                  const SizedBox(height: 8),
                  Text("Document damaged parts for inventory adjustment",
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
                        Image.network(widget.imageUrl, height: 50, width: 50),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text("Stock: ${widget.stock} units",
                                  style: const TextStyle(color: Colors.red)),
                              Text("SKU: ${widget.sku}",
                                  style: const TextStyle(
                                      color: Colors.lightBlue, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle('Damage Type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _damageTypes.map((e) {
                      final selected = _damageType == e;
                      return ChoiceChip(
                        label: Text(e),
                        selected: selected,
                        onSelected: (_) => setState(() => _damageType = e),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle('Cause of Damage'),
                  DropdownButtonFormField<String>(
                    value: _cause,
                    items: _causes
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _cause = v!),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF1E1E1E),
                      border: InputBorder.none,
                    ),
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle('Quantity Damaged'),
                  TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: "of ${widget.stock} units",
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter a valid number';
                      if (n > widget.stock) return 'Exceeds stock';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle('Situation'),
                  Column(
                    children: _situations.map((e) {
                      return RadioListTile<String>(
                        value: e,
                        groupValue: _situation,
                        onChanged: (v) => setState(() => _situation = v!),
                        title: Text(e),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle('Damage Description'),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe the damage in detail...',
                      filled: true,
                      fillColor: Color(0xFF1E1E1E),
                      border: InputBorder.none,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) return;
                            final result = DamagedFormResult(
                              damageType: _damageType,
                              cause: _cause,
                              quantity: int.parse(_qtyCtrl.text),
                              situation: _situation,
                              description:
                              _descCtrl.text.isEmpty ? null : _descCtrl.text,
                              photos: _photos,
                            );
                            Navigator.of(context).pop(result);
                          },
                          child: const Text("Submit"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  );
}
