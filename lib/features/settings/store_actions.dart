import 'dart:io' show Platform;

import 'package:amitabha/core/config/store_links.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';

class StoreActions {
  StoreActions._();

  static final InAppReview _review = InAppReview.instance;

  static Future<void> rate(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final t = AppLocalizations.of(context);
    try {
      await _review.openStoreListing(
        appStoreId: StoreLinks.hasIosAppStoreId ? StoreLinks.iosAppStoreId : null,
      );
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(t.storeActionFailed)),
      );
    }
  }

  static Future<void> share(BuildContext context) async {
    final t = AppLocalizations.of(context);

    final message = _buildShareText(t);

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    await Share.share(
      message,
      subject: t.shareSubject,
      sharePositionOrigin: origin,
    );
  }

  static String _buildShareText(AppLocalizations t) {
    final buffer = StringBuffer()
      ..writeln(t.shareMessage)
      ..writeln()
      ..writeln('Android：')
      ..writeln(StoreLinks.androidStoreUrl)
      ..writeln()
      ..writeln('iOS：')
      ..writeln(StoreLinks.iosStoreUrl)
      ..writeln()
      ..writeln('Meta：')
      ..write(StoreLinks.metaStoreUrl);
    return buffer.toString();
  }
}

bool get isRateSupported => Platform.isAndroid || Platform.isIOS;
