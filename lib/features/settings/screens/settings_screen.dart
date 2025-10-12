//amitabha/lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:amitabha/core/localization/locale_controller.dart';
import 'package:amitabha/features/auth/application/delete_account_runner.dart';
/* import 'package:amitabha/features/auth/application/auth_facade.dart';
import 'package:amitabha/features/auth/data/firebase_auth_repository.dart';
import 'package:amitabha/features/auth/data/firestore_user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:amitabha/core/ui/busy_dialog.dart';
import 'package:amitabha/core/firebase_bootstrap.dart'; */
import 'package:url_launcher/url_launcher_string.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return ListView(
      children: [
        const SizedBox(height: 8),

        //_AccountTile(),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(t.language),
          subtitle: Text(_languageLabel(context)),
          onTap: () => _chooseLanguage(context),
        ),
        ListTile(
          leading: const Icon(Icons.feedback_outlined),
          title: Text(t.feedback),
          onTap: () => _sendFeedbackEmail(context),
        ),

        /* const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(t.deleteAccount),
          onTap: () => _onDeleteAccount(context),
        ), */
      ],
    );
  }

  String _languageLabel(BuildContext context) {
    final l = Localizations.localeOf(context);
    if (l.languageCode == 'zh' &&
        (l.countryCode == 'TW' || l.scriptCode == 'Hant')) {
      return '繁體中文';
    }
    return 'English';
  }

  void _chooseLanguage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('繁體中文'),
              onTap: () {
                context
                    .read<LocaleController>()
                    .useTraditionalChinese(); // zh-TW 或 zh-Hant
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('English'),
              onTap: () {
                context.read<LocaleController>().useEnglish();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onDeleteAccount(BuildContext context) async {
    final t = AppLocalizations.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.confirm),
        content: Text(t.confirmDeleteAccount),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.deleteAccount),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // UI：loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String? error;
    try {
      await DeleteAccountRunner.run();
    } catch (e) {
      error = e.toString();
    } finally {
      if (context.mounted) Navigator.pop(context); // 關 loading
    }

    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('刪除失敗：$error')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.done)));
    }
  }

  void _sendFeedbackEmail(BuildContext context) {
    // 你可以換成自己的收件者
    final to = 'namoamitabha1995@gmail.com';
    final subject = Uri.encodeComponent('[念佛App] 意見回饋');
    final body = Uri.encodeComponent('描述問題/建議：\n\n裝置與系統版本：\nApp 版本：\n(可附上截圖)');
    final uri = 'mailto:$to?subject=$subject&body=$body';
    launchUrlString(uri);
  }
}

/* class _AccountTile extends StatefulWidget {
  const _AccountTile();
  @override
  State<_AccountTile> createState() => _AccountTileState();
} */

/* class _AccountTileState extends State<_AccountTile> {
  AuthFacade? _facade;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // A. 未初始化 → 只顯示按鈕
    if (!FirebaseBootstrap.isReady) {
      return ListTile(
        leading: const Icon(Icons.person),
        title: Text(t.account),
        subtitle: Text(t.statusSignedOut),
        trailing: FilledButton.icon(
          icon: const Icon(Icons.cloud_upload),
          label: Text(t.enableCloudSync),
          onPressed: () async {
            showBusyDialog(context, t.enableCloudSync, 'Initializing cloud…');
            var toast = ''; 
            try {
              toast = t.done; 
              await FirebaseBootstrap.ensureReady();
              setState(() {
                _facade = AuthFacade(
                  // ← 初始化完成後才 new
                  auth: FirebaseAuthRepository(),
                  users: FirestoreUserRepository(),
                );
              });
              // （可選）匿名登入
              // await FirebaseBootstrap.ensureAnonymousSignedIn();
              toast = t.done;
            } catch (e) {
              toast = '初始化失敗：$e';
            } finally {
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(toast)));
              }
            }
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(toast)));
            }
          },
        ),
      );
    }

    // B. 已初始化 → 確保 facade 存在
    _facade ??= AuthFacade(
      auth: FirebaseAuthRepository(),
      users: FirestoreUserRepository(),
    );

    return StreamBuilder<fb.User?>(
      stream: _facade!.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        final isSignedIn = user != null && !user.isAnonymous;
        final status = isSignedIn ? t.statusSignedIn : t.statusSignedOut;
        final email = (user?.email ?? '').trim();
        final subtitle = email.isNotEmpty ? '$status\n$email' : status;

        final trailing = isSignedIn
            ? OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(t.logOut),
                onPressed: () async {
                  await _facade!.signOut();
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(t.done)));
                  }
                },
              )
            : FilledButton.icon(
                icon: const Icon(Icons.login),
                label: Text(t.logIn),
                onPressed: () async {
                  await showBusyDialog(context, t.logIn, 'Signing in…');
                  String? toast;
                  try {
                    final cred = await _facade!.signInWithGoogle();
                    final who = cred.user?.email ?? cred.user?.uid ?? '';
                    toast = '已登入：$who';
                  } catch (e) {
                    toast = '登入失敗：$e';
                  } finally {
                    if (mounted) Navigator.pop(context);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(toast)));
                  }
                },
              );

        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(t.account),
          subtitle: Text(subtitle),
          isThreeLine: subtitle.contains('\n'),
          trailing: trailing,
        );
      },
    );
  }
} */
