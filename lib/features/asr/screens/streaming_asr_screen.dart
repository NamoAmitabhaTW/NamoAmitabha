// features/asr/screens/streaming_asr_screen.dart
import 'dart:async';

import 'package:amitabha/features/asr/application/asr_session_controller.dart';
import 'package:amitabha/features/asr/widgets/chanting_background.dart';
import 'package:amitabha/features/asr/widgets/liuli_button.dart';
import 'package:amitabha/features/background/background_controller.dart';
import 'package:amitabha/features/model_install/install_progress_model.dart';
import 'package:amitabha/features/model_install/model_install_flow.dart';
import 'package:amitabha/features/model_install/model_installer.dart';
import 'package:amitabha/features/model_install/widgets/download_progress_dialog.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class StreamingAsrScreen extends StatelessWidget {
  const StreamingAsrScreen({super.key});

  /// 「開始」按下後的前置流程:模型就緒 → 麥克風權限 → 開始錄音。
  /// 模型安裝的對話框在 ModelInstallFlow 內;這裡只處理權限引導。
  Future<void> _handleStart(BuildContext context) async {
    final asr = context.read<AsrSessionController>();

    // 安裝已在進行中 → 重新開啟進度對話框即可(射後不理,對話框自行收合)
    final progressModel = context.read<InstallProgressModel>();
    if (progressModel.isBusy) {
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const DownloadProgressDialog(),
        ),
      );
      return;
    }

    // 模型缺件 → 走安裝流程;安裝完成後由使用者再按一次「開始」
    final installer = ModelInstaller();
    if (await installer.status(kAsrModelName) != InstallStatus.ready) {
      if (!context.mounted) return;
      await ModelInstallFlow(
        installer: installer,
      ).ensureReady(context, kAsrModelName);
      return;
    }

    // 先觸發系統原生權限(第一次會跳 iOS/Android 原生彈窗);
    // 沒拿到就引導使用者去設定頁
    final granted = await asr.hasMicPermission();
    if (!granted) {
      if (!context.mounted) return;
      await _showOpenSettingsDialog(context);
      return;
    }

    await asr.start();
  }

  Future<void> _showOpenSettingsDialog(BuildContext context) async {
    final t = AppLocalizations.of(context);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.micPermissionTitle),
        content: Text(t.micPermissionRationale),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await openAppSettings(); // 由 permission_handler 提供
            },
            child: Text(t.openSettings),
          ),
        ],
      ),
    );
  }

  /// 依語系挑選「阿彌陀佛」書法圖。
  ///  zh → 中文書法
  ///  ja → 日文
  ///  vi → 越南文
  ///  en/de/fr → 梵文/羅馬化版 (_sa)
  ///  其餘(含 ko)→ 退回中文書法
  static String _calligraphyAsset(String lang) {
    switch (lang) {
      case 'ja':
        return 'assets/images/amitabha_calligraphy_ja.png';
      case 'ko':
        return 'assets/images/amitabha_calligraphy_ko.png';
      case 'vi':
        return 'assets/images/amitabha_calligraphy_vi.png';
      case 'en':
      case 'de':
      case 'fr':
        return 'assets/images/amitabha_calligraphy_sa.png';
      case 'zh':
      default:
        return 'assets/images/amitabha_calligraphy.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = context.watch<AsrSessionController>();
    final bg = context.watch<BackgroundController>();
    final lang = Localizations.localeOf(context).languageCode;

    // 拿底部導航的字型做為基礎
    final navLabelBase =
        NavigationBarTheme.of(context).labelTextStyle?.resolve(const {}) ??
        Theme.of(context).textTheme.labelMedium ??
        const TextStyle();

    // 計數字樣式：放大、粗一點、沿用底部導航字型
    final countStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
      fontFamily: navLabelBase.fontFamily,
      fontWeight: FontWeight.w600,
      height: 1.05,
      letterSpacing: navLabelBase.letterSpacing,
    );

    // 顏色：數字用主色，單位用 onSurface 降不透明
    final numberColor = Colors.white;
    final unitColor = Colors.white;

    // 取得系統可視安全區（特別是底部手勢列的高度）
    final viewPadding = MediaQuery.of(context).viewPadding;
    // ===== 以 FocusTraversalGroup 包住，提供穩定焦點導覽 =====
    return FocusTraversalGroup(
      child: Stack(
        children: [
          // ① 滿版背景（影片或圖片）— 不受安全區內縮，墊到螢幕最底
          Positioned.fill(
            child: ChantingBackground(source: bg.currentSource, active: true),
            // ↑ 之後接設定頁時，改成 type: s.backgroundType 即可
          ),

          // ② 前景內容 — 只保留底部安全區
          Padding(
            padding: EdgeInsets.only(bottom: viewPadding.bottom + 120),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Spacer(flex: 4),
                  Image.asset(
                    _calligraphyAsset(lang),
                    width: MediaQuery.of(context).size.width * 0.8,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 320),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          // 數字:沿用 countStyle 的 w600,不再覆寫
                          TextSpan(
                            text: '${s.sessionCount} ',
                            style: countStyle?.copyWith(
                              color: numberColor,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          // 單位「次」:較輕(w400)、較小(約 0.62 倍),退一步
                          TextSpan(
                            text: t.times,
                            style: countStyle?.copyWith(
                              color: unitColor,
                              fontWeight: FontWeight.w400,
                              fontSize: (countStyle.fontSize ?? 57.0) * 0.62,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 10),
                  Row(
                    children: [
                      Expanded(
                        child: LiuliButton(
                          onPressed: () {
                            if (s.isRecording) {
                              s.stop();
                            } else {
                              _handleStart(context);
                            }
                          },
                          icon: s.isRecording ? Icons.pause : Icons.play_arrow,
                          label: s.isRecording ? t.pause : t.start,
                          gradientColors: [
                            Colors.white.withValues(
                              alpha: 0.22,
                            ), // 上緣：極淡白，像玻璃反光
                            Colors.white.withValues(alpha: 0.10), // 下緣：更透
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: LiuliButton(
                          onPressed: s.sessionCount > 0 ? s.save : null,
                          icon: Icons.save,
                          label: t.save,
                          gradientColors: [
                            Colors.white.withValues(
                              alpha: 0.22,
                            ), // 上緣：極淡白，像玻璃反光
                            Colors.white.withValues(alpha: 0.10), // 下緣：更透
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
