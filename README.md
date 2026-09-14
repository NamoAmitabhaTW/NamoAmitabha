App名稱：好好念佛<br>
核心功能：語音辨識自動計算佛號數量<br>
解決痛點：減少計算佛號數量的分心

念佛是一個練習收攝身心的過程，
將注意力放在心中的一聲聲佛號。

目前現有的佛號計數方式，大多會動用手部，
使用者的心力或多或少會分散一些到觸覺上。

播放音檔的計數方式，使用者必須配合音檔速度，過程若要調整念誦速度，需停下重新設置。

此次開發的念佛App，透過語音辨識自動計數佛號，念佛過程可以隨時調整念誦速度，不用分心計算佛號數量。

## 建置前置步驟 / Build setup

語音辨識模型（約 160 MB）**未納入 git**，需在建置前從 GitHub Release 下載。
在 `flutter run` / `flutter build` 之前，先執行一次：

The ASR model (~160 MB) is **not stored in git**. Fetch it from the GitHub
Release before building — run this once (it downloads, verifies the SHA256
checksums, and extracts into `assets/ml/asr/`; it's idempotent and
skips if the files are already present):

```bash
./tool/fetch_model.sh
```

> 若 `assets/ml/asr/` 為空，App 會找不到模型而無法運作。CI 若之後加入
> `flutter build` / `flutter test`，也需在建置前加上這一步。

## Licenses

This project bundles two third-party components, both licensed under the
Apache License 2.0:

- **[sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx)** — on-device speech
  recognition runtime.
- **[X-ASR](https://github.com/Gilgamesh-J/X-ASR)** streaming zipformer model
  (zh-en, 960ms, int8) — the bundled ASR model, redistributed unmodified.

See `THIRD_PARTY_LICENSES.txt` for details.