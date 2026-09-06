# FAQ

## Gatekeeper の警告が出るのはなぜですか？

Rounder のリリース版は**ad-hoc署名されていますが、Developer ID署名・公証（notarization）は行っていません**。そのため、macOS が初回起動をブロックすることがあります。

`Rounder.app` を右クリックして **開く** を選び、確認画面でもう一度 **開く** を選んでください。必要な場合は、quarantine属性を手動で外すこともできます。

```bash
xattr -dr com.apple.quarantine /Applications/Rounder.app
```

## アクセシビリティ権限や画面収録権限は必要ですか？

必要ありません。Rounder はボーダーレスのオーバーレイウィンドウを描画するため、アクセシビリティ、画面収録、自動化などのプライバシー権限を使いません。

## MacBook の内蔵ディスプレイで角丸が見えないのはなぜですか？

Notch搭載Macの内蔵ディスプレイは、物理的に角が丸くなっています。Rounderは、角が直線的な外部モニターや古いMacBookディスプレイで最も効果が分かりやすいです。

## Rounder はデータを送信しますか？

送信しません。Rounder はテレメトリや分析を収集しません。設定は macOS の `UserDefaults` にローカル保存されます。

## ダウンロードを検証するには？

GitHub はリリースassetのSHA-256 digestを表示します。最新リリースで `Rounder.zip` の詳細を開き、GitHubに表示されているdigestとローカルのチェックサムを比較してください。

```bash
shasum -a 256 Rounder.zip
```
