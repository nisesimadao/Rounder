# FAQ

## Gatekeeper の警告が出るのはなぜですか？

Rounder のリリース版は ad-hoc 署名されていますが、Developer ID 署名と公証は行っていません。
そのため、macOS が初回起動をブロックする場合があります。

`Rounder.app` を右クリックして **開く** を選び、確認画面でもう一度 **開く** を選択してください。
必要な場合は、quarantine 属性を手動で削除できます。

```bash
xattr -dr com.apple.quarantine /Applications/Rounder.app
```

## アクセシビリティ権限や画面収録権限は必要ですか？

必要ありません。
Rounder はボーダーレスのオーバーレイウィンドウを描画するため、アクセシビリティ、画面収録、自動化などのプライバシー権限を使用しません。

## MacBook の内蔵ディスプレイで角丸が見えないのはなぜですか？

Notch 搭載 Mac の内蔵ディスプレイは、物理的に角が丸くなっています。
Rounder の効果は、角が直線的な外部モニターや古い MacBook のディスプレイで確認しやすくなります。

## Rounder はデータを送信しますか？

送信しません。
Rounder はテレメトリや分析データを収集しません。
設定は macOS の `UserDefaults` にローカル保存します。

## ダウンロードを検証するには？

GitHub Releases では、配布 asset の SHA-256 digest を確認できます。
最新リリースで `Rounder.zip` の詳細を開き、GitHub に表示される digest とローカルで計算したチェックサムを比較してください。

```bash
shasum -a 256 Rounder.zip
```
