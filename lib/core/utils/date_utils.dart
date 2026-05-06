import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

String timeAgo(BuildContext context, DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return context.tr('justNow');
  if (diff.inMinutes == 1) return context.tr('minuteAgo');
  if (diff.inHours < 1) return '${diff.inMinutes} ${context.tr('minutesAgo')}';
  if (diff.inHours == 1) return '1 ${context.tr('hoursAgo')}';
  if (diff.inDays < 1) return '${diff.inHours} ${context.tr('hoursAgo')}';
  if (diff.inDays == 1) return context.tr('justNow'); // "Yesterday" fallback
  return '${diff.inDays}d ago';
}
