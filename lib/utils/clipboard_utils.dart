import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> copyToClipboard(
  BuildContext context,
  String text, {
  String? snackMessage,
  Color? snackColor,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  await Clipboard.setData(ClipboardData(text: text));

  if (snackMessage != null && snackMessage.isNotEmpty) {
    messenger.showSnackBar(
      SnackBar(content: Text(snackMessage), backgroundColor: snackColor),
    );
  }
}
