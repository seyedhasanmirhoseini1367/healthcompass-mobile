import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';
import '../models/medical_record.dart';

const _recordTypes = [
  ('', 'All'),
  ('lab_result',   'Lab Results'),
  ('prescription', 'Prescriptions'),
  ('diagnosis',    'Diagnoses'),
  ('imaging',      'Imaging'),
  ('discharge',    'Discharge'),
  ('wearable',     'Wearable'),
  ('vaccination',  'Vaccination'),
  ('other',        'Other'),
];

const _datePresets = [
  ('30d',  '30 Days'),
  ('3m',   '3 Months'),
  ('6m',   '6 Months'),
  ('1y',   '1 Year'),
  ('custom', 'Custom…'),
];

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<MedicalRecord> _records = [];
  bool   _loading          = true;
  String? _error;
  String _selectedType     = '';
  final _searchCtrl        = TextEditingController();
  String _searchQuery      = '';
  String? _datePreset;   // '30d','3m','6m','1y','custom'
  String? _dateFrom;
  String? _dateTo;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q == _searchQuery) return;
    _searchQuery = q;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.records(
        type:     _selectedType.isEmpty ? null : _selectedType,
        q:        _searchQuery.isEmpty  ? null : _searchQuery,
        dateFrom: _dateFrom,
        dateTo:   _dateTo,
      );
      setState(() { _records = data; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Could not load records.'; _loading = false; });
    }
  }

  void _setType(String type) {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
    _load();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _selectPreset(String preset) async {
    if (preset == 'custom') {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2010),
        lastDate: DateTime.now(),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF0ea5e9))),
          child: child!,
        ),
      );
      if (range == null) return;
      setState(() {
        _datePreset = 'custom';
        _dateFrom   = _fmt(range.start);
        _dateTo     = _fmt(range.end);
      });
    } else if (_datePreset == preset) {
      // deselect
      setState(() { _datePreset = null; _dateFrom = null; _dateTo = null; });
    } else {
      final now = DateTime.now();
      DateTime from;
      switch (preset) {
        case '30d': from = now.subtract(const Duration(days: 30));  break;
        case '3m':  from = DateTime(now.year, now.month - 3, now.day); break;
        case '6m':  from = DateTime(now.year, now.month - 6, now.day); break;
        case '1y':  from = DateTime(now.year - 1, now.month, now.day); break;
        default:    from = now.subtract(const Duration(days: 30));
      }
      setState(() { _datePreset = preset; _dateFrom = _fmt(from); _dateTo = _fmt(now); });
    }
    _load();
  }

  bool get _hasFilters => _selectedType.isNotEmpty || _searchQuery.isNotEmpty || _dateFrom != null;

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _selectedType = '';
      _searchQuery  = '';
      _datePreset   = null;
      _dateFrom     = null;
      _dateTo       = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('Medical Records', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
        actions: [
          if (_hasFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Clear', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFef4444)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(children: [
              // Search bar
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search records…',
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94a3b8)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchCtrl.clear())
                      : null,
                  filled: true, fillColor: const Color(0xFFf0f7ff),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              // Dropdown row
              Row(children: [
                // ── Type dropdown ─────────────────────────────────────────
                Expanded(child: _FilterDropdown(
                  icon: Icons.folder_outlined,
                  label: _selectedType.isEmpty
                      ? 'All Types'
                      : _recordTypes
                          .firstWhere((t) => t.$1 == _selectedType,
                              orElse: () => ('', 'All Types'))
                          .$2,
                  active: _selectedType.isNotEmpty,
                  color: const Color(0xFF0ea5e9),
                  items: _recordTypes.map((t) => _DropItem(t.$1, t.$2)).toList(),
                  selected: _selectedType,
                  onSelect: _setType,
                )),
                const SizedBox(width: 10),
                // ── Time dropdown ─────────────────────────────────────────
                Expanded(child: _FilterDropdown(
                  icon: Icons.calendar_month_rounded,
                  label: _datePreset == null
                      ? 'Any Time'
                      : _datePreset == 'custom' && _dateFrom != null
                          ? 'Custom range'
                          : _datePresets
                              .firstWhere((p) => p.$1 == _datePreset,
                                  orElse: () => ('', 'Any Time'))
                              .$2,
                  active: _datePreset != null,
                  color: const Color(0xFF6366f1),
                  items: [
                    const _DropItem('', 'Any Time'),
                    ..._datePresets.map((p) => _DropItem(p.$1, p.$2)),
                  ],
                  selected: _datePreset ?? '',
                  onSelect: (v) => v.isEmpty ? setState(() {
                    _datePreset = null; _dateFrom = null; _dateTo = null; _load();
                  }) : _selectPreset(v),
                )),
              ]),
            ]),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final uploaded = await context.push<bool>('/upload');
          if (uploaded == true) _load();
        },
        backgroundColor: const Color(0xFF0ea5e9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFcbd5e1)),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFF64748b))),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _records.isEmpty ? _emptyState() : _list(),
                ),
    );
  }

  Widget _emptyState() => ListView(children: [
    const SizedBox(height: 100),
    Center(child: Column(children: [
      const Icon(Icons.folder_open_rounded, size: 56, color: Color(0xFFcbd5e1)),
      const SizedBox(height: 12),
      Text(
        _hasFilters ? 'No records match your filters' : 'No records yet',
        style: const TextStyle(color: Color(0xFF64748b), fontSize: 16),
      ),
      const SizedBox(height: 4),
      Text(
        _hasFilters
            ? 'Try a different filter, date range, or search term'
            : 'Tap Upload to add your first record',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 13),
      ),
    ])),
  ]);

  Widget _list() => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
    itemCount: _records.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) => _recordCard(_records[i]),
  );

  Widget _recordCard(MedicalRecord record) => InkWell(
    onTap: () => context.push('/records/${record.id}'),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Row(children: [
        Container(width: 4, height: 52,
            decoration: BoxDecoration(
              color: record.isFlagged
                  ? const Color(0xFFef4444) : const Color(0xFF0ea5e9),
              borderRadius: BorderRadius.circular(4),
            )),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(record.title.isEmpty ? 'Untitled' : record.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1e293b))),
          const SizedBox(height: 3),
          Text(record.recordTypeDisplay,
              style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
          if ((record.recordDate ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(record.recordDate!,
                style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 11)),
          ],
        ])),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (record.isFlagged)
            const Icon(Icons.flag_rounded, color: Color(0xFFef4444), size: 16),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Color(0xFFcbd5e1), size: 20),
        ]),
      ]),
    ),
  );
}

// ── Dropdown filter helpers ───────────────────────────────────────────────────

class _DropItem {
  final String value, label;
  const _DropItem(this.value, this.label);
}

class _FilterDropdown extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     active;
  final Color    color;
  final List<_DropItem> items;
  final String   selected;
  final void Function(String) onSelect;

  const _FilterDropdown({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelect,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      color: Colors.white,
      itemBuilder: (_) => items.map((item) {
        final isSelected = item.value == selected;
        return PopupMenuItem<String>(
          value: item.value,
          height: 44,
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFFf1f5f9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.circle_outlined,
                size: 14,
                color: isSelected ? color : const Color(0xFFcbd5e1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : const Color(0xFF1e293b),
                ))),
          ]),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.08) : const Color(0xFFf1f5f9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.35) : const Color(0xFFe2e8f0),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 15, color: active ? color : const Color(0xFF94a3b8)),
          const SizedBox(width: 6),
          Expanded(child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? color : const Color(0xFF475569),
              ))),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: active ? color : const Color(0xFF94a3b8)),
        ]),
      ),
    );
  }
}
