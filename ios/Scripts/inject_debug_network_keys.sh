#!/bin/sh
# 區域網路除錯 key 只注入 Debug / Profile 產物；Release 不含，上架版本因此不宣告。
# 無線實機除錯時 Flutter 只能靠 mDNS 找到 Dart VM Service，缺這兩個 key 會失效。
# 服務名須為 _dartVmService._tcp（Flutter 3.x）；_dartobservatory._tcp 為舊名相容。
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
"${PB}" -c "Add :NSBonjourServices:0 string _dartVmService._tcp" "${PLIST}"
"${PB}" -c "Add :NSBonjourServices:1 string _dartobservatory._tcp" "${PLIST}"

echo "note: injected local-network debug keys into ${INFOPLIST_PATH} (${CONFIGURATION})"
