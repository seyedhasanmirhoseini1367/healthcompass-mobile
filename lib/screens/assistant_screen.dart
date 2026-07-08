import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scroll     = ScrollController();

  // Current session
  String? _sessionId;
  String  _sessionTitle = 'New Chat';

  // Messages displayed in the current session
  final List<Map<String, dynamic>> _messages = [];
  bool _sending = false;

  // Sessions sidebar
  List<Map<String, dynamic>> _sessions    = [];
  bool _sessionsLoading = false;

  @override
  void initState() { super.initState(); _loadSessions(); }

  // ── Sessions API ───────────────────────────────────────────────────────────

  Future<void> _loadSessions() async {
    setState(() => _sessionsLoading = true);
    try {
      final data = await ApiService.chatSessions();
      setState(() {
        _sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
        _sessionsLoading = false;
      });
    } catch (_) {
      setState(() => _sessionsLoading = false);
    }
  }

  Future<void> _openSession(String id, String title) async {
    setState(() { _sending = true; });
    try {
      final data = await ApiService.chatSessionDetail(id);
      final msgs = data['messages'] as List? ?? [];
      setState(() {
        _sessionId    = id;
        _sessionTitle = title;
        _messages.clear();
        for (final m in msgs) {
          _messages.add({'role': 'user',      'content': m['query'],    'time': m['created_at']});
          _messages.add({'role': 'assistant', 'content': m['response'], 'time': m['created_at']});
        }
        _sending = false;
      });
      _scrollDown();
    } catch (_) {
      setState(() => _sending = false);
    }
  }

  void _newChat() => setState(() {
    _sessionId    = null;
    _sessionTitle = 'New Chat';
    _messages.clear();
  });

  Future<void> _deleteSession(String id) async {
    try {
      await ApiService.deleteChatSession(id);
      if (_sessionId == id) _newChat();
      await _loadSessions();
    } catch (_) {}
  }

  // ── Send message ───────────────────────────────────────────────────────────

  Future<void> _send() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': query});
      _sending = true;
    });
    _scrollDown();
    try {
      final res = await ApiService.ask(query, sessionId: _sessionId);
      final sid = res['session_id']?.toString();
      setState(() {
        _messages.add({'role': 'assistant', 'content': res['answer'] ?? ''});
        _sending = false;
        if (sid != null) {
          _sessionId = sid;
          if (_sessionTitle == 'New Chat') {
            _sessionTitle = query.length > 50 ? '${query.substring(0, 50)}…' : query;
          }
        }
      });
      _loadSessions();
    } catch (_) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Sorry, something went wrong. Please try again.'});
        _sending = false;
      });
    }
    _scrollDown();
  }

  void _scrollDown() => Future.delayed(const Duration(milliseconds: 120), () {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  });

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          if (_sessionTitle != 'New Chat')
            Text(_sessionTitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748b), fontWeight: FontWeight.w400),
                maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          // New chat
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New chat',
            onPressed: _newChat,
          ),
          // History
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Chat history',
                onPressed: _showHistorySheet,
              ),
              if (_sessions.isNotEmpty)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366f1), shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(children: [
        // ── Chat gradient header bar ──────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0ea5e9), Color(0xFF6366f1)],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Text('🧠', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _sessionId != null
                  ? _sessionTitle
                  : 'Ask me anything about your health records',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            if (_sessionId != null)
              GestureDetector(
                onTap: _newChat,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('+ New', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ),

        // ── Messages ─────────────────────────────────────────────────────
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length) return _buildTypingIndicator();
                    final m      = _messages[i];
                    final isUser = m['role'] == 'user';
                    return _MessageBubble(content: m['content'] ?? '', isUser: isUser);
                  },
                ),
        ),

        // ── Input ─────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(16, 10, 8,
              MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom
                  : 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _send(),
                maxLines: null,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Ask about your health…',
                  hintStyle: const TextStyle(color: Color(0xFF94a3b8)),
                  filled: true,
                  fillColor: const Color(0xFFf0f7ff),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _sending ? const Color(0xFFe2e8f0) : const Color(0xFF6366f1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sending ? null : _send,
                icon: Icon(_sending ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── History bottom sheet ───────────────────────────────────────────────────

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistorySheet(
        sessions:         _sessions,
        loading:          _sessionsLoading,
        currentSessionId: _sessionId,
        onRefresh:        _loadSessions,
        onNewChat:        () { Navigator.pop(context); _newChat(); },
        onSelectSession:  (id, title) { Navigator.pop(context); _openSession(id, title); },
        onDelete:         (id) async { await _deleteSession(id); },
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0ea5e9), Color(0xFF6366f1)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Center(child: Text('🧠', style: TextStyle(fontSize: 36))),
        ),
        const SizedBox(height: 20),
        const Text('AI Health Assistant',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1e293b))),
        const SizedBox(height: 8),
        const Text('Ask me anything about your health records, medications, or lab results.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748b), fontSize: 13, height: 1.6)),
        const SizedBox(height: 28),
        // Suggestion chips
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          _SuggestionChip('Summarise my records', Icons.summarize_rounded, () {
            _controller.text = 'Summarise my recent medical records';
            _send();
          }),
          _SuggestionChip('Latest lab results', Icons.science_rounded, () {
            _controller.text = 'What are my latest lab results?';
            _send();
          }),
          _SuggestionChip('My medications', Icons.medication_rounded, () {
            _controller.text = 'What medications am I on?';
            _send();
          }),
        ]),
      ]),
    ),
  );

  Widget _SuggestionChip(String label, IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFe2e8f0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: const Color(0xFF6366f1)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
      ]),
    ),
  );

  Widget _buildTypingIndicator() => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0ea5e9), Color(0xFF6366f1)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('🧠', style: TextStyle(fontSize: 16))),
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFe2e8f0)),
        ),
        child: const _TypingDots(),
      ),
    ]),
  );
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool   isUser;
  const _MessageBubble({required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0ea5e9), Color(0xFF6366f1)]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(child: Text('🧠', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .75),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF6366f1) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(16),
                  topRight:    const Radius.circular(16),
                  bottomLeft:  Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4  : 16),
                ),
                border: isUser ? null : Border.all(color: const Color(0xFFe2e8f0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(content,
                  style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF1e293b),
                    fontSize: 14, height: 1.5,
                  )),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF6366f1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(child: Icon(Icons.person_rounded, size: 18, color: Color(0xFF6366f1))),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Animated typing dots ──────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
          final opacity = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
          final scale   = 0.6 + opacity * 0.4;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: Color.lerp(const Color(0xFFcbd5e1), const Color(0xFF6366f1), opacity),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }));
      },
    );
  }
}

