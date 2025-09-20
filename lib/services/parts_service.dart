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

  // Update part status for inventory adjustment
  Future<void> updatePartStatus(String partId, String status) async {
    try {
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