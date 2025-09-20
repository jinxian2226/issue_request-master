import 'package:flutter/material.dart';

class ReceivedFormResult {
  final int units;
  final String packageType;
  final String condition;      // Good | Damaged | Partial
  final String location;
  final String? notes;
  final String? photoPath;     // placeholder

  ReceivedFormResult({
    required this.units,
    required this.packageType,
    required this.condition,
    required this.location,
    this.notes,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
    'units': units,
    'packageType': packageType,
    'condition': condition,
    'location': location,
    'notes': notes,
    'photoPath': photoPath,
  };
}

class MarkAsReceivedSheet extends StatefulWidget {
  final String sku;
  final String name;
  final String imageUrl;
  final int expectedUnits;
  final String tierLabel;

  const MarkAsReceivedSheet({
    super.key,
    required this.sku,
    required this.name,
    required this.imageUrl,
    required this.expectedUnits,
    required this.tierLabel,
  });

  @override
  State<MarkAsReceivedSheet> createState() => _MarkAsReceivedSheetState();
}

class _MarkAsReceivedSheetState extends State<MarkAsReceivedSheet> {
  final _formKey = GlobalKey<FormState>();
  final _unitsCtrl = TextEditingController(text: "12");
  final _notesCtrl = TextEditingController();

  String _pkgType = 'Box';
  String _condition = 'Good';
  String _location = 'Aisle A - Shelf 3';
  String? _photoPath;

  final _pkgTypes = const ['Box', 'Carton', 'Bag', 'Loose'];
  final _locations = const [
    'Aisle A - Shelf 3',
    'Aisle B - Shelf 1',
    'Receiving Dock',
    'QA Hold'
  ];

  @override
  void dispose() {
    _unitsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.96,
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
                  // Handle
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.settings, size: 18, color: Colors.lightBlue),
                      SizedBox(width: 6),
                      Text('Mark as Received',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Part header card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Image.network(widget.imageUrl, height: 56, width: 56),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 8,
                                children: [
                                  Text('Expected: ${widget.expectedUnits} units',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                  Text('SKU: ${widget.sku}',
                                      style: const TextStyle(
                                          color: Colors.lightBlue, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(widget.tierLabel,
                            style: const TextStyle(
                                color: Colors.lightBlue, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _sectionTitle('Quantity Received'),
                  Row(
                    children: [
                      Expanded(
                        child: _boxed(
                          child: TextFormField(
                            controller: _unitsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Units',
                              border: InputBorder.none,
                            ),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n <= 0) {
                                return 'Enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _boxed(
                          child: DropdownButtonFormField<String>(
                            value: _pkgType,
                            items: _pkgTypes
                                .map((e) => DropdownMenuItem(
                                value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setState(() => _pkgType = v!),
                            decoration: const InputDecoration(
                              labelText: 'Package Type',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _sectionTitle('Condition'),
                  Row(
                    children: [
                      Expanded(child: _pillButton('Good',
                          selected: _condition == 'Good', onTap: () {
                            setState(() => _condition = 'Good');
                          })),
                      const SizedBox(width: 8),
                      Expanded(child: _pillButton('Damaged',
                          selected: _condition == 'Damaged', onTap: () {
                            setState(() => _condition = 'Damaged');
                          })),
                      const SizedBox(width: 8),
                      Expanded(child: _pillButton('Partial',
                          selected: _condition == 'Partial', onTap: () {
                            setState(() => _condition = 'Partial');
                          })),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _sectionTitle('Storage Location'),
                  _boxed(
                    child: DropdownButtonFormField<String>(
                      value: _location,
                      items: _locations
                          .map((e) => DropdownMenuItem(
                          value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _location = v!),
                      decoration: const InputDecoration(
                        labelText: 'Choose location',
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _sectionTitle('Notes'),
                  _boxed(
                    child: TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add any notes about this delivery...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final result = ReceivedFormResult(
                          units: int.parse(_unitsCtrl.text),
                          packageType: _pkgType,
                          condition: _condition,
                          location: _location,
                          notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
                          photoPath: _photoPath,
                        );
                        Navigator.of(context).pop(result);
                      },
                      child: const Text('Submit'),
                    ),
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
    child: Text(t, style: const TextStyle(
        fontWeight: FontWeight.bold, fontSize: 14)),
  );

  Widget _boxed({required Widget child, double? height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _pillButton(String label,
      {required bool selected, required VoidCallback onTap}) {
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
}
