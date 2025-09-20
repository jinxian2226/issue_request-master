import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/part.dart';
import '../services/parts_service.dart';

class RequestFormScreen extends StatefulWidget {
  final Part part;

  const RequestFormScreen({super.key, required this.part});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workOrderController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedRequestType = 'work_order';
  String _selectedDeliveryOption = 'pickup';
  bool _isLoading = false;

  List<Map<String, dynamic>> _requestedParts = [];
  double _estimatedTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _addPartToRequest();
  }

  void _addPartToRequest() {
    setState(() {
      _requestedParts.add({
        'part': widget.part,
        'quantity': 1,
      });
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var item in _requestedParts) {
      final Part part = item['part'];
      final int quantity = item['quantity'];
      total += part.pricing * quantity;
    }
    setState(() {
      _estimatedTotal = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Request Parts'),
        backgroundColor: const Color(0xFF2C2C2C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Information Section
              _buildSectionHeader('Vehicle Information'),
              const SizedBox(height: 16),
              _buildInfoCard([
                _buildInfoRow('Vehicle Brand:', 'Honda'),
                _buildInfoRow('Vin:', 'ABC-1234'),
                _buildInfoRow('Plate:', 'WXY123'),
                _buildInfoRow('Customer Vehicle:', ''),
              ]),
              const SizedBox(height: 24),

              // Parts Section
              _buildSectionHeader('Parts'),
              const SizedBox(height: 16),
              ..._requestedParts.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> item = entry.value;
                return _buildPartItem(item, index);
              }).toList(),

              // Add More Parts Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: OutlinedButton(
                  onPressed: () {
                    // Add functionality to select more parts
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Color(0xFF2196F3)),
                  ),
                  child: const Text('Add More Parts'),
                ),
              ),

              // Additional Notes
              _buildSectionHeader('Additional Notes'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _notesController,
                label: '',
                hintText: 'Add any specific requirements or details about the request...',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Request Type
              _buildSectionHeader('Request Type'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text(
                        'Work Order',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      value: 'work_order',
                      groupValue: _selectedRequestType,
                      onChanged: (value) {
                        setState(() {
                          _selectedRequestType = value!;
                        });
                      },
                      activeColor: const Color(0xFF2196F3),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text(
                        'General',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      value: 'general',
                      groupValue: _selectedRequestType,
                      onChanged: (value) {
                        setState(() {
                          _selectedRequestType = value!;
                        });
                      },
                      activeColor: const Color(0xFF2196F3),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              // Work Order Field (conditional)
              if (_selectedRequestType == 'work_order') ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _workOrderController,
                  label: 'Work Order Number',
                  validator: (value) {
                    if (_selectedRequestType == 'work_order' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter work order number';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Delivery Options
              _buildSectionHeader('Delivery Options'),
              const SizedBox(height: 8),
              Column(
                children: [
                  RadioListTile<String>(
                    title: const Text(
                      'Pickup at Depot',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Ready for collection',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    value: 'pickup',
                    groupValue: _selectedDeliveryOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedDeliveryOption = value!;
                      });
                    },
                    activeColor: const Color(0xFF2196F3),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'Address',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Delivery to specified address',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    value: 'address',
                    groupValue: _selectedDeliveryOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedDeliveryOption = value!;
                      });
                    },
                    activeColor: const Color(0xFF2196F3),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Estimated Total
              Card(
                color: const Color(0xFF2C2C2C),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Parts (${_requestedParts.length})',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'RM ${_estimatedTotal.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.grey),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tax',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            'RM 15.20',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'RM ${(_estimatedTotal + 15.20).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Submit Request',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : () {
                        // Navigate back to part request/issue
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Back Part Request/Issue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      color: const Color(0xFF2C2C2C),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
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

  Widget _buildPartItem(Map<String, dynamic> item, int index) {
    final Part part = item['part'];
    final int quantity = item['quantity'];

    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.partNumber,
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        part.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _requestedParts.removeAt(index);
                      _calculateTotal();
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: quantity > 1 ? () {
                        setState(() {
                          _requestedParts[index]['quantity']--;
                          _calculateTotal();
                        });
                      } : null,
                      icon: const Icon(Icons.remove, color: Colors.white),
                    ),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _requestedParts[index]['quantity']++;
                          _calculateTotal();
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
                Text(
                  'RM ${(part.pricing * quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          enabled: enabled,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade600),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade600),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2196F3)),
            ),
          ),
        ),
      ],
    );
  }

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final partsService = context.read<PartsService>();

      // Submit request for each part
      for (var item in _requestedParts) {
        final Part part = item['part'];
        final int quantity = item['quantity'];

        await partsService.requestPart(
          partId: part.id,
          quantity: quantity,
          requestType: _selectedRequestType,
          requestedBy: 'Current User', // In real app, get from auth
          workOrder: _selectedRequestType == 'work_order' ? _workOrderController.text : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _workOrderController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}