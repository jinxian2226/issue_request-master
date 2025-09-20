class Part {
  final String id;
  final String partNumber;
  final String name;
  final String category;
  final int quantity;
  final String status;
  final String? warehouseBay;
  final String? shelfNumber;
  final double pricing;
  final DateTime createdAt;
  final DateTime updatedAt;

  Part({
    required this.id,
    required this.partNumber,
    required this.name,
    required this.category,
    required this.quantity,
    required this.status,
    this.warehouseBay,
    this.shelfNumber,
    required this.pricing,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      id: json['id'],
      partNumber: json['part_number'],
      name: json['name'],
      category: json['category'],
      quantity: json['quantity'],
      status: json['status'],
      warehouseBay: json['warehouse_bay'],
      shelfNumber: json['shelf_number'],
      pricing: (json['pricing'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'part_number': partNumber,
      'name': name,
      'category': category,
      'quantity': quantity,
      'status': status,
      'warehouse_bay': warehouseBay,
      'shelf_number': shelfNumber,
      'pricing': pricing,
    };
  }

  String get location {
    if (warehouseBay != null && shelfNumber != null) {
      return '$warehouseBay - $shelfNumber';
    }
    return 'No location';
  }
}

class PartIssue {
  final String id;
  final String partId;
  final String? workOrder;
  final int quantityIssued;
  final String issueType;
  final String issuedBy;
  final String? notes;
  final DateTime issuedAt;

  PartIssue({
    required this.id,
    required this.partId,
    this.workOrder,
    required this.quantityIssued,
    required this.issueType,
    required this.issuedBy,
    this.notes,
    required this.issuedAt,
  });

  factory PartIssue.fromJson(Map<String, dynamic> json) {
    return PartIssue(
      id: json['id'],
      partId: json['part_id'],
      workOrder: json['work_order'],
      quantityIssued: json['quantity_issued'],
      issueType: json['issue_type'],
      issuedBy: json['issued_by'],
      notes: json['notes'],
      issuedAt: DateTime.parse(json['issued_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'part_id': partId,
      'work_order': workOrder,
      'quantity_issued': quantityIssued,
      'issue_type': issueType,
      'issued_by': issuedBy,
      'notes': notes,
    };
  }
}

class PartRequest {
  final String id;
  final String partId;
  final String? workOrder;
  final int quantityRequested;
  final String requestType;
  final String requestedBy;
  final String status;
  final String? notes;
  final DateTime requestedAt;
  final DateTime? fulfilledAt;

  PartRequest({
    required this.id,
    required this.partId,
    this.workOrder,
    required this.quantityRequested,
    required this.requestType,
    required this.requestedBy,
    required this.status,
    this.notes,
    required this.requestedAt,
    this.fulfilledAt,
  });

  factory PartRequest.fromJson(Map<String, dynamic> json) {
    return PartRequest(
      id: json['id'],
      partId: json['part_id'],
      workOrder: json['work_order'],
      quantityRequested: json['quantity_requested'],
      requestType: json['request_type'],
      requestedBy: json['requested_by'],
      status: json['status'],
      notes: json['notes'],
      requestedAt: DateTime.parse(json['requested_at']),
      fulfilledAt: json['fulfilled_at'] != null
          ? DateTime.parse(json['fulfilled_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'part_id': partId,
      'work_order': workOrder,
      'quantity_requested': quantityRequested,
      'request_type': requestType,
      'requested_by': requestedBy,
      'status': status,
      'notes': notes,
    };
  }
}