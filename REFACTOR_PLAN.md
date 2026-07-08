# 念佛 App 健檢報告與重構優化計劃書

> 產出日期：2026-07-07(P0–P5 全部完成 ✅ 2026-07-08)
> 範圍：`amitabha/` Flutter 專案（Flutter 3.35.7 / Dart SDK ^3.8.1）
> 依據：全量原始碼閱讀、`flutter analyze`（43 個 issue）、`flutter test`（11 過 / 4 敗）

---

## 一、健檢總覽

| 面向 | 評分 | 摘要 |
|------|------|------|
| 功能完成度 | ★★★★☆ | 核心流程（ASR 計數、下載模型、背景、多語系）完整，錯誤處理用心 |
| 架構一致性 | ★★☆☆☆ | 新舊兩套結構並存：`lib/` 根目錄平面檔案 vs `features/` 分層 |
| 正確性風險 | ★★☆☆☆ | 35 處 `use_build_context_synchronously`、ASR stream 生命週期有 use-after-free 風險 |
| 可測試性 | ★★☆☆☆ | 業務邏輯與 UI（dialog/context）強耦合，核心流程無法單元測試 |
| 測試健康度 | ★☆☆☆☆ | 4 個測試失敗（mock 過期 + 模板殘留），測試無法當守門員 |
| 效能 | ★★★☆☆ | 解壓流程整包進記憶體 + 每檔開 isolate，低階機有 OOM 風險 |
| 資料層 | ★★★☆☆ | atomic write / single writer 設計好，但資料只增不減、commit 失敗會丟數 |

**整體判斷**：專案品質底子不差（錯誤處理、原子寫入、離線 fallback 都有想到），
主要債務集中在三處：**`utils.dart` 大雜燴**、**ASR 邏輯藏在隱形 widget**、**測試失修**。
不需要打掉重練，適合「分階段、每階段可獨立驗收」的漸進式重構。

---

## 二、問題清單（依嚴重度）

### 🔴 高：正確性 / 穩定性風險

| # | 問題 | 位置 | 說明 |
|---|------|------|------|
| H1 | `use_build_context_synchronously` ×35 | `utils.dart`、`streaming_asr.dart` | `await` 之後直接用 `context` 開 dialog / `Navigator.pop`。頁面若已卸載會 crash 或 pop 錯層。是 analyzer 43 個 issue 的主體 |
| H2 | 音訊 stream 訂閱未管理 | `streaming_asr.dart:191` | `stream.listen(...)` 回傳的 subscription 沒保存、沒 cancel。`_stop()` 先 `_stream?.free()` 再建新 stream，但舊 callback 可能還在跑 → 對已 free 的 native 資源呼叫 `acceptWaveform`，有 native crash 風險 |
| H3 | 解壓記憶體峰值過高 | `utils.dart:445-465` | `readAsBytesSync` 整包 → BZip2 全解 → Tar 全解，全部駐留記憶體；再對**每個檔案**各開一個 `compute` isolate（跨 isolate 複製大 onnx bytes）。模型數百 MB 時低階裝置可能 OOM |
| H4 | 測試失修（4 敗） | `test/` | ① `widget_test.dart` 仍是模板 counter 測試，必敗。② `storage_test.dart` 的 fake 只覆寫 `getApplicationDocumentsPath`，但 `AppPaths` 已改用 `getApplicationSupportDirectory` → 3 個 storage 測試全炸 |
| H5 | commit 失敗會丟計數 | `streaming_asr.dart:336-342` | `_commitSession` 先把 UI/狀態歸零，daily 寫入失敗只 `debugPrint`，該次計數永久遺失 |
| H6 | 本地資料無限成長 | `storage/` | session snapshot 與 hits NDJSON 只寫不讀、永不清理；`StorageCleaner` 寫好了但沒有任何呼叫點 |

### 🟠 中：架構債

