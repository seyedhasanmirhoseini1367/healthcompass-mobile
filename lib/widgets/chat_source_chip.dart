import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/chat_event.dart';

/// A tappable citation chip shown under an assistant chat bubble for each
/// [SourceRef] the reply cited. Personal-record sources navigate to the
/// record detail screen; general/article sources are not tappable.
class SourceChip extends StatelessWidget {
  final SourceRef source;
  const SourceChip({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (source.isGeneral) {
      if (source.sourceName != null && source.sourceName!.isNotEmpty) parts.add(source.sourceName!);
      if (source.topic != null && source.topic!.isNotEmpty) parts.add(source.topic!);
    } else {
      if (source.documentType != null && source.documentType!.isNotEmpty) parts.add(source.documentType!);
      if (source.recordDate != null && source.recordDate!.isNotEmpty) parts.add(source.recordDate!);
    }
    final subtitle = parts.join(' · ');
    final tappable  = !source.isGeneral && (source.recordId?.isNotEmpty ?? false);

    return InkWell(
      onTap: tappable ? () => context.push('/records/${source.recordId}') : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFf0f4ff),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFe0e7ff)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            source.isGeneral ? Icons.public_rounded : Icons.description_rounded,
            size: 13, color: const Color(0xFF6366f1),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(source.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4338ca))),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748b))),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
