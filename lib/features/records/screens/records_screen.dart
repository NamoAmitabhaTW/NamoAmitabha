// lib/features/records/screens/records_screen.dart
import 'dart:io';
import 'package:amitabha/core/assets/app_assets.dart';
import 'package:amitabha/core/layout/layout_scale.dart';
import 'package:amitabha/core/theme/brand.dart';
import 'package:amitabha/core/widgets/content_width.dart';
import 'package:amitabha/features/asr/application/asr_session_controller.dart';
import 'package:amitabha/l10n/generated/app_localizations.dart';
import 'package:amitabha/storage/app_paths.dart';
import 'package:amitabha/storage/atomic_io.dart';
import 'package:amitabha/storage/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

double _scale(BuildContext context) => layoutScale(context);

const Color _goldHairline = Color(0x4D82663A);
const Color _goldDeep = Color(0xFF82663A);
const Color _amitabhaInk = Brand.amitabhaInk;
const Color _brownSoft = Color(0xFF6F4E37);

const RadialGradient _recordsBackground = RadialGradient(
  center: Alignment(0, -0.55),
  radius: 1.3,
  colors: [Color(0xFFFFFCF3), Color(0xFFFFF8E7), Color(0xFFF3E7CE)],
  stops: [0.0, 0.55, 1.0],
);

