import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../core/api_service.dart';

class SeizureAnalysisScreen extends StatefulWidget {
  const SeizureAnalysisScreen({super.key});
  @override
  State<SeizureAnalysisScreen> createState() => _SeizureAnalysisScreenState();
}

class _SeizureAnalysisScreenState extends State<SeizureAnalysisScreen> {
  PlatformFile? _selectedFile;
  bool  _analyzing = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['parquet', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _selectedFile = result.files.first;
      _result       = null;
      _error        = null;
    });
  }

  Future<void> _analyze() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) return;
    setState(() { _analyzing = true; _error = null; _result = null; });
    try {
      final res = await ApiService.seizureAnalysis(
        _selectedFile!.bytes!,
        _selectedFile!.name,
      );
      setState(() { _result = res; _analyzing = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('timed out') || e.toString().contains('504')
            ? 'Analysis timed out. The file may be too large or the server is busy. Please try again.'
            : 'Analysis failed. Please check your file and try again.';
        _analyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('EEG Seizure Analysis', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(),
          const SizedBox(height: 20),
          _uploadCard(),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _errorCard(),
          ],
          if (_result != null) ...[
            const SizedBox(height: 20),
            _resultCard(),
          ],
          const SizedBox(height: 32),
          const Center(child: Text(
            'This AI analysis is for research purposes only.\nAlways consult a qualified neurologist.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94a3b8), fontSize: 11, height: 1.6),
          )),
        ],
      ),
    );
  }

  Widget _headerCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF3b82f6), Color(0xFF6366f1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 26)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('EEG Seizure Detection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          Text('Ensemble AI Analysis', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
      const SizedBox(height: 14),
      const Text(
        'Upload a Parquet or CSV EEG file. Our ensemble of 3 deep learning models '
        '(CNN-Transformer, LSTM+Attention, CNN-LSTM Fusion) will analyze it for seizure activity.',
        style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, height: 1.5),
      ),
    ]),
  );

  Widget _uploadCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe2e8f0))),
    child: Column(children: [
      GestureDetector(
        onTap: _analyzing ? null : _pickFile,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFf0f7ff),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0ea5e9).withValues(alpha: 0.3), width: 1.5,
                style: BorderStyle.solid),
          ),
          child: Column(children: [
            Icon(
              _selectedFile != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              size: 40,
              color: _selectedFile != null ? const Color(0xFF22c55e) : const Color(0xFF0ea5e9),
            ),
            const SizedBox(height: 10),
            Text(
              _selectedFile != null
                  ? _selectedFile!.name
                  : 'Tap to select EEG file',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _selectedFile != null ? const Color(0xFF22c55e) : const Color(0xFF0ea5e9),
              ),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 4),
              Text(
                '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12),
              ),
            ] else ...[
              const SizedBox(height: 4),
              const Text('.parquet or .csv formats supported',
                  style: TextStyle(color: Color(0xFF94a3b8), fontSize: 12)),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Row(children: [
        if (_selectedFile != null)
          Expanded(
            child: OutlinedButton(
              onPressed: _analyzing ? null : _pickFile,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFe2e8f0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Change File', style: TextStyle(color: Color(0xFF64748b))),
            ),
          ),
        if (_selectedFile != null) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: (_selectedFile == null || _analyzing) ? null : _analyze,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3b82f6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: _analyzing
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Analyze EEG', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
      if (_analyzing) ...[
        const SizedBox(height: 14),
        const Text('Sending to ensemble AI models… this may take up to 2 minutes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748b), fontSize: 12)),
      ],
    ]),
  );

  Widget _errorCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFef4444).withValues(alpha: 0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: Color(0xFFef4444)),
      const SizedBox(width: 10),
      Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFef4444), fontSize: 13))),
    ]),
  );

  Widget _resultCard() {
    final label      = _result!['ensemble_label'] ?? 'Unknown';
    final votes      = _result!['ensemble_votes'] as Map? ?? {};
    final results    = _result!['results'] as List? ?? [];
    final interp     = _result!['ai_interpretation'] ?? '';
    final isSeizure  = label.toLowerCase().contains('seizure');
    final isLPD      = label.toLowerCase().contains('lpd');
    final color      = isSeizure ? const Color(0xFFef4444)
        : isLPD ? const Color(0xFFf59e0b)
        : const Color(0xFF22c55e);
    final predId = _result!['prediction_id']?.toString();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Ensemble verdict
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(
            isSeizure ? Icons.warning_rounded : isLPD ? Icons.info_rounded : Icons.check_circle_rounded,
            color: color, size: 40,
          ),
          const SizedBox(height: 10),
          Text('Ensemble Verdict', style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          if (votes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 6,
              children: votes.entries.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20)),
                child: Text('${e.key}: ${e.value} vote${e.value == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1e293b))),
              )).toList(),
            ),
          ],
        ]),
      ),

      // Individual model results
      if (results.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFe2e8f0))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Individual Models', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1e293b))),
            const SizedBox(height: 12),
            ...results.where((r) => r['success'] == true).map((r) {
              final conf = r['confidence'] != null
                  ? '${(r['confidence'] * 100).toStringAsFixed(1)}%' : '—';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  const Icon(Icons.memory_rounded, size: 16, color: Color(0xFF94a3b8)),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r['project_title'] ?? r['project_id'] ?? 'Model',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(r['prediction_label'] ?? '', style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                  ])),
                  Text('$conf', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1e293b))),
                ]),
              );
            }),
          ]),
        ),
      ],

      // AI Interpretation
      if (interp.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFe2e8f0))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.psychology_rounded, size: 18, color: Color(0xFF6366f1)),
              SizedBox(width: 8),
              Text('AI Clinical Interpretation',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1e293b))),
            ]),
            const SizedBox(height: 12),
            Text(interp, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.6)),
          ]),
        ),
      ],

      // View full prediction
      if (predId != null) ...[
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.push('/predictions/$predId'),
          icon: const Icon(Icons.analytics_rounded, size: 18),
          label: const Text('View Full Prediction'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6366f1),
            side: const BorderSide(color: Color(0xFF6366f1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
      ],
    ]);
  }
}
