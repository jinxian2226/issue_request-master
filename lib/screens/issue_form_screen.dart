import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/part.dart';
import '../models/auth_service.dart';
import '../services/parts_service.dart';
import 'issue_success_screen.dart';

class IssueFormScreen extends StatefulWidget {
  final Part part;

  const IssueFormScreen({super.key, required this.part});

  @override
  State<IssueFormScreen> createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends State<IssueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _workOrderController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedIssueType = 'work_order';
  String _selectedReason = 'Repair';
  bool _isLoading = false;

  final List<String> _issueReasons = [
    'Repair',
    'Scheduled Maintenance',
    'Emergency',
    'Replacement',
  ];

  @override
  void initState() {
    super.initState();
    _partNumberController.text = widget.part.partNumber;
    _quantityController.text = '1';
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUsername = authService.currentUser ?? 'Unknown User';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Issue Form'),
        backgroundColor: const Color(0xFF2C2C2C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete the form to issue parts',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                controller: _partNumberController,
                label: 'Part Number',
                enabled: false,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                initialValue: widget.part.name,
                label: 'Description',
                enabled: false,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _quantityController,
                label: 'Quantity',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  if (quantity > widget.part.quantity) {
                    return 'Not enough stock (Available: ${widget.part.quantity})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Assigned To',
                initialValue: currentUsername,
                enabled: false,
              ),
              const SizedBox(height: 16),

              const Text(
                'Issue Type',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                      groupValue: _selectedIssueType,
                      onChanged: (value) {
                        setState(() {
                          _selectedIssueType = value!;
                        });
                      },
                      activeColor: const Color(0xFF2196F3),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text(
                        'General Use',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      value: 'general',
                      groupValue: _selectedIssueType,
                      onChanged: (value) {
                        setState(() {
                          _selectedIssueType = value!;
                        });
                      },
                      activeColor: const Color(0xFF2196F3),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_selectedIssueType == 'work_order') ...[
                _buildTextField(
                  controller: _workOrderController,
                  label: 'Work Order Number',
                  validator: (value) {
                    if (_selectedIssueType == 'work_order' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter work order number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              const Text(
                'Reason for Issue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade600),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xFF2C2C2C),
                    items: _issueReasons.map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                maxLines: 3,
                hintText: 'Add any additional information or details about the part issue',
              ),
              const SizedBox(height: 32),

              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _issuePart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Issue Part',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
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

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    TextInputType? keyboardType,
    bool enabled = true,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
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
            fillColor: enabled ? const Color(0xFF2C2C2C) : const Color(0xFF1A1A1A),
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade800),
            ),
          ),
        ),
      ],
    );
  }

  void _issuePart() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final partsService = context.read<PartsService>();
      final authService = context.read<AuthService>();
      final currentUsername = authService.currentUser ?? 'Unknown User';

      await partsService.issuePart(
        partId: widget.part.id,
        quantity: int.parse(_quantityController.text),
        issueType: _selectedIssueType,
        issuedBy: currentUsername, // Use the logged-in username
        workOrder: _selectedIssueType == 'work_order' ? _workOrderController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => IssueSuccessScreen(
              part: widget.part,
              quantityIssued: int.parse(_quantityController.text),
              workOrder: _selectedIssueType == 'work_order' ? _workOrderController.text : null,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error issuing part: $e'),
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
    _partNumberController.dispose();
    _quantityController.dispose();
    _workOrderController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}