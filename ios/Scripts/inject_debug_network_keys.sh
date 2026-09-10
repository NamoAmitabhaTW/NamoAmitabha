#!/bin/sh
# 只在 Debug / Profile 組態，把區域網路除錯所需的 key 注入「已建構產物」的
# Info.plist。原始碼中的 ios/Runner/Info.plist 保持乾淨，因此 Release 上架
# 版本不會宣告 NSLocalNetworkUsageDescription / NSBonjourServices。
#
# 為什麼需要：無線實機除錯時，Flutter 只能靠 mDNS 找到 Dart VM Service
# （見 flutter_tools/lib/src/ios/devices.dart，讀裝置日誌那條備援路徑對無線
# 是關閉的）。VM Service 跑在 App 行程內，要在區域網路上被找到就需要這兩個
# key 宣告的權限。USB 連線可走 USB tunnel，不需要。
set -e

case "${CONFIGURATION}" in
  Debug*|Profile*) ;;
  *) exit 0 ;;
esac

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
[ -f "${PLIST}" ] || exit 0

PB=/usr/libexec/PlistBuddy

"${PB}" -c "Delete :NSLocalNetworkUsageDescription" "${PLIST}" 2>/dev/null || true
"${PB}" -c "Add :NSLocalNetworkUsageDescription string This app needs local network access to discover and connect to the Dart VM service during debugging." "${PLIST}"

"${PB}" -c "Delete :NSBonjourServices" "${PLIST}" 2>/dev/null || true
"${PB}" -c "Add :NSBonjourServices array" "${PLIST}"
# Flutter 3.x 的 mDNS 查詢名稱是 _dartVmService._tcp（見 flutter_tools/lib/src/
# mdns_discovery.dart 的 dartVmServiceName）。舊的 _dartobservatory._tcp 隨
# Observatory 退役已作廢、工具鏈不再查詢，一併保留僅為相容更舊的引擎。
"${PB}" -c "Add :NSBonjourServices:0 string _dartVmService._tcp" "${PLIST}"
"${PB}" -c "Add :NSBonjourServices:1 string _dartobservatory._tcp" "${PLIST}"

echo "note: injected local-network debug keys into ${INFOPLIST_PATH} (${CONFIGURATION})"