// ── History bottom sheet ──────────────────────────────────────────────────────

class _HistorySheet extends StatefulWidget {
  final List<Map<String, dynamic>> sessions;
  final bool   loading;
  final String? currentSessionId;
  final VoidCallback onRefresh;
  final VoidCallback onNewChat;
  final void Function(String id, String title) onSelectSession;
  final void Function(String id) onDelete;

  const _HistorySheet({
    required this.sessions,
    required this.loading,
    required this.currentSessionId,
    required this.onRefresh,
    required this.onNewChat,
    required this.onSelectSession,
    required this.onDelete,
  });

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  late List<Map<String, dynamic>> _local;

  @override
  void initState() {
    super.initState();
    _local = List.from(widget.sessions);
  }

  @override
  void didUpdateWidget(_HistorySheet old) {
    super.didUpdateWidget(old);
    if (old.sessions != widget.sessions) {
      setState(() => _local = List.from(widget.sessions));
    }
  }

  Future<void> _delete(String id) async {
    setState(() => _local.removeWhere((s) => s['id']?.toString() == id));
    await widget.onDelete(id);
  }

  Future<void> _rename(String id, String currentTitle) async {
    final ctrl = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Rename chat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 120,
          decoration: InputDecoration(
            hintText: 'Chat title',
            filled: true,
            fillColor: const Color(0xFFf0f7ff),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94a3b8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366f1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTitle == null || newTitle.isEmpty || newTitle == currentTitle) return;
    setState(() {
      final idx = _local.indexWhere((s) => s['id']?.toString() == id);
      if (idx >= 0) _local[idx] = {..._local[idx], 'title': newTitle};
    });
    try { await ApiService.renameChatSession(id, newTitle); } catch (_) {}
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt   = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7)  return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFe2e8f0), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
            child: Row(children: [
              const Icon(Icons.history_rounded, color: Color(0xFF6366f1), size: 22),
              const SizedBox(width: 10),
              const Text('Chat History',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1e293b))),
              const Spacer(),
              TextButton.icon(
                onPressed: widget.onNewChat,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New chat'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366f1)),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFf1f5f9)),

          // List
          Expanded(
            child: widget.loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)))
                : _local.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFFcbd5e1)),
                        const SizedBox(height: 12),
                        const Text('No past conversations',
                            style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('Start a new chat to begin.',
                            style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 12)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: widget.onNewChat,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('New Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366f1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ]))
                    : RefreshIndicator(
                        onRefresh: () async => widget.onRefresh(),
                        child: ListView.builder(
                          controller: scroll,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                          itemCount: _local.length,
                          itemBuilder: (_, i) {
                            final s         = _local[i];
                            final id        = s['id']?.toString() ?? '';
                            final title     = s['title']?.toString() ?? 'Chat';
                            final count     = (s['message_count'] ?? 0) as int;
                            final updated   = _formatDate(s['updated_at']?.toString());
                            final isCurrent = id == widget.currentSessionId;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isCurrent ? const Color(0xFFf0f4ff) : const Color(0xFFf8fafc),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCurrent ? const Color(0xFF6366f1) : const Color(0xFFe2e8f0),
                                  width: isCurrent ? 1.5 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => widget.onSelectSession(id, title),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                                  child: Row(children: [
                                    // Icon
                                    Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? const Color(0xFF6366f1).withValues(alpha: 0.12)
                                            : const Color(0xFFf1f5f9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(child: Icon(Icons.chat_bubble_rounded,
                                          size: 17,
                                          color: isCurrent ? const Color(0xFF6366f1) : const Color(0xFF94a3b8))),
                                    ),
                                    const SizedBox(width: 12),
                                    // Text
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title,
                                            style: TextStyle(
                                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                                              fontSize: 13,
                                              color: isCurrent ? const Color(0xFF4338ca) : const Color(0xFF1e293b),
                                            ),
                                            maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${count == 1 ? "1 message" : "$count messages"} · $updated',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
                                        ),
                                      ],
                                    )),
                                    // Action buttons
                                    Row(mainAxisSize: MainAxisSize.min, children: [
                                      // Rename
                                      _IconBtn(
                                        icon: Icons.edit_rounded,
                                        color: const Color(0xFF6366f1),
                                        tooltip: 'Rename',
                                        onTap: () => _rename(id, title),
                                      ),
                                      const SizedBox(width: 2),
                                      // Delete
                                      _IconBtn(
                                        icon: Icons.delete_rounded,
                                        color: const Color(0xFFef4444),
                                        tooltip: 'Delete',
                                        onTap: () => _confirmDelete(id, title),
                                      ),
                                    ]),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(String id, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete chat?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
          'This will permanently delete "$title" and all its messages.',
          style: const TextStyle(color: Color(0xFF64748b)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94a3b8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _delete(id);
  }
}

// Small icon action button used inside history rows
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   tooltip;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    ),
  );
}
