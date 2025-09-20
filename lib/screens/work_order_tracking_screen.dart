import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/parts_service.dart';
import '../models/part.dart';
import '../models/auth_service.dart';
import 'package:intl/intl.dart';

class WorkOrderTrackingScreen extends StatefulWidget {
  const WorkOrderTrackingScreen({super.key});

  @override
  State<WorkOrderTrackingScreen> createState() => _WorkOrderTrackingScreenState();
}

class _WorkOrderTrackingScreenState extends State<WorkOrderTrackingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Approved', 'Fulfilled', 'Cancelled'];
  bool _isLoading = false;

  // Cache for part details
  Map<String, Part> _partCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final partsService = context.read<PartsService>();
      partsService.fetchIssues();
      partsService.fetchRequests();
      _loadPartsCache();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load all parts into cache for quick lookup
  Future<void> _loadPartsCache() async {
    try {
      final partsService = context.read<PartsService>();
      await partsService.fetchParts();
      setState(() {
        _partCache = {for (var part in partsService.parts) part.id: part};
      });
    } catch (e) {
      print('Error loading parts cache: $e');
    }
  }

  // Get part name from cache
  String _getPartName(String partId) {
    return _partCache[partId]?.name ?? 'Unknown Part';
  }

  // Get part number from cache
  String _getPartNumber(String partId) {
    return _partCache[partId]?.partNumber ?? 'Unknown';
  }

  Future<void> _cancelIssue(PartIssue issue) async {
    final confirmed = await _showConfirmationDialog(
      'Cancel Issue',
      'Are you sure you want to cancel this issue? This will restore the parts to inventory.',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final partsService = context.read<PartsService>();

      // Get the part details
      final part = await partsService.getPartById(issue.partId);
      if (part != null) {
        // Restore the quantity back to inventory
        final newQuantity = part.quantity + issue.quantityIssued;
        await partsService.updatePartQuantity(issue.partId, newQuantity);

        // Mark issue as cancelled (you'll need to add this method)
        await partsService.cancelIssue(issue.id);

        // Refresh data
        await partsService.fetchIssues();
        await partsService.fetchParts();
        await _loadPartsCache();

        _showSuccessMessage('Issue cancelled successfully. ${issue.quantityIssued} units restored to inventory.');
      }
    } catch (e) {
      _showErrorMessage('Error cancelling issue: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRequest(PartRequest request) async {
    final confirmed = await _showConfirmationDialog(
      'Cancel Request',
      'Are you sure you want to cancel this request?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final partsService = context.read<PartsService>();
      await partsService.cancelRequest(request.id);
      await partsService.fetchRequests();

      _showSuccessMessage('Request cancelled successfully.');
    } catch (e) {
      _showErrorMessage('Error cancelling request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(PartRequest request) async {
    final confirmed = await _showConfirmationDialog(
      'Approve Request',
      'Are you sure you want to approve this request? This will add ${request.quantityRequested} units to inventory.',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final partsService = context.read<PartsService>();
      final authService = context.read<AuthService>();

      // Get current part
      final part = await partsService.getPartById(request.partId);
      if (part != null) {
        // Add requested quantity to inventory
        final newQuantity = part.quantity + request.quantityRequested;
        await partsService.updatePartQuantity(request.partId, newQuantity);

        // Mark request as fulfilled
        await partsService.fulfillRequest(
            request.id,
            authService.currentUser ?? 'System'
        );

        // Refresh data
        await partsService.fetchRequests();
        await partsService.fetchParts();
        await _loadPartsCache();

        _showSuccessMessage('Request approved! ${request.quantityRequested} units added to inventory.');
      }
    } catch (e) {
      _showErrorMessage('Error approving request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Work Order Tracking'),
        backgroundColor: const Color(0xFF2C2C2C),
        actions: [
          IconButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              final partsService = context.read<PartsService>();
              await partsService.fetchIssues();
              await partsService.fetchRequests();
              await _loadPartsCache();
              setState(() => _isLoading = false);
              _showSuccessMessage('Data refreshed');
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2196F3),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Issues'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Filter: ',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                                backgroundColor: const Color(0xFF2C2C2C),
                                selectedColor: const Color(0xFF2196F3),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIssuesTab(),
                    _buildRequestsTab(),
                  ],
                ),
              ),
            ],
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2196F3)),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIssuesTab() {
    return Consumer<PartsService>(
      builder: (context, partsService, child) {
        if (partsService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2196F3)),
          );
        }

        final issues = partsService.issues;
        if (issues.isEmpty) {
          return _buildEmptyState(
            'No issues found',
            'Issues will appear here when parts are distributed',
            Icons.assignment_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: issues.length,
          itemBuilder: (context, index) {
            final issue = issues[index];
            return _buildIssueCard(issue);
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return Consumer<PartsService>(
      builder: (context, partsService, child) {
        if (partsService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2196F3)),
          );
        }

        final requests = _getFilteredRequests(partsService.requests);
        if (requests.isEmpty) {
          return _buildEmptyState(
            _selectedFilter == 'All' ? 'No requests found' : 'No ${_selectedFilter.toLowerCase()} requests',
            'Requests will appear here when parts are needed',
            Icons.request_page_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<PartRequest> _getFilteredRequests(List<PartRequest> requests) {
    if (_selectedFilter == 'All') return requests;
    return requests.where((request) =>
    request.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  Widget _buildIssueCard(PartIssue issue) {
    final partName = _getPartName(issue.partId);
    final partNumber = _getPartNumber(issue.partId);

    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show part name instead of issue ID
                      Text(
                        partName,
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Part: $partNumber',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (issue.workOrder != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Work Order: ${issue.workOrder}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: const Text(
                        'ISSUED',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _cancelIssue(issue),
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                      tooltip: 'Cancel Issue',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details
            _buildDetailRow('Quantity:', '${issue.quantityIssued}'),
            _buildDetailRow('Type:', issue.issueType.toUpperCase()),
            _buildDetailRow('Issued By:', issue.issuedBy),
            _buildDetailRow('Date:', DateFormat('MMM dd, yyyy HH:mm').format(issue.issuedAt)),

            if (issue.notes != null && issue.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Notes: ${issue.notes}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(PartRequest request) {
    final canApprove = request.status.toLowerCase() == 'pending';
    final canCancel = request.status.toLowerCase() == 'pending';
    final partName = _getPartName(request.partId);
    final partNumber = _getPartNumber(request.partId);

    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show part name instead of request ID
                      Text(
                        partName,
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Part: $partNumber',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (request.workOrder != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Work Order: ${request.workOrder}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildStatusChip(request.status),
                    const SizedBox(width: 8),
                    if (canApprove)
                      IconButton(
                        onPressed: () => _approveRequest(request),
                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        tooltip: 'Approve Request',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (canCancel) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _cancelRequest(request),
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                        tooltip: 'Cancel Request',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details
            _buildDetailRow('Quantity:', '${request.quantityRequested}'),
            _buildDetailRow('Type:', request.requestType.toUpperCase()),
            _buildDetailRow('Requested By:', request.requestedBy),
            _buildDetailRow('Date:', DateFormat('MMM dd, yyyy HH:mm').format(request.requestedAt)),
            if (request.fulfilledAt != null)
              _buildDetailRow('Fulfilled:', DateFormat('MMM dd, yyyy HH:mm').format(request.fulfilledAt!)),

            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Notes: ${request.notes}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'approved':
        color = Colors.blue;
        break;
      case 'fulfilled':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}