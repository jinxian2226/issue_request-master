import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/part.dart';
import '../models/auth_service.dart';
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
  String _selectedPriority = 'medium';
  bool _isLoading = false;

  List<Map<String, dynamic>> _requestedParts = [];
  double _estimatedTotal = 0.0;

  final List<String> _priorities = ['low', 'medium', 'high', 'urgent'];

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Request Information Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2196F3).withOpacity(0.1),
                      const Color(0xFF1976D2).withOpacity(0.1),
                    ],
                  ),
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
                        const Icon(
                          Icons.request_page,
                          color: Color(0xFF2196F3),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'New Parts Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Consumer<AuthService>(
                      builder: (context, authService, child) {
                        return Text(
                          'Requested by: ${authService.currentUser ?? 'Unknown User'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Request Date: ${DateTime.now().toString().split(' ')[0]}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Parts Section
              _buildSectionHeader('Requested Parts'),
              const SizedBox(height: 16),
              ..._requestedParts.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> item = entry.value;
                return _buildPartItem(item, index);
              }).toList(),

              // Request Type
              _buildSectionHeader('Request Type'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildRadioOption(
                      'Work Order',
                      'work_order',
                      _selectedRequestType,
                          (value) => setState(() => _selectedRequestType = value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRadioOption(
                      'General',
                      'general',
                      _selectedRequestType,
                          (value) => setState(() => _selectedRequestType = value!),
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
                  prefixIcon: Icons.assignment,
                  validator: (value) {
                    if (_selectedRequestType == 'work_order' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter work order number';
                    }
                    return null;
                  },
                  hintText: 'Enter work order reference',
                ),
              ],

              const SizedBox(height: 24),

              // Priority Selection
              _buildSectionHeader('Request Priority'),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  Color color;
                  switch (priority) {
                    case 'urgent':
                      color = Colors.red;
                      break;
                    case 'high':
                      color = Colors.orange;
                      break;
                    case 'medium':
                      color = Colors.blue;
                      break;
                    default:
                      color = Colors.green;
                  }

                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: priority != _priorities.last ? 8 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPriority = priority),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.2) : const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? color : Colors.grey.shade600,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _getPriorityIcon(priority),
                                color: isSelected ? color : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                priority.toUpperCase(),
                                style: TextStyle(
                                  color: isSelected ? color : Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Delivery Options
              _buildSectionHeader('Delivery Options'),
              const SizedBox(height: 8),
              Column(
                children: [
                  _buildDeliveryOption(
                    'Pickup at Depot',
                    'Ready for collection at warehouse',
                    Icons.store,
                    'pickup',
                  ),
                  const SizedBox(height: 8),
                  _buildDeliveryOption(
                    'Delivery to Location',
                    'Parts delivered to work site',
                    Icons.local_shipping,
                    'delivery',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Additional Notes
              _buildSectionHeader('Additional Notes'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _notesController,
                label: '',
                hintText: 'Add any specific requirements, delivery instructions, or details about the request...',
                maxLines: 3,
                prefixIcon: Icons.note_add,
              ),

              const SizedBox(height: 24),

              // Estimated Total
              Card(
                color: const Color(0xFF2C2C2C),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calculate, color: Colors.amber, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Cost Estimate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                            'Processing Fee',
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
                            'Total Estimate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'RM ${(_estimatedTotal + 15.20).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF2196F3),
                              fontSize: 16,
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
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Submitting Request...'),
                        ],
                      )
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
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Help Section
              Container(
                width: double.infinity,
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
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Request Information',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoPoint('High priority requests are processed within 24 hours'),
                    _buildInfoPoint('Work order requests require approval from supervisor'),
                    _buildInfoPoint('Delivery fees may apply for off-site delivery'),
                    _buildInfoPoint('All requests are subject to parts availability'),
                  ],
                ),
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

  Widget _buildPartItem(Map<String, dynamic> item, int index) {
    final Part part = item['part'];
    final int quantity = item['quantity'];

    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF2196F3).withOpacity(0.3),
        ),
      ),
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
                      const SizedBox(height: 4),
                      Text(
                        part.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            color: part.quantity > 0 ? Colors.green : Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Available: ${part.quantity} units',
                            style: TextStyle(
                              color: part.quantity > 0 ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Category: ${part.category}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Location: ${part.location}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_requestedParts.length > 1)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _requestedParts.removeAt(index);
                        _calculateTotal();
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Remove part',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
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
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                        tooltip: 'Decrease quantity',
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF2196F3).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          quantity.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _requestedParts[index]['quantity']++;
                            _calculateTotal();
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                        tooltip: 'Increase quantity',
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Unit: RM ${part.pricing.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Total: RM ${(part.pricing * quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
    IconData? prefixIcon,
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
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
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

  Widget _buildRadioOption(
      String title,
      String value,
      String groupValue,
      void Function(String?) onChanged,
      ) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3).withOpacity(0.2) : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade600,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2196F3) : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2196F3),
                  ),
                ),
              )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOption(String title, String subtitle, IconData icon, String value) {
    final isSelected = _selectedDeliveryOption == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDeliveryOption = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3).withOpacity(0.2) : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade600,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2196F3).withOpacity(0.2) : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF2196F3) : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2196F3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Colors.amber, fontSize: 12),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.priority_high;
      case 'high':
        return Icons.keyboard_arrow_up;
      case 'medium':
        return Icons.remove;
      default:
        return Icons.keyboard_arrow_down;
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

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final partsService = context.read<PartsService>();
      final authService = context.read<AuthService>();

      // Submit request for each part
      for (var item in _requestedParts) {
        final Part part = item['part'];
        final int quantity = item['quantity'];

        await partsService.requestPart(
          partId: part.id,
          quantity: quantity,
          requestType: _selectedRequestType,
          requestedBy: authService.currentUser ?? 'Unknown User', // Use actual logged-in user
          workOrder: _selectedRequestType == 'work_order' ? _workOrderController.text : null,
          notes: _notesController.text.isNotEmpty
              ? 'Priority: ${_selectedPriority.toUpperCase()}, Delivery: $_selectedDeliveryOption. ${_notesController.text}'
              : 'Priority: ${_selectedPriority.toUpperCase()}, Delivery: $_selectedDeliveryOption',
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