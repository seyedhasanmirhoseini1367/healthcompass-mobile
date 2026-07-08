import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_service.dart';

// ── Upload modes ──────────────────────────────────────────────────────────────

enum _Mode { none, scan, pdf, text, kanta, wearable }

const _modes = [
  (_Mode.scan,     'Scan Paper',     'Take a photo — AI reads and extracts the text',
      Icons.camera_alt_rounded,    Color(0xFFec4899)),
  (_Mode.pdf,      'PDF / Document', 'Lab reports, prescriptions, discharge summaries',
      Icons.picture_as_pdf_rounded, Color(0xFF22c55e)),
  (_Mode.text,     'Paste Text',     'Paste any lab result or note — AI parses it',
      Icons.content_paste_rounded,  Color(0xFFf59e0b)),
  (_Mode.kanta,    'Kanta XML',      'Import Finnish health records',
      Icons.folder_zip_rounded,     Color(0xFF0ea5e9)),
  (_Mode.wearable, 'Wearable Data',  'Apple Watch, Fitbit, Garmin — CSV, JSON, or XML export',
      Icons.watch_rounded,          Color(0xFF6366f1)),
];

const _recordTypes = [
  ('auto', 'Auto-detect'),
  ('lab_result',   'Lab Result'),
  ('prescription', 'Prescription'),
  ('diagnosis',    'Diagnosis'),
  ('vaccination',  'Vaccination'),
  ('imaging',      'Imaging Report'),
  ('wearable',     'Wearable Data'),
  ('discharge',    'Discharge Summary'),
  ('other',        'Other'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class UploadRecordScreen extends StatefulWidget {
  const UploadRecordScreen({super.key});
  @override
  State<UploadRecordScreen> createState() => _UploadRecordScreenState();
}

class _UploadRecordScreenState extends State<UploadRecordScreen> {
  _Mode _mode      = _Mode.none;
  bool  _uploading = false;
  String? _error;
  String? _success;

  // shared
  final _notesCtrl = TextEditingController();
  String _selectedType = 'auto';

  // PDF / Scan / Kanta / Wearable
  PlatformFile? _pickedFile;
  // Scan
  XFile?  _cameraImage;
  String  _ocrText     = '';
  bool    _scanning    = false;
  final   _ocrEditCtrl = TextEditingController();
  // Text paste
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    _textCtrl.dispose();
    _ocrEditCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _mode = _Mode.none; _uploading = false;
      _error = null; _success = null;
      _pickedFile = null; _cameraImage = null;
      _ocrText = ''; _scanning = false;
      _notesCtrl.clear(); _textCtrl.clear(); _ocrEditCtrl.clear();
      _selectedType = 'auto';
    });
  }

  // ── File pickers ───────────────────────────────────────────────────────────

  Future<void> _pickPdf() async {
    final r = await FilePicker.platform.pickFiles(withData: true,
        type: FileType.custom, allowedExtensions: ['pdf','PDF','png','jpg','jpeg']);
    if (r != null && r.files.isNotEmpty) setState(() => _pickedFile = r.files.first);
  }

  Future<void> _pickXml() async {
    final r = await FilePicker.platform.pickFiles(withData: true,
        type: FileType.custom, allowedExtensions: ['xml','XML']);
    if (r != null && r.files.isNotEmpty) setState(() => _pickedFile = r.files.first);
  }

  Future<void> _pickWearable() async {
    final r = await FilePicker.platform.pickFiles(withData: true,
        type: FileType.custom, allowedExtensions: ['csv','json','xml','CSV','JSON','XML']);
    if (r != null && r.files.isNotEmpty) setState(() => _pickedFile = r.files.first);
  }

  Future<void> _takePhoto() async {
    final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
    if (img == null) return;
    setState(() { _cameraImage = img; _scanning = true; _error = null; _ocrText = ''; });
    try {
      final bytes = await img.readAsBytes();
      final text  = await ApiService.scanOcr(imageBytes: bytes, fileName: img.name);
      _ocrEditCtrl.text = text;
      setState(() { _ocrText = text; _scanning = false; });
    } catch (_) {
      setState(() { _error = 'OCR failed. Try again or use Paste Text instead.'; _scanning = false; });
    }
  }

  // ── Submit handlers ────────────────────────────────────────────────────────

  Future<void> _submitPdf() async {
    if (_pickedFile?.bytes == null) {
      setState(() => _error = 'Please select a file.'); return;
    }
    setState(() { _uploading = true; _error = null; });
    try {
      final r = await ApiService.uploadPdf(
        bytes: _pickedFile!.bytes!, fileName: _pickedFile!.name,
        recordType: _selectedType == 'auto' ? null : _selectedType,
        notes: _notesCtrl.text.trim(),
      );
      _onSuccess(r);
    } catch (_) { _onError(); }
  }

  Future<void> _submitText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) { setState(() => _error = 'Please paste some text.'); return; }
    setState(() { _uploading = true; _error = null; });
    try {
      final r = await ApiService.uploadText(
        text: text, recordType: _selectedType, notes: _notesCtrl.text.trim());
      _onSuccess(r);
    } catch (_) { _onError(); }
  }

  Future<void> _submitScan() async {
    final text = _ocrEditCtrl.text.trim();
    if (text.isEmpty) { setState(() => _error = 'No text extracted. Please retake the photo.'); return; }
    setState(() { _uploading = true; _error = null; });
    try {
      final r = await ApiService.uploadText(
        text: text, recordType: _selectedType, notes: _notesCtrl.text.trim());
      _onSuccess(r);
    } catch (_) { _onError(); }
  }

  Future<void> _submitKanta() async {
    if (_pickedFile?.bytes == null) {
      setState(() => _error = 'Please select an XML file.'); return;
    }
    setState(() { _uploading = true; _error = null; });
    try {
      final r = await ApiService.uploadKanta(
        bytes: _pickedFile!.bytes!, fileName: _pickedFile!.name,
        notes: _notesCtrl.text.trim());
      final count = r['records_created'] ?? 0;
      final labs  = r['lab_values_created'] ?? 0;
      setState(() { _success = 'Imported $count record(s) with $labs lab value(s).'; _uploading = false; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) { _onError(); }
  }

  Future<void> _submitWearable() async {
    if (_pickedFile?.bytes == null) {
      setState(() => _error = 'Please select a file.'); return;
    }
    setState(() { _uploading = true; _error = null; });
    try {
      final r = await ApiService.uploadWearable(
        bytes: _pickedFile!.bytes!, fileName: _pickedFile!.name,
        notes: _notesCtrl.text.trim());
      _onSuccess(r);
    } catch (_) { _onError(); }
  }

  void _onSuccess(Map<String, dynamic> r) {
    final flagged = (r['flagged'] as int? ?? 0) > 0;
    setState(() {
      _success = flagged
          ? 'Saved! ⚠️ ${r['flagged']} abnormal value(s) detected.'
          : 'Record saved successfully!';
      _uploading = false;
    });
    Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.of(context).pop(true); });
  }

  void _onError() {
    setState(() { _error = 'Upload failed. Please try again.'; _uploading = false; });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: Text(_mode == _Mode.none ? 'Add Record' : _modeTitle(_mode),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
        leading: _mode != _Mode.none
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _reset)
            : null,
      ),
      body: _mode == _Mode.none ? _modeSelector() : _modeForm(),
    );
  }

  String _modeTitle(_Mode m) => switch (m) {
    _Mode.scan     => 'Scan Paper',
    _Mode.pdf      => 'PDF / Document',
    _Mode.text     => 'Paste Text',
    _Mode.kanta    => 'Kanta XML',
    _Mode.wearable => 'Wearable Data',
    _Mode.none     => 'Add Record',
  };

  // ── Mode selector ──────────────────────────────────────────────────────────

  Widget _modeSelector() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Choose how to add your record',
          style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
      const SizedBox(height: 16),
      ..._modes.map((m) => _modeCard(m.$1, m.$2, m.$3, m.$4, m.$5)),
    ],
  );

  Widget _modeCard(_Mode mode, String title, String subtitle, IconData icon, Color color) =>
    Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() { _mode = mode; _error = null; }),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFe2e8f0)),
            ),
            child: Row(children: [
              Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1e293b))),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
              ])),
              const Icon(Icons.chevron_right, color: Color(0xFFcbd5e1)),
            ]),
          ),
        ),
      ),
    );

  // ── Mode form ──────────────────────────────────────────────────────────────

  Widget _modeForm() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_success != null) _banner(_success!, const Color(0xFF22c55e), Icons.check_circle_rounded),
      if (_error   != null) _banner(_error!,   const Color(0xFFef4444), Icons.error_outline_rounded),
      if (_success == null && _error == null || _error != null) ...[
        _formBody(),
        const SizedBox(height: 20),
        _notesField(),
        const SizedBox(height: 20),
        _submitButton(),
      ],
    ]),
  );

  Widget _formBody() {
    return switch (_mode) {
      _Mode.scan     => _scanForm(),
      _Mode.pdf      => _fileForm('PDF or image file', _pickPdf,
          hint: 'PDF, PNG, JPG supported', icon: Icons.picture_as_pdf_rounded),
      _Mode.text     => _textForm(),
      _Mode.kanta    => _fileForm('Kanta XML file', _pickXml,
          hint: 'Export from kanta.fi → select XML file', icon: Icons.folder_zip_rounded),
      _Mode.wearable => _fileForm('Wearable export file', _pickWearable,
          hint: 'CSV, JSON, or XML from your device', icon: Icons.watch_rounded),
      _Mode.none     => const SizedBox.shrink(),
    };
  }

  Widget _scanForm() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    // Camera button
    GestureDetector(
      onTap: _scanning || _uploading ? null : _takePhoto,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFFec4899).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFec4899).withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(children: [
          if (_scanning)
            const CircularProgressIndicator(color: Color(0xFFec4899))
          else
            Icon(
              _cameraImage != null ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
              size: 44,
              color: _cameraImage != null ? const Color(0xFF22c55e) : const Color(0xFFec4899),
            ),
          const SizedBox(height: 10),
          Text(
            _scanning ? 'Extracting text with AI…'
                : _cameraImage != null ? 'Photo captured — retake?'
                : 'Tap to open camera',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _cameraImage != null ? const Color(0xFF22c55e) : const Color(0xFFec4899),
            ),
          ),
        ]),
      ),
    ),
    // OCR result editor
    if (_ocrText.isNotEmpty) ...[
      const SizedBox(height: 16),
      const Text('Extracted text (review and edit if needed)',
          style: TextStyle(color: Color(0xFF64748b), fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: _ocrEditCtrl,
        maxLines: 8,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        ),
      ),
      const SizedBox(height: 14),
      _typeSelector(),
    ],
  ]);

  Widget _fileForm(String label, VoidCallback onPick,
      {required String hint, required IconData icon}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GestureDetector(
        onTap: _uploading ? null : onPick,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _pickedFile != null ? const Color(0xFF22c55e) : const Color(0xFFe2e8f0),
              width: 1.5),
          ),
          child: _pickedFile == null
              ? Column(children: [
                  Icon(icon, size: 40, color: const Color(0xFF0ea5e9)),
                  const SizedBox(height: 10),
                  Text('Tap to select $label',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0ea5e9))),
                  const SizedBox(height: 4),
                  Text(hint, style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12)),
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
      if (_mode != _Mode.kanta && _mode != _Mode.wearable) ...[
        const SizedBox(height: 14),
        _typeSelector(),
      ],
    ],
  );

  Widget _textForm() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    TextFormField(
      controller: _textCtrl,
      maxLines: 10,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Paste your lab result, prescription, or clinical note here…',
        hintStyle: const TextStyle(color: Color(0xFF94a3b8)),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFf59e0b), width: 1.5)),
      ),
    ),
    const SizedBox(height: 14),
    _typeSelector(),
  ]);

  Widget _typeSelector() => DropdownButtonFormField<String>(
    value: _selectedType,
    decoration: InputDecoration(
      labelText: 'Record type',
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
    ),
    items: _recordTypes.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
    onChanged: (v) => setState(() => _selectedType = v!),
  );

  Widget _notesField() => TextFormField(
    controller: _notesCtrl,
    maxLines: 2,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      labelText: 'Notes (optional)',
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0ea5e9), width: 1.5)),
    ),
  );

  Widget _submitButton() {
    VoidCallback? onTap;
    if (!_uploading) {
      onTap = switch (_mode) {
        _Mode.scan     => _submitScan,
        _Mode.pdf      => _submitPdf,
        _Mode.text     => _submitText,
        _Mode.kanta    => _submitKanta,
        _Mode.wearable => _submitWearable,
        _Mode.none     => null,
      };
    }
    final modeInfo = _modes.firstWhere((m) => m.$1 == _mode,
        orElse: () => (_Mode.none, '', '', Icons.upload, const Color(0xFF0ea5e9)));
    final color = modeInfo.$5;

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: _uploading
          ? const SizedBox(height: 20, width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text('Save Record', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }

  Widget _banner(String text, Color color, IconData icon) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );
}