| # | 問題 | 位置 | 說明 |
|---|------|------|------|
| A1 | 兩套目錄結構並存 | `lib/` | 根目錄殘留 7 個平面檔（`utils.dart`、`streaming_asr.dart`、`download_model.dart`、`online_model.dart`、`ars_hotwords.dart`、`model_cleanup.dart`、`amitabha_normalizer.dart`），與 `features/`、`core/`、`storage/` 新結構混用 |
| A2 | `core/core/` 雙層目錄 | `lib/core/core/theme/` | 明顯是路徑手誤，theme 埋了兩層 core |
| A3 | `home/` 與 `features/` 並存；`app/application/` 只有一檔 | `lib/` | 分層標準不一，新人無法判斷檔案該放哪 |
| A4 | `utils.dart` 大雜燴（734 行） | `utils.dart` | 混了：音訊轉換、下載主流程、解壓、對話框 UI、磁碟空間判斷、模型完整性驗證、日期工具、wakelock。UI（`showDialog`）與 IO 業務邏輯纏死，無法測試，也是 H1 的根源 |
| A5 | ASR 業務邏輯藏在隱形 widget | `streaming_asr.dart` | `StreamingAsrRunner` 是 `SizedBox.shrink()` 的無畫面 widget，透過 `AppState.bindAsrHandlers` 反向注入 callback。錄音、辨識、session、儲存全綁在 widget 生命週期上；`dispose()` 裡還呼叫 `context.read`（不安全，靠 try/catch 硬吞） |
| A6 | `DownloadModel` 職責混雜 | `download_model.dart` | 同時管：模型選擇（asr/kws）、下載進度、解壓進度、取消旗標、狀態文字 |
| A7 | 檔名 typo | `ars_hotwords.dart` | `ars` 應為 `asr` |
| A8 | 四份重複的 JSON prefs 樣板 | `theme_prefs` / `locale_prefs` / `background_prefs` / manifest cache | 讀寫模式幾乎相同（`_file()` → decode → try/catch 回 null），應抽共用 helper |

### 🟡 低：清潔度

| # | 問題 | 位置 |
|---|------|------|
| L1 | 死碼：`StorageCleaner`（無呼叫點）、`SessionRepository.readSnapshot`、`AppState` 的 `_records`/`totalCount`/`practiceDays`（RecordsScreen 自己算，這裡的永遠是空的）、`DownloadModel.useKws`/`ModelKind.kws` + `model_cleanup.dart` 的 KWS 項、`PositionedFillWatermark`、`app.dart` 註解掉的 `_flavorBanner` 與 `typedef MyApp` | 各處 |
| L2 | `_isEncoderSupported` 迴圈印錯變數：印 `encoder.name` 而非 `e.name` | `streaming_asr.dart:274` |
| L3 | `pubspec.yaml` description 仍是 "A new Flutter project"；模板註解未清 | `pubspec.yaml` |
| L4 | `analysis_options.yaml` 幾乎裸的 flutter_lints，無專案自訂規則 | `analysis_options.yaml` |
| L5 | 專案根目錄雜物：`new_manifest.xml`、`.DS_Store`、`.idea/workspace.xml` | 根目錄 |
| L6 | 硬編碼 userId `'local'` / userName `'使用者'` 散在 `streaming_asr.dart` | `streaming_asr.dart:79-80` |
| L7 | settings 頁棕色系常數硬編碼（註解自己也說該抽到 theme） | `settings_screen.dart:8-14` |

---

## 三、重構計劃（六個階段）

原則：
- **每階段獨立可驗收、可上架**，不做跨階段的半成品。
- **先建安全網（測試），再動刀（重構）**，順序不可顛倒。
- 全程不改變使用者可見行為（Phase 5 的效能改善除外——只會更快更省記憶體）。

### Phase 0：修復安全網（0.5–1 天）🔴 必做，最先做

目的：讓 `flutter test` + `flutter analyze` 變成可信任的守門員。

1. **修 `storage_test.dart`**：`_FakePathProvider` 補上
   `getApplicationSupportPath` / `getApplicationCachePath` / `getTemporaryPath` 的 override（對應 `AppPaths`、`ModelPaths` 實際用到的 API）。
