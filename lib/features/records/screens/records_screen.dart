// features/records/screens/records_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:amitabha/app/application/app_state.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:characters/characters.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final df = DateFormat.yMd(locale); // 依使用者語系顯示日期

    return Consumer<AppState>(
      builder: (_, s, __) {
        // 上方固定三列
        // --- header（三欄卡片）---
        final header = Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatCol(
                      topLabel: t.total,
                      valueText: '${s.totalCount}',
                      unitText: t.times,
                    ),
                  ),
                  const _VDivider(),
                  Expanded(child: _VerticalTitle(title: t.amitabha)),
                  const _VDivider(),
                  Expanded(
                    child: _StatCol(
                      topLabel: t.chant,
                      valueText: '${s.practiceDays}',
                      unitText: t.days,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // 空清單
        if (s.records.isEmpty) {
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

        // 下方每日清單：2025/09/08  108 次
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: header),
            const SliverToBoxAdapter(child: Divider(height: 0)),
            SliverList.builder(
              itemCount: s.records.length,
              itemBuilder: (_, i) {
                final r = s.records[i];
                return ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: Text('${df.format(r.date)}'),
                  trailing: Text('${r.count} ${t.times}'),
                );
              },
            ),
          ],
        );
      },
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
    final title = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);
    final unit = Theme.of(context).textTheme.titleMedium;
    final numTx = Theme.of(context).textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // ← 三欄都置中
        children: [
          Text(topLabel, style: title, textAlign: TextAlign.center),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  valueText,
                  style: numTx,
                  textAlign: TextAlign.center,
                ),
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
  const _VerticalTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge;
    final chars = title.characters.toList(); // 逐字直排

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
