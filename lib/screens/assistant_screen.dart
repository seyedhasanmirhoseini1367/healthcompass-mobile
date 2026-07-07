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
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  Future<void> _send() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': query});
      _loading = true;
    });
    _scrollDown();
    try {
      final res = await ApiService.ask(query, history: _messages);
      setState(() {
        _messages.add({'role': 'assistant', 'content': res['answer'] ?? ''});
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Sorry, something went wrong.'});
        _loading = false;
      });
    }
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
      ),
      body: Column(children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: Text('Ask me anything about your health records.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748b))))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length) {
                      return const Padding(padding: EdgeInsets.only(top: 8),
                          child: Center(child: SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366f1)))));
                    }
                    final m = _messages[i];
                    final isUser = m['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF0ea5e9) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: isUser ? null : Border.all(color: const Color(0xFFe2e8f0)),
                        ),
                        child: Text(m['content'] ?? '',
                            style: TextStyle(color: isUser ? Colors.white : const Color(0xFF1e293b), fontSize: 14)),
                      ),
                    );
                  },
                ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _controller,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask about your health...',
                filled: true, fillColor: const Color(0xFFf0f7ff),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _loading ? null : _send,
              icon: const Icon(Icons.send_rounded),
              color: const Color(0xFF6366f1),
              iconSize: 28,
            ),
          ]),
        ),
      ]),
    );
  }
}