2. **重寫 `widget_test.dart`**：刪掉模板 counter 測試，改成最小 smoke test
   （pump `App()`，驗證 `HomeShell` 與底部三個 tab 存在即可；需要 mock path_provider）。
3. **把 `path_provider_platform_interface` 加進 `dev_dependencies`**（目前 analyzer 警告 `depend_on_referenced_packages`）。
4. （可選）加一個 `tool/check.sh`：`flutter analyze && flutter test`，之後每個 Phase 完成都跑。

**驗收標準**：`flutter test` 全綠；analyzer 不再有 test 相關警告。

### Phase 1：死碼清理 + 目錄結構統一（1–2 天）

目的：先把地掃乾淨，後面的搬移 diff 才乾淨。純搬移/刪除，不改邏輯。

1. **刪除死碼**（見 L1 全清單）。`AppState` 刪掉 `_records`/`DailyRecord`/`totalCount`/`practiceDays`；若未來要做即時總數，屆時再從 repo 層做。
2. **修 `core/core/` → `core/`**：`lib/core/core/theme/*` 移到 `lib/core/theme/*`，全案更新 import。
3. **統一目錄結構**（目標樹如下），根目錄 7 個平面檔全部歸位：

```
lib/
├── main.dart
├── app/                      # App 殼：組裝 provider、MaterialApp、flavors
│   ├── app.dart              # (原 app.dart)
│   ├── app_state.dart        # (原 app/application/app_state.dart)
│   └── flavors.dart
├── core/
│   ├── theme/                # brand.dart, theme_controller.dart, theme_prefs.dart
│   ├── localization/         # locale_controller.dart, locale_prefs.dart
│   └── utils/
│       ├── audio_convert.dart    # convertBytesToFloat32 (從 utils.dart 抽出)
│       └── date_format.dart      # nowYmdLocal / formatYMd (從 utils.dart 抽出)
├── features/
│   ├── asr/
│   │   ├── application/          # (Phase 3 的 AsrSessionController 落點)
│   │   ├── domain/
│   │   │   └── amitabha_normalizer.dart   # (原根目錄)
│   │   ├── screens/  widgets/
│   │   └── streaming_asr.dart    # 暫時原樣搬入，Phase 3 再拆
│   ├── model_install/            # (Phase 2 拆 utils.dart 的落點)
│   │   ├── download_model.dart   # (原根目錄)
│   │   ├── online_model.dart     # (原根目錄)
│   │   ├── model_cleanup.dart    # (原根目錄)
│   │   ├── asr_hotwords.dart     # (原 ars_hotwords.dart，改名修 typo)
│   │   └── model_install.dart    # (原 utils.dart 剩餘部分，暫名)
│   ├── background/  records/  settings/
│   └── home/                     # (原 lib/home/)
├── storage/                      # 維持現狀（此層品質良好）
└── l10n/
```

4. 清理根目錄雜物：`new_manifest.xml` 確認用途後移除或歸檔；`.DS_Store` 加入 `.gitignore`。
5. `pubspec.yaml`：補正 description、清模板註解。

**驗收標準**：`flutter analyze` issue 數不增加；`flutter test` 全綠；App 三個 flavor 可正常編譯啟動。

### Phase 2：拆解 `utils.dart` — 下載/解壓與 UI 分離（2–3 天）⭐ 本計劃核心

目的：一次解決 A4 + H1 的 35 個 context 警告中屬於 utils.dart 的部分，讓下載流程可單元測試。

1. **抽純邏輯層 `ModelInstaller`**（純 Dart，不 import Flutter widget）：
   - API 形如：
     ```dart
     class ModelInstaller {
       Stream<InstallEvent> install(String modelName);   // 進度/階段事件
       Future<InstallStatus> status(String modelName);   // ready / needsDownload / needsUnzip / incomplete
       void cancel();
     }
     sealed class InstallEvent {}  // Downloading(progress) / Unzipping(progress) / Done / Failed(reason)
     ```
   - 把現有的下載（timeout、完整性驗證、殘檔策略）、解壓、`modelFilesComplete`、`ensureModelReady` 決策樹全部搬進來。**錯誤分類（網路/伺服器/磁碟滿/損毀）改為 typed failure reason**，不再於 IO 層直接開 dialog。
