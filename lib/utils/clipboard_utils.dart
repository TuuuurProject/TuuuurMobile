import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool _isMounted(BuildContext context) {
  return context is Element && (context as Element).mounted;
}

Future<void> copyToClipboard(
  BuildContext context,
  String text, {
  String? snackMessage,
  Color? snackColor,
}) async {
  await Clipboard.setData(ClipboardData(text: text));

  if (!_isMounted(context)) return;
  if (snackMessage != null && snackMessage.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(snackMessage), backgroundColor: snackColor),
    );
  }
}
