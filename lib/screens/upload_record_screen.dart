import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/api_service.dart';

class UploadRecordScreen extends StatefulWidget {
  const UploadRecordScreen({super.key});
  @override
  State<UploadRecordScreen> createState() => _UploadRecordScreenState();
}

class _UploadRecordScreenState extends State<UploadRecordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String  _recordType = 'other';
  String? _recordDate;
  PlatformFile? _pickedFile;
  bool _uploading = false;
  String? _error;

  static const _types = [
    ('lab_result',   'Lab Result'),
    ('prescription', 'Prescription'),
    ('diagnosis',    'Diagnosis'),
    ('vaccination',  'Vaccination'),
    ('imaging',      'Imaging Report'),
    ('wearable',     'Wearable Data'),
    ('discharge',    'Discharge Summary'),
    ('other',        'Other'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0ea5e9)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _recordDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null) {
      setState(() => _error = 'Please select a file to upload.');
      return;
    }
    final bytes = _pickedFile!.bytes;
    if (bytes == null) {
      setState(() => _error = 'Could not read file. Please try again.');
      return;
    }

    setState(() { _uploading = true; _error = null; });
    try {
      await ApiService.uploadRecord(
        fileBytes:  bytes,
        fileName:   _pickedFile!.name,
        title:      _titleCtrl.text.trim(),
        recordType: _recordType,
        recordDate: _recordDate,
        notes:      _notesCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record uploaded successfully!'),
              backgroundColor: Color(0xFF22c55e)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = 'Upload failed. Please check your connection and try again.';
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('Upload Record', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // File picker
            GestureDetector(
              onTap: _uploading ? null : _pickFile,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _pickedFile != null
                        ? const Color(0xFF22c55e)
                        : const Color(0xFFe2e8f0),
                    width: 1.5,
                  ),
                ),
                child: _pickedFile == null
                    ? Column(children: [
                        const Icon(Icons.upload_file_rounded, size: 44, color: Color(0xFF0ea5e9)),
                        const SizedBox(height: 10),
                        const Text('Tap to select a file', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0ea5e9))),
                        const SizedBox(height: 4),
                        const Text('PDF, JPG, PNG, CSV, XLSX and more',
                            style: TextStyle(color: Color(0xFF94a3b8), fontSize: 12)),
                      ])
                    : Row(children: [
                        const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF22c55e), size: 36),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_pickedFile!.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text('${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12)),
                        ])),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF94a3b8), size: 20),
                          onPressed: () => setState(() => _pickedFile = null),
                        ),
                      ]),
              ),
            ),

            const SizedBox(height: 20),

            _field('Title', _titleCtrl, required: true, hint: 'e.g. Blood Test June 2025'),
            const SizedBox(height: 14),

            // Record type dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFe2e8f0))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _recordType,
                  isExpanded: true,
                  style: const TextStyle(color: Color(0xFF1e293b), fontSize: 14, fontFamily: 'Roboto'),
                  items: _types.map((t) => DropdownMenuItem(
                    value: t.$1,
                    child: Text(t.$2),
                  )).toList(),
                  onChanged: (v) => setState(() => _recordType = v!),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFe2e8f0))),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF94a3b8)),
                  const SizedBox(width: 10),
                  Text(
                    _recordDate ?? 'Record date (optional)',
                    style: TextStyle(
                      color: _recordDate != null ? const Color(0xFF1e293b) : const Color(0xFF94a3b8),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (_recordDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _recordDate = null),
                      child: const Icon(Icons.close, size: 16, color: Color(0xFF94a3b8)),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 14),

            _field('Notes', _notesCtrl, required: false, hint: 'Additional notes (optional)', maxLines: 3),
            const SizedBox(height: 24),

            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFfee2e2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFdc2626), fontSize: 13)),
              ),

            ElevatedButton(
              onPressed: _uploading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0ea5e9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _uploading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Upload Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false, String? hint, int maxLines = 1}) =>
    TextFormField(
      controller: ctrl,
      maxLines:   maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText:   label,
        hintText:    hint,
        filled:      true,
        fillColor:   Colors.white,
        border:       OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0ea5e9), width: 1.5)),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
}