2. **UI 端 `ModelInstallFlow`**（薄薄一層，掛在 widget 樹內）：
   - 訂閱 `InstallEvent`，負責所有 dialog（確認下載、進度、各類失敗、重試、成功）。
   - 每次 `await` 後統一 `if (!context.mounted) return;` —— **此檔案是唯一允許碰 dialog 的地方**。
   - 現在 `_showRetryUnzipOnlyDialog` 的遞迴重試邏輯改為事件迴圈，消除遞迴 dialog。
3. **瘦身 `DownloadModel`** → 改名 `InstallProgressModel`：只留進度/狀態文字/取消旗標；模型名稱選擇移到 `ModelInstaller` 的參數；刪 kws 分支（已死碼）。
4. **補單元測試**：
   - `ModelInstaller.status()` 的四種狀態判定（用 temp dir 假檔案）。
   - 失敗分類：mock http client 丟 404 / SocketException / 假 ENOSPC → 驗證 typed reason 與殘檔保留策略（zip 該留就留、該刪就刪）。
   - `modelFilesComplete` 的 int8/float 擇一邏輯。

**驗收標準**：`utils.dart` 消失；`use_build_context_synchronously` 歸零（utils 部分）；新增 ≥10 個單元測試；手動驗證下載→取消→重試→解壓→成功全流程。

### Phase 3：ASR Session 邏輯抽離 widget（2–3 天）

目的：解決 A5 + H2 + H5，錄音/辨識/計數變成可測試的 controller。

1. **建 `AsrSessionController`（ChangeNotifier，註冊進 MultiProvider）**：
   - 持有 recognizer、stream、`AudioRecorder`、`HitLogger`、`BufferedHits`、session 狀態機（idle/recording/paused）。
   - `start()` / `stop()` / `save()` 直接是 controller 方法 → **刪除 `AppState.bindAsrHandlers` 反向綁定 hack**，UI 改 `context.read<AsrSessionController>().start()`。
   - `AppState` 只留 UI 狀態（isRecording、sessionCount、lastHitAt、dataVersion），或直接併入 controller 評估後刪除。
2. **修 H2（use-after-free）**：
   - `stream.listen` 的 `StreamSubscription` 存成員變數；`stop()` 順序改為：`await subscription.cancel()` → `await recorder.stop()` → 才 `_stream.free()` + 重建。
   - callback 內對 `_stream`/`_recognizer` 的 `!` 斷言改為區域變數快照 + null 檢查。
3. **修 H5（丟計數）**：commit 失敗時把 snapshot 寫入 `data/pending/` journal，下次啟動或下次 commit 時重放；成功才刪。歸零 UI 移到寫入成功之後。
4. **生命週期**：lifecycle observer 移進 controller（用 `WidgetsBindingObserver` 或 `AppLifecycleListener`）；`dispose` 不再碰 `context`。
5. **修 L2**（`e.name` 印錯）與 L6（userId/userName 抽成常數集中一處，為未來帳號功能留接縫）。
6. **補測試**：狀態機轉換（idle→recording→paused→commit）、命中累計、pending journal 重放。BufferedHits 已可測，補 flush 時序測試。

**驗收標準**：`streaming_asr.dart`（隱形 widget）刪除；analyzer 的 context 警告全案歸零；錄音→暫停→續錄→儲存、切後台自動暫停、殺 App 自動 commit 均手動驗證通過。

### Phase 4：儲存層強化（1–2 天）

> **2026-07-08 決策**:資料保留策略(第 1 項)**暫緩**——實測體積估算(重度使用一年 <110MB)
> 與雙平台既有使用者的風險考量,由專案擁有者決定不清理;日後若有使用者回報空間問題再啟用。
> 保留執行:prefs 統一(第 2 項,含 manifest 快取改原子寫入),併入 P5 一起實作。

