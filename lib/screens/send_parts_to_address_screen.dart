import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/part.dart';
import '../models/auth_service.dart';
import '../services/parts_service.dart';

class SendPartsToAddressScreen extends StatefulWidget {
  final Part part;

  const SendPartsToAddressScreen({super.key, required this.part});

  @override
  State<SendPartsToAddressScreen> createState() => _SendPartsToAddressScreenState();
}

class _SendPartsToAddressScreenState extends State<SendPartsToAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: "1");
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  String _selectedDeliveryType = 'standard';
  String _selectedPriority = 'medium';
  DateTime? _requestedDeliveryDate;
  bool _isLoading = false;

  final List<String> _deliveryTypes = [
    'standard',
    'express',
    'same_day',
    'scheduled'
  ];
  final List<String> _priorities = ['low', 'medium', 'high', 'urgent'];

  final List<Map<String, String>> _quickAddresses = [
    {
      'name': 'Main Workshop',
      'address': 'Workshop Bay A, Main Building\nKuala Lumpur Industrial Area\n50100 Kuala Lumpur'
    },
    {
      'name': 'Service Center 1',
      'address': 'Service Center 1\nJalan Ampang 123\n50450 Kuala Lumpur'
    },
    {
      'name': 'Warehouse B',
      'address': 'Warehouse B, Storage Complex\nShah Alam Industrial Park\n40000 Shah Alam, Selangor'
    },
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _addressController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _selectQuickAddress(String address) {
    setState(() {
      _addressController.text = address;
    });
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme
                .of(context)
                .colorScheme
                .copyWith(
              primary: const Color(0xFF2196F3),
              surface: const Color(0xFF2C2C2C),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _requestedDeliveryDate = picked;
      });
    }
  }

  double _calculateDeliveryCost() {
    double baseCost = 15.00;
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    switch (_selectedDeliveryType) {
      case 'express':
        baseCost = 35.00;
        break;
      case 'same_day':
        baseCost = 55.00;
        break;
      case 'scheduled':
        baseCost = 25.00;
        break;
      default:
        baseCost = 15.00;
    }

    switch (_selectedPriority) {
      case 'high':
        baseCost *= 1.3;
        break;
      case 'urgent':
        baseCost *= 1.6;
        break;
    }

    // Additional cost for multiple items
    if (quantity > 1) {
      baseCost += (quantity - 1) * 5.00;
    }

    return baseCost;
  }

  @override
  Widget build(BuildContext context) {
    final deliveryCost = _calculateDeliveryCost();
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final totalValue = widget.part.pricing * quantity;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Send Parts to Address'),
        backgroundColor: const Color(0xFF2C2C2C),
        actions: [
          // Show current user
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
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
              // Send Information Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.1),
                      Colors.teal.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_shipping,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Send Parts Delivery',
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
                          'Sent by: ${authService.currentUser ??
                              'Unknown User'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send Date: ${DateTime.now().toString().split(' ')[0]}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Part Information
              _buildSectionHeader('Part to Send'),
              const SizedBox(height: 16),
              _buildPartCard(),

              const SizedBox(height: 24),

              // Quantity Selection
              _buildSectionHeader('Quantity'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: quantity > 1 ? () {
                        setState(() {
                          _quantityController.text = (quantity - 1).toString();
                        });
                      } : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '1',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        validator: (value) {
                          final qty = int.tryParse(value ?? '');
                          if (qty == null || qty <= 0) {
                            return 'Enter valid quantity';
                          }
                          if (qty > widget.part.quantity) {
                            return 'Not enough stock (Available: ${widget.part
                                .quantity})';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      onPressed: quantity < widget.part.quantity ? () {
                        setState(() {
                          _quantityController.text = (quantity + 1).toString();
                        });
                      } : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available stock: ${widget.part.quantity} units',
                style: TextStyle(
                  color: widget.part.quantity > 0 ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 24),

              // Recipient Information
              _buildSectionHeader('Recipient Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _recipientNameController,
                label: 'Recipient Name',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter recipient name';
                  }
                  return null;
                },
                hintText: 'Enter full name of recipient',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _recipientPhoneController,
                label: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter valid phone number';
                  }
                  return null;
                },
                hintText: '+60123456789',
              ),

              const SizedBox(height: 24),

              // Delivery Address
              _buildSectionHeader('Delivery Address'),
              const SizedBox(height: 8),

              // Quick Address Buttons
              if (_quickAddresses.isNotEmpty) ...[
                const Text(
                  'Quick Addresses:',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickAddresses.map((addr) =>
                      _buildQuickAddressChip(addr)).toList(),
                ),
                const SizedBox(height: 16),
              ],

              _buildTextField(
                controller: _addressController,
                label: '',
                hintText: 'Enter complete delivery address\nInclude building, street, city, and postal code',
                maxLines: 4,
                prefixIcon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter delivery address';
                  }
                  if (value.length < 20) {
                    return 'Please enter complete address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Delivery Options
              _buildSectionHeader('Delivery Options'),
              const SizedBox(height: 16),

              // Delivery Type
              const Text(
                'Delivery Type',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: _deliveryTypes.map((type) =>
                    _buildDeliveryTypeOption(type)).toList(),
              ),

              const SizedBox(height: 16),

              // Priority Level
              const Text(
                'Priority Level',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  Color color = _getPriorityColor(priority);

                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: priority != _priorities.last ? 8 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedPriority = priority),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.2)
                                : const Color(0xFF2C2C2C),
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

              // Requested Delivery Date
              const Text(
                'Requested Delivery Date (Optional)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDeliveryDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade600),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _requestedDeliveryDate != null
                              ? '${_requestedDeliveryDate!
                              .day}/${_requestedDeliveryDate!
                              .month}/${_requestedDeliveryDate!.year}'
                              : 'Select delivery date',
                          style: TextStyle(
                            color: _requestedDeliveryDate != null
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_requestedDeliveryDate != null)
                        IconButton(
                          onPressed: () =>
                              setState(() => _requestedDeliveryDate = null),
                          icon: const Icon(Icons.clear, color: Colors.grey,
                              size: 20),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Special Instructions
              _buildSectionHeader('Special Instructions'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _specialInstructionsController,
                label: '',
                hintText: 'Any special handling, security requirements, or delivery instructions...',
                maxLines: 3,
                prefixIcon: Icons.note_add,
              ),

              const SizedBox(height: 24),

              // Cost Summary
              Card(
                color: const Color(0xFF2C2C2C),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt, color: Colors.green,
                              size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Delivery Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                          'Parts Value', 'RM ${totalValue.toStringAsFixed(2)}'),
                      _buildSummaryRow('Quantity', '$quantity units'),
                      _buildSummaryRow('Delivery Type',
                          _selectedDeliveryType
                              .replaceAll('_', ' ')
                              .toUpperCase()),
                      _buildSummaryRow(
                          'Priority', _selectedPriority.toUpperCase()),
                      _buildSummaryRow('Delivery Cost',
                          'RM ${deliveryCost.toStringAsFixed(2)}'),
                      const Divider(color: Colors.grey),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Cost',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'RM ${(totalValue + deliveryCost).toStringAsFixed(
                                2)}',
                            style: const TextStyle(
                              color: Colors.green,
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
                      onPressed: _isLoading ? null : _sendParts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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
                          Text('Processing Delivery...'),
                        ],
                      )
                          : const Text(
                        'Send Parts',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : () =>
                          Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Information Section
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
                          color: Colors.blue,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delivery Information',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoPoint('Standard delivery: 2-3 business days'),
                    _buildInfoPoint('Express delivery: Next business day'),
                    _buildInfoPoint(
                        'Same day delivery: Within 8 hours (KL area only)'),
                    _buildInfoPoint(
                        'Tracking number will be provided after dispatch'),
                    _buildInfoPoint(
                        'Delivery confirmation required upon receipt'),
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

  Widget _buildPartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory,
              color: Colors.green,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.part.partNumber,
                  style: const TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.part.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.part.category,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Location: ${widget.part.location}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'RM ${widget.part.pricing.toStringAsFixed(2)}/unit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
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
            prefixIcon: prefixIcon != null ? Icon(
                prefixIcon, color: Colors.grey) : null,
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
              borderSide: const BorderSide(color: Colors.green),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddressChip(Map<String, String> address) {
    return GestureDetector(
      onTap: () => _selectQuickAddress(address['address']!),
      child: Chip(
        label: Text(
          address['name']!,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: const Color(0xFF2C2C2C),
        side: BorderSide(color: Colors.grey.shade600),
        avatar: const Icon(Icons.location_on, color: Colors.blue, size: 16),
      ),
    );
  }

  Widget _buildDeliveryTypeOption(String type) {
    final isSelected = _selectedDeliveryType == type;
    final info = _getDeliveryTypeInfo(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedDeliveryType = type),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.withOpacity(0.2) : const Color(
                0xFF2C2C2C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.grey.shade600,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey,
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
                      color: Colors.green,
                    ),
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Icon(
                info['icon'] as IconData,
                color: isSelected ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info['title'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.green : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      info['description'] as String,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                info['duration'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.green : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            style: TextStyle(color: Colors.blue, fontSize: 12),
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

  Map<String, dynamic> _getDeliveryTypeInfo(String type) {
    switch (type) {
      case 'standard':
        return {
          'title': 'Standard Delivery',
          'description': 'Regular delivery service',
          'duration': '2-3 days',
          'icon': Icons.local_shipping,
        };
      case 'express':
        return {
          'title': 'Express Delivery',
          'description': 'Priority handling and faster delivery',
          'duration': '1 day',
          'icon': Icons.rocket_launch,
        };
      case 'same_day':
        return {
          'title': 'Same Day Delivery',
          'description': 'Urgent delivery within the same day',
          'duration': '4-8 hours',
          'icon': Icons.flash_on,
        };
      case 'scheduled':
        return {
          'title': 'Scheduled Delivery',
          'description': 'Delivery on your preferred date',
          'duration': 'As requested',
          'icon': Icons.schedule,
        };
      default:
        return {
          'title': 'Standard',
          'description': 'Regular delivery',
          'duration': '2-3 days',
          'icon': Icons.local_shipping,
        };
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.green;
    }
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

  void _sendParts() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final partsService = context.read<PartsService>();
      final authService = context.read<AuthService>();

      final deliveryCost = _calculateDeliveryCost();
      final quantity = int.parse(_quantityController.text);

      await partsService.sendPartsToAddress(
        partId: widget.part.id,
        quantitySent: quantity,
        deliveryAddress: _addressController.text.trim(),
        recipientName: _recipientNameController.text.trim(),
        recipientPhone: _recipientPhoneController.text.trim(),
        deliveryType: _selectedDeliveryType,
        priority: _selectedPriority,
        specialInstructions: _specialInstructionsController.text
            .trim()
            .isNotEmpty
            ? _specialInstructionsController.text.trim()
            : null,
        requestedDeliveryDate: _requestedDeliveryDate,
        sentBy: authService.currentUser ?? 'Unknown User',
        deliveryCost: deliveryCost,
      );

      if (mounted) {
        // Show success dialog with tracking information
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              AlertDialog(
                backgroundColor: const Color(0xFF2C2C2C),
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Delivery Scheduled!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your parts have been scheduled for delivery.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking ID: TRK-${DateTime
                                .now()
                                .millisecondsSinceEpoch
                                .toString()
                                .substring(7)}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Part: ${widget.part.partNumber}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'Quantity: $quantity units',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'Recipient: ${_recipientNameController.text}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You will receive SMS updates about your delivery status.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.popUntil(
                          context, (route) => route.isFirst); // Go to home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling delivery: $e'),
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
}