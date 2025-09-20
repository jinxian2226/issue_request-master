
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/part.dart';

class PartsService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Part> _parts = [];
  List<PartIssue> _issues = [];
  List<PartRequest> _requests = [];
  bool _isLoading = false;
  String? _error;

  List<Part> get parts => _parts;
  List<PartIssue> get issues => _issues;
  List<PartRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all parts
  Future<void> fetchParts() async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('parts')
          .select()
          .order('name');

      _parts = (response as List)
          .map((json) => Part.fromJson(json))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Error fetching parts: $e';
    }
    _setLoading(false);
  }

  // Search parts by name, part number, or category
  Future<List<Part>> searchParts(String query) async {
    if (query.isEmpty) return _parts;

    try {
      final response = await _supabase
          .from('parts')
          .select()
          .or('name.ilike.%$query%,part_number.ilike.%$query%,category.ilike.%$query%')
          .order('name');

      return (response as List)
          .map((json) => Part.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error searching parts: $e');
    }
  }

  // Get part by ID
  Future<Part?> getPartById(String id) async {
    try {
      final response = await _supabase
          .from('parts')
          .select()
          .eq('id', id)
          .single();

      return Part.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Update part quantity directly
  Future<void> updatePartQuantity(String partId, int newQuantity) async {
    try {
      await _supabase
          .from('parts')
          .update({
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', partId);

      // Update local cache
      final partIndex = _parts.indexWhere((part) => part.id == partId);
      if (partIndex != -1) {
        await fetchParts(); // Refresh all parts for now
      }
    } catch (e) {
      throw Exception('Error updating part quantity: $e');
    }
  }

  // Issue part (with user from auth)
  Future<void> issuePart({
    required String partId,
    required int quantity,
    required String issueType,
    required String issuedBy,
    String? workOrder,
    String? notes,
  }) async {
    try {
      // Create issue record
      final issueData = {
        'part_id': partId,
        'work_order': workOrder,
        'quantity_issued': quantity,
        'issue_type': issueType,
        'issued_by': issuedBy,
        'notes': notes,
      };

      await _supabase.from('part_issues').insert(issueData);

      // Update part quantity
      final part = await getPartById(partId);
      if (part != null) {
        final newQuantity = part.quantity - quantity;
        await _supabase
            .from('parts')
            .update({'quantity': newQuantity})
            .eq('id', partId);
      }

      await fetchParts();
    } catch (e) {
      throw Exception('Error issuing part: $e');
    }
  }

  // Request part (with user from auth)
  Future<void> requestPart({
    required String partId,
    required int quantity,
    required String requestType,
    required String requestedBy,
    String? workOrder,
    String? notes,
  }) async {
    try {
      final requestData = {
        'part_id': partId,
        'work_order': workOrder,
        'quantity_requested': quantity,
        'request_type': requestType,
        'requested_by': requestedBy,
        'notes': notes,
        'status': 'pending',
      };

      await _supabase.from('part_requests').insert(requestData);
      await fetchRequests();
    } catch (e) {
      throw Exception('Error requesting part: $e');
    }
  }

  // Updated getDeliveries method with correct Supabase syntax
  Future<List<Map<String, dynamic>>> getDeliveries({String? partId, String? trackingNumber}) async {
    try {
      // First try to check if table exists by doing a simple query
      try {
        await _supabase.from('part_deliveries').select('id').limit(1);
      } catch (e) {
        // If table doesn't exist, return empty list
        print('part_deliveries table does not exist: $e');
        return [];
      }

      var query = _supabase.from('part_deliveries').select('''
      id,
      part_id,
      quantity_sent,
      delivery_address,
      recipient_name,
      recipient_phone,
      delivery_type,
      priority,
      special_instructions,
      requested_delivery_date,
      sent_by,
      status,
      tracking_number,
      delivery_cost,
      actual_delivery_date,
      delivery_notes,
      created_at,
      updated_at,
      parts:part_id (
        part_number,
        name,
        category
      )
    ''');

      if (partId != null) {
        query = query.eq('part_id', partId);
      }

      if (trackingNumber != null) {
        query = query.eq('tracking_number', trackingNumber);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching deliveries: $e');
      // Return empty list instead of throwing error
      return [];
    }
  }

// Also update the sendPartsToAddress method to handle table creation
  Future<void> sendPartsToAddress({
    required String partId,
    required int quantitySent,
    required String deliveryAddress,
    required String recipientName,
    required String recipientPhone,
    required String deliveryType,
    required String priority,
    String? specialInstructions,
    DateTime? requestedDeliveryDate,
    required String sentBy,
    required double deliveryCost,
  }) async {
    try {
      // Generate tracking number
      final trackingNumber = 'TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Create delivery record
      final deliveryData = {
        'part_id': partId,
        'quantity_sent': quantitySent,
        'delivery_address': deliveryAddress,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'delivery_type': deliveryType,
        'priority': priority,
        'special_instructions': specialInstructions,
        'requested_delivery_date': requestedDeliveryDate?.toIso8601String(),
        'sent_by': sentBy,
        'status': 'pending_pickup',
        'tracking_number': trackingNumber,
        'delivery_cost': deliveryCost,
      };

      try {
        await _supabase.from('part_deliveries').insert(deliveryData);
      } catch (e) {
        if (e.toString().contains('part_deliveries')) {
          throw Exception('Delivery tracking table not found. Please contact your administrator to set up delivery tracking.');
        }
        throw Exception('Error creating delivery record: $e');
      }

      // Update part quantity (reduce inventory)
      final part = await getPartById(partId);
      if (part != null) {
        final newQuantity = part.quantity - quantitySent;
        await _supabase
            .from('parts')
            .update({
          'quantity': newQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('id', partId);
      }

      // Create transaction record for audit trail
      try {
        await _supabase.from('part_transactions').insert({
          'part_id': partId,
          'transaction_type': 'transferred',
          'quantity': -quantitySent, // Negative because it's leaving inventory
          'previous_quantity': part?.quantity ?? 0,
          'new_quantity': (part?.quantity ?? 0) - quantitySent,
          'notes': 'Parts sent to address: $deliveryAddress (Tracking: $trackingNumber)',
          'performed_by': sentBy,
          'metadata': {
            'delivery_type': deliveryType,
            'recipient_name': recipientName,
            'tracking_number': trackingNumber,
            'delivery_cost': deliveryCost,
          },
        });
      } catch (e) {
        print('Note: part_transactions table not available: $e');
      }

      await fetchParts();
    } catch (e) {
      throw Exception('Error sending parts to address: $e');
    }
  }

  // Update delivery status
  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? deliveryNotes,
    DateTime? actualDeliveryDate,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (deliveryNotes != null) {
        updateData['delivery_notes'] = deliveryNotes;
      }

      if (actualDeliveryDate != null) {
        updateData['actual_delivery_date'] = actualDeliveryDate.toIso8601String();
      }

      await _supabase
          .from('part_deliveries')
          .update(updateData)
          .eq('id', deliveryId);
    } catch (e) {
      if (e.toString().contains('part_deliveries')) {
        throw Exception('Delivery tracking table not found. Please contact your administrator.');
      }
      throw Exception('Error updating delivery status: $e');
    }
  }

  // Cancel an issue (restore inventory)
  Future<void> cancelIssue(String issueId) async {
    try {
      // For now, we'll just delete the issue record
      // In a real system, you might want to mark it as cancelled instead
      await _supabase
          .from('part_issues')
          .delete()
          .eq('id', issueId);
    } catch (e) {
      throw Exception('Error cancelling issue: $e');
    }
  }

  // Cancel a request
  Future<void> cancelRequest(String requestId) async {
    try {
      await _supabase
          .from('part_requests')
          .update({
        'status': 'cancelled',
      })
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Error cancelling request: $e');
    }
  }

  // FIXED: Fulfill/Approve a request (add quantity to inventory)
  Future<void> fulfillRequest(String requestId, String fulfilledBy) async {
    try {
      // Try to update with fulfilled_by column, but handle if it doesn't exist
      try {
        await _supabase
            .from('part_requests')
            .update({
          'status': 'fulfilled',
          'fulfilled_at': DateTime.now().toIso8601String(),
          'fulfilled_by': fulfilledBy,
        })
            .eq('id', requestId);
      } catch (e) {
        // If fulfilled_by column doesn't exist, update without it
        print('Note: fulfilled_by column not found, updating without it');
        await _supabase
            .from('part_requests')
            .update({
          'status': 'fulfilled',
          'fulfilled_at': DateTime.now().toIso8601String(),
        })
            .eq('id', requestId);
      }
    } catch (e) {
      throw Exception('Error fulfilling request: $e');
    }
  }

  // Mark parts as received with correct status values
  Future<void> markAsReceived({
    required String partId,
    required int quantityReceived,
    required String packageType,
    required String condition,
    required String location,
    String? notes,
    String? photoPath,
    required String performedBy,
  }) async {
    try {
      // Get current part data
      final part = await getPartById(partId);
      if (part == null) {
        throw Exception('Part not found');
      }

      final newQuantity = part.quantity + quantityReceived;

      // Parse location for warehouse_bay and shelf_number
      String? warehouseBay;
      String? shelfNumber;
      if (location.isNotEmpty) {
        final locationParts = location.split(' - ');
        if (locationParts.length >= 2) {
          warehouseBay = locationParts[0];
          shelfNumber = locationParts[1];
        }
      }

      // Use correct status values
      String newStatus;
      switch (condition.toLowerCase()) {
        case 'good':
          newStatus = 'available';
          break;
        case 'damaged':
          newStatus = 'damaged';
          break;
        case 'partial':
          newStatus = 'available';
          break;
        default:
          newStatus = 'available';
      }

      // Update part quantity and status
      final updateData = {
        'quantity': newQuantity,
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (warehouseBay != null) updateData['warehouse_bay'] = warehouseBay;
      if (shelfNumber != null) updateData['shelf_number'] = shelfNumber;

      await _supabase.from('parts').update(updateData).eq('id', partId);

      // Create detailed received item record (if table exists)
      try {
        final receivedData = {
          'part_id': partId,
          'quantity_received': quantityReceived,
          'package_type': packageType,
          'condition': condition,
          'location': location,
          'notes': notes,
          'photo_paths': photoPath != null ? [photoPath] : null,
          'received_by': performedBy,
        };

        await _supabase.from('received_items').insert(receivedData);
      } catch (e) {
        print('Note: received_items table not available: $e');
      }

      await fetchParts();
    } catch (e) {
      throw Exception('Error marking part as received: $e');
    }
  }

  // Mark parts as damaged with correct status values
  Future<void> markAsDamaged({
    required String partId,
    required int quantityDamaged,
    required String damageType,
    required String cause,
    required String situation,
    String? description,
    List<String>? photos,
    required String performedBy,
  }) async {
    try {
      // Get current part data
      final part = await getPartById(partId);
      if (part == null) {
        throw Exception('Part not found');
      }

      final newQuantity = (part.quantity - quantityDamaged).clamp(0, 999999);

      // Update part quantity and status
      await _supabase.from('parts').update({
        'quantity': newQuantity,
        'status': 'damaged',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', partId);

      // Create detailed damage report
      try {
        final damageData = {
          'part_id': partId,
          'damage_type': damageType,
          'cause': cause,
          'situation': situation,
          'quantity_damaged': quantityDamaged,
          'description': description,
          'photos': photos,
          'reported_by': performedBy,
        };

        await _supabase.from('damage_reports').insert(damageData);
      } catch (e) {
        print('Note: damage_reports table not available: $e');
      }

      await fetchParts();
    } catch (e) {
      throw Exception('Error marking part as damaged: $e');
    }
  }

  // Mark parts as returned with correct status values
  Future<void> markAsReturned({
    required String partId,
    required int quantityReturned,
    required String returnType,
    required String reason,
    String? notes,
    required String performedBy,
  }) async {
    try {
      // Get current part data
      final part = await getPartById(partId);
      if (part == null) {
        throw Exception('Part not found');
      }

      final newQuantity = (part.quantity - quantityReturned).clamp(0, 999999);

      // Update part quantity and status
      await _supabase.from('parts').update({
        'quantity': newQuantity,
        'status': 'returned',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', partId);

      // Create detailed return record
      try {
        final returnData = {
          'part_id': partId,
          'return_type': returnType,
          'reason': reason,
          'quantity_returned': quantityReturned,
          'notes': notes,
          'returned_by': performedBy,
        };

        await _supabase.from('part_returns').insert(returnData);
      } catch (e) {
        print('Note: part_returns table not available: $e');
      }

      await fetchParts();
    } catch (e) {
      throw Exception('Error marking part as returned: $e');
    }
  }

  // Update part status for inventory adjustment
  Future<void> updatePartStatus(String partId, String status) async {
    try {
      // Ensure status is valid
      const validStatuses = ['received', 'damaged', 'returned', 'available', 'out_of_stock'];
      if (!validStatuses.contains(status)) {
        throw Exception('Invalid status: $status. Valid values: ${validStatuses.join(', ')}');
      }

      await _supabase
          .from('parts')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', partId);

      await fetchParts();
    } catch (e) {
      throw Exception('Error updating part status: $e');
    }
  }

  // Fetch issues
  Future<void> fetchIssues() async {
    try {
      final response = await _supabase
          .from('part_issues')
          .select()
          .order('issued_at', ascending: false);

      _issues = (response as List)
          .map((json) => PartIssue.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'Error fetching issues: $e';
    }
    notifyListeners();
  }

  // Fetch requests
  Future<void> fetchRequests() async {
    try {
      final response = await _supabase
          .from('part_requests')
          .select()
          .order('requested_at', ascending: false);

      _requests = (response as List)
          .map((json) => PartRequest.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'Error fetching requests: $e';
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