1. **資料保留策略（H6）**：
   - hits NDJSON：目前無讀取方（純 debug 用途）→ 決策二選一：(a) 直接停寫並刪除 HitLogger/BufferedHits 鏈路；(b) 保留但啟動時清 30 天前的檔。**建議 (b)**，未來做「時段統計」功能時用得上。
   - session snapshot：daily 已彙總，snapshot 保留最近 N=100 個，啟動時背景清理。
   - 把 `StorageCleaner` 接上設定頁「清除資料」入口，或刪除。
2. **抽 `JsonPrefsFile` helper（A8）**：統一 theme/locale/background prefs 的讀寫樣板（含 atomic write —— 目前 prefs 都是直接 `writeAsString`，沒有走 `atomic_io`，順手補上）。
3. RecordsScreen 的 `_loadAllDaily` 目前每年 365 檔可接受；在檔案數 >1000 時再考慮彙總索引（先記入 backlog，不做）。

**驗收標準**：storage 測試擴充後全綠；手動塞 200 個 session 檔驗證清理。

### Phase 5：效能與品質收尾（1–2 天）

1. **解壓改單 isolate 串流（H3）**：整個「讀檔→BZip2→Tar→逐檔寫盤→回報進度」放進**一個** `Isolate.run`/長駐 isolate，用 `SendPort` 回報進度；避免整包 bytes 駐留主 isolate 與逐檔跨 isolate 複製。預期：記憶體峰值大幅下降、解壓時間縮短（少了 N 次 isolate 啟動）。
2. **強化 lint**：`analysis_options.yaml` 啟用（建議）：
   `always_declare_return_types`, `prefer_final_locals`, `unawaited_futures`, `avoid_dynamic_calls`, `directives_ordering`, `require_trailing_commas`。修完新增警告。
3. `pubspec` 依賴巡檢：`permission_handler` 只用到 `openAppSettings`（保留）；確認 `cached_network_image`/`video_player` 版本無已知安全公告；跑 `flutter pub outdated` 升 patch 版。
4. settings 頁色票抽進 `Brand`（L7）。

**驗收標準**：實機驗證模型下載+解壓（監控記憶體）；analyzer 0 issue；test 全綠。

---

## 四、時程與順序總表

| 階段 | 內容 | 預估 | 風險 | 依賴 |
|------|------|------|------|------|
| P0 ✅ | 修復測試安全網 | 0.5–1 天 | 低 | — |
| P1 ✅ | 死碼清理 + 目錄統一 | 1–2 天 | 低（純搬移） | P0 |
| P2 ✅ | 拆 utils.dart（下載/解壓服務化） | 2–3 天 | 中 | P1 |
| P3 ✅ | ASR controller 化 + 穩定性修復 | 2–3 天 | 中高（碰核心） | P2 |
| P4 ✅ | 儲存層保留策略(擱置) + prefs 統一 | 1–2 天 | 低 | P1 |
| P5 ✅ | 串流解壓 + lint + 依賴巡檢 | 1–2 天 | 中 | P2 |

合計約 **8–13 個工作天**。P4 可與 P2/P3 並行。每階段結束跑：`flutter analyze`、`flutter test`、三 flavor 編譯、核心流程手動驗證（下載模型 / 錄音計數 / 儲存 / 紀錄頁 / 換背景 / 換語言）。

## 五、明確不做的事（Non-goals）

- 不引入新狀態管理框架（Riverpod/Bloc）：Provider + ChangeNotifier 對此規模足夠，遷移成本不划算。
- 不動 `storage/` 的 atomic write / single writer 設計：這部分品質好，只做保留策略與 helper 統一。
- 不重寫 UI / 視覺：本計劃行為零變更（效能除外）。
- 不做雲端同步：`_commitSession` 註解裡的 "cloud sync" 目前是本地檔案，帳號/同步屬新功能，另立專案。