const RadialGradient _headerSpotlight = RadialGradient(
  center: Alignment(0, -0.35),
  radius: 1.0,
  colors: [Color(0x4DFFFCF3), Color(0x1AFFFCF3), Color(0x00FFFCF3)],
  stops: [0.0, 0.5, 1.0],
);

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeObj = Localizations.localeOf(context);
    final locale = localeObj.toString();

    final df = localeObj.languageCode == 'en'
        ? DateFormat.yMd(locale)
        : DateFormat(
            (DateFormat.yMd(locale).pattern ?? 'yyyy/MM/dd')
                .replaceAll(RegExp('M+'), 'MM')
                .replaceAll(RegExp('d+'), 'dd')
                .replaceAll(RegExp('y+'), 'yyyy'),
            locale,
          );

    final dfMonth = DateFormat.yMMM(locale);
    final ver = context.select<AsrSessionController, int>((s) => s.dataVersion);

    final bottomInset = MediaQuery.of(context).padding.bottom + 80;

    return Brand.withFontFamily(
      context,

      Container(
        decoration: const BoxDecoration(gradient: _recordsBackground),
        child: _buildContent(context, t, df, dfMonth, ver, bottomInset),
      ),
      family: Brand.primaryFontFor(localeObj),
      fallback: Brand.cjkFallback,
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations t,
    DateFormat df,
    DateFormat dfMonth,
    int ver,
    double bottomInset,
  ) {
    return FutureBuilder<_DailyLoadResult>(
      key: ValueKey(ver),
      future: _loadAllDaily(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        final header = _HeaderCards(
          totalText: '${data.total}',
          practiceDaysText: '${data.practiceDays}',
          calligraphyAsset: AppAssets.calligraphy(
            Localizations.localeOf(context).languageCode,
          ),
          t: t,
        );

        if (data.items.isEmpty) {
          return SafeArea(
            top: true,
            bottom: false,
            child: ContentWidth(
              child: ListView(
                padding: EdgeInsets.only(bottom: bottomInset),
                children: [
                  header,
                  Padding(
                    padding: EdgeInsets.all(24 * _scale(context)),
                    child: Center(
                      child: Text(
                        t.noRecords,
                        style: TextStyle(
                          fontSize: 20 * _scale(context),
                          color: _brownSoft,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ContentWidth(
          child: CustomScrollView(
            slivers: [
              SliverSafeArea(
                top: true,
                bottom: false,
                sliver: SliverToBoxAdapter(child: header),
              ),
              SliverList.builder(
                itemCount: data.items.length,
                itemBuilder: (_, i) {
                  final r = data.items[i];
                  final y = int.parse(r.yyyymmdd.substring(0, 4));
                  final m = int.parse(r.yyyymmdd.substring(4, 6));
                  final d = int.parse(r.yyyymmdd.substring(6, 8));
                  final dt = DateTime(y, m, d);

                  final isMonthStart =
                      i == 0 ||
                      data.items[i - 1].yyyymmdd.substring(0, 6) !=
                          r.yyyymmdd.substring(0, 6);

                  final tile = _RecordTile(
                    dateText: df.format(dt),
                    countText: '${r.amitabhaCount}',
                    unitText: t.times,
                  );

                  if (!isMonthStart) return tile;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MonthHeader(label: dfMonth.format(dt), isFirst: i == 0),
                      tile,
                    ],
                  );
                },
              ),
              SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
            ],
          ),
        );
      },
    );
  }
}

class _DailyLoadResult {
  final List<DailySummary> items;
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
    } catch (_) {}
  }

  items.sort((a, b) => b.yyyymmdd.compareTo(a.yyyymmdd));

  final total = items.fold<int>(0, (s, e) => s + e.amitabhaCount);
  final practiceDays = items.where((e) => e.amitabhaCount > 0).length;

  return _DailyLoadResult(items, total, practiceDays);
}

class _HeaderCards extends StatelessWidget {
  final String totalText;
  final String practiceDaysText;
  final String calligraphyAsset;
  final AppLocalizations t;

  const _HeaderCards({
    required this.totalText,
    required this.practiceDaysText,
    required this.calligraphyAsset,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    return Container(
      decoration: const BoxDecoration(gradient: _headerSpotlight),
      padding: EdgeInsets.fromLTRB(24 * s, 16 * s, 24 * s, 24 * s),
      child: Column(
        children: [
          Image.asset(
            calligraphyAsset,
            width: MediaQuery.of(context).size.width * 0.6,
            fit: BoxFit.contain,
            color: _amitabhaInk,
            colorBlendMode: BlendMode.srcIn,
            semanticLabel: t.amitabha,
          ),
          SizedBox(height: 2 * s),

          _CenteredMetric(
            value: totalText,
            label: t.times,
            valueSize: 80 * s,
            labelSize: 16 * s,

            maxScaleFactor: 1.4,
            valueWeight: FontWeight.w400,
            letterSpacing: 1,
          ),
          SizedBox(height: 16 * s),

          SizedBox(
            width: MediaQuery.of(context).size.width * 0.72,
            child: _GoldDivider(label: t.total),
          ),
          SizedBox(height: 14 * s),

          _CenteredMetric(
            value: practiceDaysText,
            label: t.days,
            valueSize: 44 * s,
            labelSize: 19 * s,
            maxScaleFactor: 1.6,
            valueWeight: FontWeight.w500,

            centerValueOnAxis: true,
          ),
        ],
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  final String? label;
  const _GoldDivider({this.label});

  @override
  Widget build(BuildContext context) {
    final l = label;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        return _row(context, l, maxWidth);
      },
    );
  }

  Widget _row(BuildContext context, String? l, double maxWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _line(fadeToLeft: true)),
        if (l != null)
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.6,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth - 32),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 14 * _scale(context),
                  right: 10 * _scale(context),
                ),
                child: Text(
                  l,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13 * _scale(context),
                    color: _brownSoft,
                    letterSpacing: 4 * _scale(context),
                  ),
                ),
              ),
            ),
          ),
        Expanded(child: _line(fadeToLeft: false)),
      ],
    );
  }

  Widget _line({required bool fadeToLeft}) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _goldDeep.withValues(alpha: fadeToLeft ? 0.0 : 0.5),
            _goldDeep.withValues(alpha: fadeToLeft ? 0.5 : 0.0),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String label;
  final bool isFirst;

  const _MonthHeader({required this.label, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22 * s,
        (isFirst ? 4 : 28) * s,
        22 * s,
        10 * s,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13 * s,
          fontWeight: FontWeight.w500,
          color: _brownSoft,
          letterSpacing: 1 * s,
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final String dateText;
  final String countText;
  final String unitText;

  const _RecordTile({
    required this.dateText,
    required this.countText,
    required this.unitText,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    final scaledDate = MediaQuery.textScalerOf(context).scale(19 * s);
    final stacked = scaledDate > 30 * s;

    final dateWidget = Text(
      dateText,
      style: TextStyle(
        fontSize: 19 * s,
        fontWeight: FontWeight.w400,
        color: _amitabhaInk,
      ),
    );

    final countWidget = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: countText,
            style: TextStyle(fontSize: 32 * s, fontWeight: FontWeight.w400),
          ),
          TextSpan(
            text: ' $unitText',
            style: TextStyle(fontSize: 15 * s, fontWeight: FontWeight.w400),
          ),
        ],
      ),

      style: const TextStyle(color: _amitabhaInk),
      textAlign: stacked ? TextAlign.start : TextAlign.end,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 22 * s),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _goldHairline, width: 1)),
      ),
      padding: EdgeInsets.symmetric(vertical: 18 * s),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dateWidget,
                SizedBox(height: 6 * s),
                countWidget,
              ],
            )
          : Row(
              children: [
                Expanded(child: dateWidget),
                SizedBox(width: 12 * s),

                Expanded(child: countWidget),
              ],
            ),
    );
  }
}

class _CenteredMetric extends StatelessWidget {
  const _CenteredMetric({
    required this.value,
    required this.label,
    required this.valueSize,
    required this.labelSize,
    required this.maxScaleFactor,
    required this.valueWeight,
    this.letterSpacing,
    this.centerValueOnAxis = false,
  });

  final String value;
  final String label;
  final double valueSize;
  final double labelSize;
  final double maxScaleFactor;
  final FontWeight valueWeight;
  final double? letterSpacing;

  final bool centerValueOnAxis;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: valueSize,
      fontWeight: valueWeight,
      height: 1.0,
      color: _goldDeep,
      letterSpacing: letterSpacing,
    );
    final labelStyle = TextStyle(fontSize: labelSize, color: _brownSoft);

    if (centerValueOnAxis) {
      final labelWidget = Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: labelStyle,
      );
      return MediaQuery.withClampedTextScaling(
        maxScaleFactor: maxScaleFactor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: labelWidget,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: valueStyle,
              ),
            ),
            const SizedBox(width: 8),
            labelWidget,
          ],
        ),
      );
    }

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxScaleFactor,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,

              child: Text('  $label', maxLines: 1, style: labelStyle),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: value, style: valueStyle),
                  TextSpan(text: '  $label', style: labelStyle),
                ],
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
