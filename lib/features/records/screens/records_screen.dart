// lib/features/records/screens/records_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:characters/characters.dart';

import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:amitabha/storage/app_paths.dart';
import 'package:amitabha/storage/atomic_io.dart';
import 'package:amitabha/storage/models.dart';

import 'package:provider/provider.dart'; 
import 'package:amitabha/app/application/app_state.dart'; 


class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final df = DateFormat.yMd(locale);

    // ★ 監聽 AppState.dataVersion，只要版本變了就讓 FutureBuilder 重新建立
    final ver = context.select<AppState, int>((s) => s.dataVersion);
    final isVertical = _isTraditionalChinese(context);

    return FutureBuilder<_DailyLoadResult>(
      key: ValueKey(ver),       // ★ 以版本號當 key，強制刷新
      future: _loadAllDaily(),   // 會重新 hit 檔案系統，拿到最新 daily JSON
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        final header = _HeaderCards(
          totalText: '${data.total}',
          practiceDaysText: '${data.practiceDays}',
          verticalTitle: t.amitabha,
          isVertical: isVertical, 
          t: t,
        );

        if (data.items.isEmpty) {
          return ListView(
            children: [
              header,
              const Divider(height: 0),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(t.noRecords)),
              ),
            ],
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: header),
            const SliverToBoxAdapter(child: Divider(height: 0)),
            SliverList.builder(
              itemCount: data.items.length,
              itemBuilder: (_, i) {
                final r = data.items[i];

                // yyyymmdd -> DateTime
                final y = int.parse(r.yyyymmdd.substring(0, 4));
                final m = int.parse(r.yyyymmdd.substring(4, 6));
                final d = int.parse(r.yyyymmdd.substring(6, 8));
                final dt = DateTime(y, m, d);

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const Icon(Icons.calendar_month, size: 24),
                  title: Text(
                    df.format(dt), // ← 使用轉出的日期
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: Text(
                    '${r.amitabhaCount} ${t.times}', // ← 使用正確欄位
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/* ----------------- 小工具：讀取每日 JSON ----------------- */

class _DailyLoadResult {
  final List<DailySummary> items; // 依日期新→舊排序
  final int total;
  final int practiceDays;
  _DailyLoadResult(this.items, this.total, this.practiceDays);
}

Future<_DailyLoadResult> _loadAllDaily() async {
  final root = await AppPaths.dataRoot();
  final dir = Directory(p.join(root.path, 'daily'));
  if (!await dir.exists()) {
    return _DailyLoadResult(const [], 0, 0);
  }

  final files = await dir
      .list()
      .where((e) => e is File && e.path.endsWith('.json'))
      .cast<File>()
      .toList();

  final items = <DailySummary>[];
  for (final f in files) {
    final j = await readJsonOrEmpty(f);
    if (j.isEmpty) continue;
    try {
      items.add(DailySummary.fromJson(j));
    } catch (_) {
      // 忽略壞檔
    }
  }

  // 依日期新→舊排序
  items.sort((a, b) => b.yyyymmdd.compareTo(a.yyyymmdd));

  final total = items.fold<int>(0, (s, e) => s + e.amitabhaCount);
  final practiceDays = items.where((e) => e.amitabhaCount > 0).length;

  return _DailyLoadResult(items, total, practiceDays);
}

/* ----------------- UI 子元件 ----------------- */

class _HeaderCards extends StatelessWidget {
  final String totalText;
  final String practiceDaysText;
  final String verticalTitle;
  final bool isVertical;   
  final AppLocalizations t;

  const _HeaderCards({
    required this.totalText,
    required this.practiceDaysText,
    required this.verticalTitle,
    required this.t,
    this.isVertical = true, 
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCol(
                  topLabel: t.total,
                  valueText: totalText,
                  unitText: t.times,
                ),
              ),
              const _VDivider(),
              Expanded(child: _VerticalTitle(title: verticalTitle, vertical: isVertical)),
              const _VDivider(),
              Expanded(
                child: _StatCol(
                  topLabel: t.chant,
                  valueText: practiceDaysText,
                  unitText: t.days,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String topLabel;
  final String valueText;
  final String unitText;

  const _StatCol({
    required this.topLabel,
    required this.valueText,
    required this.unitText,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);
    final unit = Theme.of(context).textTheme.titleMedium;
    final numTx = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.0,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(topLabel, style: title, textAlign: TextAlign.center),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(valueText, style: numTx, textAlign: TextAlign.center),
              ),
            ),
          ),
          Text(unitText, style: unit, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _VerticalTitle extends StatelessWidget {
  final String title;
  final bool vertical; // zh-Hant 直排；其他橫排
  const _VerticalTitle({required this.title, this.vertical = true});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge;

    if (vertical) {
      // 直排：逐字換行
      final chars = title.characters.toList();
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in chars)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(c, style: style),
              ),
          ],
        ),
      );
    }

    // 橫排（英文）：單行 + FittedBox 縮放不超框 + 省略號保護
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown, // 文字太寬會自動縮小
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).dividerColor.withOpacity(0.6);
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: color,
    );
  }
}

bool _isTraditionalChinese(BuildContext context) {
  final l = Localizations.localeOf(context);
  return l.languageCode == 'zh' &&
      (l.scriptCode == 'Hant' ||
       l.countryCode == 'TW' ||
       l.countryCode == 'HK' ||
       l.countryCode == 'MO');
}