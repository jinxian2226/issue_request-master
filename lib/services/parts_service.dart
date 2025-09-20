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

  // Issue part
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

  // Request part
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

  // **FIXED STATUS MARKING METHODS**

  // Mark parts as received with correct status values
  Future<void> markAsReceived({
    required String partId,
    required int quantityReceived,
    required String packageType,
    required String condition,
    required String location,
    String? notes,
    String? photoPath,
    String performedBy = 'System User',
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

      // **FIX: Use correct status values**
      String newStatus;
      switch (condition.toLowerCase()) {
        case 'good':
          newStatus = 'available'; // Changed from 'received' to 'available'
          break;
        case 'damaged':
          newStatus = 'damaged';
          break;
        case 'partial':
          newStatus = 'available'; // Partial is still available
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
        // If received_items table doesn't exist, just continue
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
    String performedBy = 'System User',
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
        'status': 'damaged', // This matches the constraint
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', partId);

      // Create detailed damage report (if table exists)
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
        // If damage_reports table doesn't exist, just continue
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
    String performedBy = 'System User',
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
        'status': 'returned', // This matches the constraint
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', partId);

      // Create detailed return record (if table exists)
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
        // If part_returns table doesn't exist, just continue
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