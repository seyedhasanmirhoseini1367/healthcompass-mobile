import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';
import '../core/error_handler.dart';
import '../models/ai_model.dart';
import '../widgets/error_retry_widget.dart';
import '../widgets/skeleton_loader.dart';

class AIModelsScreen extends StatefulWidget {
  const AIModelsScreen({super.key});
  @override
  State<AIModelsScreen> createState() => _AIModelsScreenState();
}

class _AIModelsScreenState extends State<AIModelsScreen> {
  List<AIModel> _models  = [];
  bool _loading = true;
  String? _error;
  String _filterCat = 'all';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.aiModels();
      setState(() { _models = data; _loading = false; });
    } catch (e) {
      setState(() { _error = friendlyError(e); _loading = false; });
    }
  }

  static const _catColors = {
    'cardiovascular': Color(0xFFef4444),
    'diabetes':       Color(0xFFf59e0b),
    'oncology':       Color(0xFF8b5cf6),
    'neurology':      Color(0xFF3b82f6),
    'general':        Color(0xFF22c55e),
    'wearable':       Color(0xFF0ea5e9),
    'other':          Color(0xFF64748b),
  };
  static const _catIcons = {
    'cardiovascular': Icons.favorite_rounded,
    'diabetes':       Icons.water_drop_rounded,
    'oncology':       Icons.biotech_rounded,
    'neurology':      Icons.psychology_rounded,
    'general':        Icons.health_and_safety_rounded,
    'wearable':       Icons.watch_rounded,
    'other':          Icons.science_rounded,
  };
  static const _catEmojis = {
    'cardiovascular': '❤️',
    'diabetes':       '🩸',
    'oncology':       '🔬',
    'neurology':      '🧠',
    'general':        '🩺',
    'wearable':       '⌚',
    'other':          '🧪',
  };

  Color    _catColor(String cat) => _catColors[cat] ?? const Color(0xFF64748b);
  IconData _catIcon(String cat)  => _catIcons[cat]  ?? Icons.science_rounded;
  String   _catEmoji(String cat) => _catEmojis[cat] ?? '🔬';

  List<AIModel> get _filtered => _filterCat == 'all'
      ? _models
      : _models.where((m) => m.category == _filterCat).toList();

  List<String> get _categories {
    final cats = _models.map((m) => m.category.isEmpty ? 'other' : m.category).toSet().toList();
    cats.sort();
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      body: _loading
          ? const SkeletonListPlaceholder()
          : _error != null
              ? ErrorRetryWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(onRefresh: _load, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    final filtered = _filtered;
    return CustomScrollView(
      slivers: [
        // ── Gradient header ─────────────────────────────────────────────────
        SliverToBoxAdapter(child: _buildHeader()),

        // ── Stats strip ─────────────────────────────────────────────────────
        if (_models.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _buildStatsStrip(),
            ),
          ),

        // ── Category filter ─────────────────────────────────────────────────
        if (_categories.length > 1)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
              child: _buildCategoryFilter(),
            ),
          ),

        // ── Section label ───────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF22c55e), Color(0xFF16a34a)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🤖', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    '${filtered.length} model${filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Divider(color: Color(0xFFe2e8f0))),
            ]),
          ),
        ),

        // ── Model cards ─────────────────────────────────────────────────────
        if (filtered.isEmpty)
          SliverFillRemaining(child: _buildEmpty())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ModelCard(model: filtered[i],
                      catColor: _catColor(filtered[i].category.isEmpty ? 'other' : filtered[i].category),
                      catIcon: _catIcon(filtered[i].category.isEmpty ? 'other' : filtered[i].category),
                      catEmoji: _catEmoji(filtered[i].category.isEmpty ? 'other' : filtered[i].category)),
                ),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16a34a), Color(0xFF22c55e), Color(0xFF0ea5e9)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: i == 2 ? 0.6 : 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ))),
            const SizedBox(height: 16),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('🤖', style: TextStyle(fontSize: 26)),
              SizedBox(width: 10),
              Text(
                'AI Models',
                style: TextStyle(
                  color: Colors.white, fontSize: 24,
                  fontWeight: FontWeight.w900, letterSpacing: -0.5,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              'Browse and run specialist clinical AI models',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatsStrip() {
    final cats = _categories;
    final inputTypes = _models.map((m) => m.inputType).toSet();
    return Row(children: [
      _StatChip(value: '${_models.length}', label: 'Models',     color: const Color(0xFF22c55e)),
      const SizedBox(width: 10),
      _StatChip(value: '${cats.length}',    label: 'Categories', color: const Color(0xFF6366f1)),
      const SizedBox(width: 10),
      _StatChip(value: '${inputTypes.length}', label: 'Input types', color: const Color(0xFF0ea5e9)),
    ]);
  }

  Widget _buildCategoryFilter() {
    final cats = ['all', ..._categories];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: cats.map((cat) {
          final selected = _filterCat == cat;
          final color = cat == 'all' ? const Color(0xFF22c55e) : _catColor(cat);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterCat = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? color : const Color(0xFFe2e8f0)),
                ),
                child: Text(
                  cat == 'all' ? 'All' : cat[0].toUpperCase() + cat.substring(1),
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('🤖', style: TextStyle(fontSize: 52)),
    const SizedBox(height: 16),
    const Text('No AI models available', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF475569))),
    const SizedBox(height: 8),
    const Text('Models approved by admin\nwill appear here.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF94a3b8), fontSize: 13, height: 1.5)),
  ]));
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color  color;
  const _StatChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe2e8f0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, height: 1)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94a3b8), fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Model card ────────────────────────────────────────────────────────────────

class _ModelCard extends StatelessWidget {
  final AIModel  model;
  final Color    catColor;
  final IconData catIcon;
  final String   catEmoji;

  const _ModelCard({
    required this.model,
    required this.catColor,
    required this.catIcon,
    required this.catEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final name     = model.name;
    final catLabel = model.categoryDisplay;
    final desc     = model.description;
    final runs     = model.runCount;
    final inputType = model.inputType;
    final inputLabel = model.inputTypeDisplay.isEmpty ? inputType : model.inputTypeDisplay;
    final slug     = model.slug;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Coloured accent bar ──────────────────────────────────────────────
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: catColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18)),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Header row ───────────────────────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(catEmoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1e293b))),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(catLabel, style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ])),
              // Runs badge
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf1f5f9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$runs runs', style: const TextStyle(color: Color(0xFF64748b), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
            ]),

            // ── Description ──────────────────────────────────────────────────
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5)),
            ],

            const SizedBox(height: 14),

            // ── Footer row ───────────────────────────────────────────────────
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFf8fafc),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFe2e8f0)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_inputIcon(inputType), size: 12, color: const Color(0xFF64748b)),
                  const SizedBox(width: 4),
                  Text(inputLabel, style: const TextStyle(color: Color(0xFF64748b), fontSize: 11, fontWeight: FontWeight.w500)),
                ]),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/ai-models/$slug/run'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [catColor, catColor.withValues(alpha: 0.8)]),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [BoxShadow(color: catColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 15),
                    const SizedBox(width: 5),
                    Text(
                      inputType == 'tabular' ? 'Run Now' : 'View Details',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  IconData _inputIcon(String type) => switch (type) {
    'tabular' => Icons.table_chart_rounded,
    'image'   => Icons.image_rounded,
    'eeg'     => Icons.ssid_chart_rounded,
    _         => Icons.data_object_rounded,
  };
}
