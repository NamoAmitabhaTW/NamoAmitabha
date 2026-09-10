// lib/features/settings/presentation/leaf_layout.dart
import 'dart:ui' show Size;
import 'package:amitabha/core/assets/app_assets.dart';
import 'package:flutter/foundation.dart';

enum SettingsCanvas { phone, tabletPortrait, tabletLandscape }

const Map<SettingsCanvas, Size> settingsCanvasSize = {
  SettingsCanvas.phone: Size(1080, 1920),
  SettingsCanvas.tabletPortrait: Size(1080, 1440),
  SettingsCanvas.tabletLandscape: Size(1440, 1080),
};

const Map<SettingsCanvas, String> settingsCanvasBackground = {
  SettingsCanvas.phone: AppAssets.bodhiLeafPhone,
  SettingsCanvas.tabletPortrait: AppAssets.bodhiLeafTabletPortrait,
  SettingsCanvas.tabletLandscape: AppAssets.bodhiLeafTabletLandscape,
};

enum SettingsLeaf {
  language,
  background,
  announcements,
  dedication,
  rate,
  share,
}

@immutable
class LeafRect {
  const LeafRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get centerX => left + width / 2;

  double get centerY => top + height / 2;
}

@immutable
class LeafLayout {
  const LeafLayout({
    required this.phone,
    required this.tabletPortrait,
    required this.tabletLandscape,
  });

  final LeafRect phone;
  final LeafRect tabletPortrait;
  final LeafRect tabletLandscape;

  LeafRect forCanvas(SettingsCanvas canvas) => switch (canvas) {
    SettingsCanvas.phone => phone,
    SettingsCanvas.tabletPortrait => tabletPortrait,
    SettingsCanvas.tabletLandscape => tabletLandscape,
  };
}

const Map<SettingsLeaf, LeafLayout> settingsLeafLayout = {
  SettingsLeaf.language: LeafLayout(
    phone: LeafRect(left: 590, top: 185, width: 340, height: 240),
    tabletPortrait: LeafRect(left: 618, top: 148, width: 340, height: 240),
    tabletLandscape: LeafRect(left: 576, top: 98, width: 330, height: 230),
  ),

  SettingsLeaf.background: LeafLayout(
    phone: LeafRect(left: 0, top: 60, width: 430, height: 300),
    tabletPortrait: LeafRect(left: -32, top: 17, width: 340, height: 270),
    tabletLandscape: LeafRect(left: 23, top: 2, width: 340, height: 230),
  ),

  SettingsLeaf.announcements: LeafLayout(
    phone: LeafRect(left: 630, top: 1440, width: 380, height: 300),
    tabletPortrait: LeafRect(left: 552, top: 1021, width: 380, height: 300),
    tabletLandscape: LeafRect(left: 774, top: 609, width: 330, height: 240),
  ),

  SettingsLeaf.dedication: LeafLayout(
    phone: LeafRect(left: 70, top: 500, width: 400, height: 320),
    tabletPortrait: LeafRect(left: -20, top: 456, width: 400, height: 320),
    tabletLandscape: LeafRect(left: 177, top: 356, width: 330, height: 240),
  ),

  SettingsLeaf.rate: LeafLayout(
    phone: LeafRect(left: 190, top: 1060, width: 270, height: 320),
    tabletPortrait: LeafRect(left: 102, top: 874, width: 270, height: 320),
    tabletLandscape: LeafRect(left: 250, top: 700, width: 320, height: 230),
  ),

  SettingsLeaf.share: LeafLayout(
    phone: LeafRect(left: 620, top: 890, width: 280, height: 320),
    tabletPortrait: LeafRect(left: 692, top: 573, width: 280, height: 320),
    tabletLandscape: LeafRect(left: 956, top: 307, width: 320, height: 230),
  ),
};
