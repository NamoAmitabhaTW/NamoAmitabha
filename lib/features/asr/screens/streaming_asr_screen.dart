// features/asr/screens/streaming_asr_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amitabha/app/app_state.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:amitabha/features/asr/widgets/chanting_background.dart';
import 'package:amitabha/features/asr/widgets/liuli_button.dart';
import 'package:amitabha/features/background/background_controller.dart';

class StreamingAsrScreen extends StatelessWidget {
  const StreamingAsrScreen({super.key});

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
    final s = context.watch<AppState>();
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
                              s.stopAsr?.call();
                            } else {
                              s.startAsr?.call();
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
                          onPressed: s.sessionCount > 0 ? s.saveAsr : null,
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
