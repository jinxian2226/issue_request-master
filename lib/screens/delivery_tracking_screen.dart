import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/parts_service.dart';
import 'package:intl/intl.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({super.key});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final TextEditingController _trackingController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = false;
  String _selectedStatusFilter = 'All';

  final List<String> _statusFilters = [
    'All',
    'pending_pickup',
    'in_transit',
    'out_for_delivery',
    'delivered',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _loadAllDeliveries();
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAllDeliveries() async {
    setState(() => _isLoading = true);
    try {
      final partsService = context.read<PartsService>();
      final deliveries = await partsService.getDeliveries();
      setState(() {
        _deliveries = deliveries;
      });
    } catch (e) {
      print('Error loading deliveries: $e');
      // Handle specific error messages
      String errorMessage;
      if (e.toString().contains('part_deliveries') || e.toString().contains('PGRST205')) {
        errorMessage = 'Delivery tracking is not yet configured.\nPlease contact your administrator to set up the delivery tracking system.';
      } else {
        errorMessage = 'Unable to load deliveries at this time.\nPlease try again later.';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text('Setup Required', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              errorMessage,
              style: const TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to previous screen
                },
                child: const Text('Go Back'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadAllDeliveries(); // Retry
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      setState(() {
        _deliveries = []; // Set empty list to avoid further errors
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchByTracking() async {
    final trackingNumber = _trackingController.text.trim();
    if (trackingNumber.isEmpty) {
      _loadAllDeliveries();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final partsService = context.read<PartsService>();
      final deliveries = await partsService.getDeliveries(trackingNumber: trackingNumber);
      setState(() {
        _deliveries = deliveries;
      });

      if (deliveries.isEmpty && mounted) {
        _showErrorMessage('No delivery found with tracking number: $trackingNumber');
      }
    } catch (e) {
      print('Error searching delivery: $e');
      if (e.toString().contains('part_deliveries') || e.toString().contains('PGRST205')) {
        _showErrorMessage('Delivery tracking system is not configured yet.');
      } else {
        _showErrorMessage('Error searching delivery. Please try again.');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredDeliveries() {
    if (_selectedStatusFilter == 'All') return _deliveries;
    return _deliveries
        .where((delivery) => delivery['status'] == _selectedStatusFilter)
        .toList();
  }

  Future<void> _updateDeliveryStatus(String deliveryId, String currentStatus, Map<String, dynamic> delivery) async {
    final List<String> availableStatuses = [
      'pending_pickup',
      'in_transit',
      'out_for_delivery',
      'delivered',
      'cancelled'
    ];

    String? newStatus;
    String? deliveryNotes;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Update Delivery Status',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current delivery info
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
                        'Tracking: ${delivery['tracking_number']}',
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Recipient: ${delivery['recipient_name']}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        'Current Status: ${_getStatusDisplayName(currentStatus)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Select New Status:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                // Status selection
                ...availableStatuses.map((status) {
                  final isSelected = status == newStatus;
                  final isCurrent = status == currentStatus;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      leading: Icon(
                        _getStatusIcon(status),
                        color: isCurrent ? Colors.grey : _getStatusColor(status),
                        size: 20,
                      ),
                      title: Text(
                        _getStatusDisplayName(status),
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.grey
                              : isSelected
                              ? const Color(0xFF2196F3)
                              : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.check, color: Colors.grey, size: 16)
                          : isSelected
                          ? const Icon(Icons.radio_button_checked, color: Color(0xFF2196F3), size: 16)
                          : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 16),
                      onTap: isCurrent ? null : () {
                        setDialogState(() {
                          newStatus = status;
                        });
                      },
                      enabled: !isCurrent,
                    ),
                  );
                }).toList(),

                if (newStatus != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Delivery Notes (Optional):',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: newStatus == 'delivered'
                          ? 'Delivered to recipient at...'
                          : newStatus == 'cancelled'
                          ? 'Reason for cancellation...'
                          : 'Status update notes...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      deliveryNotes = value.trim().isEmpty ? null : value.trim();
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _notesController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: newStatus == null ? null : () {
                Navigator.pop(context);
                _performStatusUpdate(deliveryId, newStatus!, deliveryNotes);
                _notesController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: newStatus != null ? _getStatusColor(newStatus!) : Colors.grey,
              ),
              child: const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performStatusUpdate(String deliveryId, String newStatus, String? notes) async {
    try {
      setState(() => _isLoading = true);

      final partsService = context.read<PartsService>();
      await partsService.updateDeliveryStatus(
        deliveryId: deliveryId,
        status: newStatus,
        deliveryNotes: notes,
        actualDeliveryDate: newStatus == 'delivered' ? DateTime.now() : null,
      );

      _showSuccessMessage('Delivery status updated to ${_getStatusDisplayName(newStatus)}');
      await _loadAllDeliveries();
    } catch (e) {
      _showErrorMessage('Error updating status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showDeliveryDetails(Map<String, dynamic> delivery) async {
    final part = delivery['parts'];
    final createdAt = DateTime.parse(delivery['created_at']);
    final requestedDate = delivery['requested_delivery_date'] != null
        ? DateTime.parse(delivery['requested_delivery_date'])
        : null;
    final actualDate = delivery['actual_delivery_date'] != null
        ? DateTime.parse(delivery['actual_delivery_date'])
        : null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Row(
          children: [
            const Icon(Icons.local_shipping, color: Color(0xFF2196F3), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Delivery Details',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tracking Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.qr_code, color: Color(0xFF2196F3), size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Tracking Information',
                            style: TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: delivery['tracking_number']));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tracking number copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF2196F3), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                delivery['tracking_number'],
                                style: const TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy, color: Color(0xFF2196F3), size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusChip(delivery['status']),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Part Information
                if (part != null) ...[
                  const Text(
                    'Part Information',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Part Number:', part['part_number']),
                        _buildDetailRow('Name:', part['name']),
                        _buildDetailRow('Category:', part['category']),
                        _buildDetailRow('Quantity:', '${delivery['quantity_sent']} units'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Delivery Information
                const Text(
                  'Delivery Information',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Recipient:', delivery['recipient_name']),
                      _buildDetailRow('Phone:', delivery['recipient_phone']),
                      _buildDetailRow('Address:', delivery['delivery_address'], maxLines: 3),
                      _buildDetailRow('Type:', _getDeliveryTypeDisplayName(delivery['delivery_type'])),
                      _buildDetailRow('Priority:', delivery['priority'].toString().toUpperCase()),
                      if (delivery['delivery_cost'] != null)
                        _buildDetailRow('Cost:', 'RM ${delivery['delivery_cost'].toStringAsFixed(2)}'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Timeline Information
                const Text(
                  'Timeline',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Created:', DateFormat('MMM dd, yyyy HH:mm').format(createdAt)),
                      _buildDetailRow('Sent By:', delivery['sent_by']),
                      if (requestedDate != null)
                        _buildDetailRow('Requested Date:', DateFormat('MMM dd, yyyy').format(requestedDate)),
                      if (actualDate != null)
                        _buildDetailRow('Delivered:', DateFormat('MMM dd, yyyy HH:mm').format(actualDate)),
                    ],
                  ),
                ),

                // Special Instructions
                if (delivery['special_instructions'] != null &&
                    delivery['special_instructions'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Special Instructions',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      delivery['special_instructions'],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],

                // Delivery Notes
                if (delivery['delivery_notes'] != null &&
                    delivery['delivery_notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Delivery Notes',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      delivery['delivery_notes'],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (delivery['status'] != 'delivered' && delivery['status'] != 'cancelled')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateDeliveryStatus(delivery['id'], delivery['status'], delivery);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
              ),
              child: const Text('Update Status'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDeliveries = _getFilteredDeliveries();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Delivery Tracking'),
        backgroundColor: const Color(0xFF2C2C2C),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadAllDeliveries,
            icon: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2C2C2C),
            child: Column(
              children: [
                // Tracking Search
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _trackingController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter tracking number (e.g., TRK-123456)',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _trackingController.text.isNotEmpty
                              ? IconButton(
                            onPressed: () {
                              _trackingController.clear();
                              _loadAllDeliveries();
                            },
                            icon: const Icon(Icons.clear, color: Colors.grey),
                          )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _searchByTracking(),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _searchByTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Status Filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusFilters.length,
                    itemBuilder: (context, index) {
                      final filter = _statusFilters[index];
                      final isSelected = _selectedStatusFilter == filter;
                      final count = filter == 'All'
                          ? _deliveries.length
                          : _deliveries.where((d) => d['status'] == filter).length;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_getStatusDisplayName(filter)),
                              if (count > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : const Color(0xFF2196F3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    count.toString(),
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatusFilter = filter;
                            });
                          },
                          backgroundColor: const Color(0xFF1A1A1A),
                          selectedColor: const Color(0xFF2196F3),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Results Section
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2196F3)),
                  SizedBox(height: 16),
                  Text(
                    'Loading deliveries...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : filteredDeliveries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDeliveries.length,
              itemBuilder: (context, index) {
                final delivery = filteredDeliveries[index];
                return _buildDeliveryCard(delivery);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedStatusFilter == 'All'
                ? Icons.local_shipping_outlined
                : _getStatusIcon(_selectedStatusFilter),
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedStatusFilter == 'All'
                ? 'No deliveries found'
                : 'No ${_getStatusDisplayName(_selectedStatusFilter).toLowerCase()} deliveries',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _trackingController.text.isNotEmpty
                ? 'Try searching with a different tracking number'
                : 'Deliveries will appear here when parts are sent',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_trackingController.text.isNotEmpty) {
                _trackingController.clear();
              }
              setState(() {
                _selectedStatusFilter = 'All';
              });
              _loadAllDeliveries();
            },
            icon: const Icon(Icons.refresh),
            label: Text(_trackingController.text.isNotEmpty ? 'Show All' : 'Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final part = delivery['parts'];
    final createdAt = DateTime.parse(delivery['created_at']);

    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDeliveryDetails(delivery),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tracking number (clickable)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: delivery['tracking_number']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tracking number copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  delivery['tracking_number'],
                                  style: const TextStyle(
                                    color: Color(0xFF2196F3),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.copy,
                                  color: Color(0xFF2196F3),
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Part information
                        if (part != null) ...[
                          Text(
                            '${part['part_number']} - ${part['name']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            part['category'],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],

                        const SizedBox(height: 4),

                        // Recipient
                        Text(
                          'To: ${delivery['recipient_name']}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right side info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _updateDeliveryStatus(delivery['id'], delivery['status'], delivery),
                        child: _buildStatusChip(delivery['status']),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${delivery['quantity_sent']} units',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd').format(createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Quick info row
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.grey,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        delivery['delivery_address'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _getDeliveryTypeIcon(delivery['delivery_type']),
                      color: Colors.grey,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getDeliveryTypeDisplayName(delivery['delivery_type']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Action hint
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap for details',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.7),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (delivery['status'] != 'delivered' && delivery['status'] != 'cancelled')
                    Text(
                      'Tap status to update',
                      style: TextStyle(
                        color: const Color(0xFF2196F3).withOpacity(0.7),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
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

  Widget _buildDetailRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusDisplayName(status),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_pickup':
        return Colors.orange;
      case 'in_transit':
        return Colors.blue;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending_pickup':
        return Icons.schedule;
      case 'in_transit':
        return Icons.local_shipping;
      case 'out_for_delivery':
        return Icons.directions_car;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getDeliveryTypeIcon(String type) {
    switch (type) {
      case 'express':
        return Icons.rocket_launch;
      case 'same_day':
        return Icons.flash_on;
      case 'scheduled':
        return Icons.schedule;
      default:
        return Icons.local_shipping;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'All':
        return 'All Status';
      case 'pending_pickup':
        return 'Pending Pickup';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _getDeliveryTypeDisplayName(String type) {
    switch (type) {
      case 'standard':
        return 'Standard';
      case 'express':
        return 'Express';
      case 'same_day':
        return 'Same Day';
      case 'scheduled':
        return 'Scheduled';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}