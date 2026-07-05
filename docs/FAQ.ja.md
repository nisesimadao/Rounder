# FAQ

## Gatekeeper の警告が出るのはなぜですか？

Rounder のリリースビルドは、現在、有料の Apple Developer ID で署名していません。そのため、macOS が初回起動をブロックすることがあります。

`Rounder.app` を右クリックして **開く** を選び、確認画面でもう一度 **開く** を選んでください。手動で quarantine 属性を外す場合は次を実行します:

```bash
xattr -dr com.apple.quarantine /Applications/Rounder.app
```

## Accessibility 権限や Screen Recording 権限は必要ですか？

必要ありません。Rounder はボーダーレスのオーバーレイウィンドウを描画するため、Accessibility、Screen Recording、Automation などのプライバシー権限を使いません。

## MacBook の内蔵ディスプレイで角丸が見えないのはなぜですか？

ノッチ搭載 Mac の内蔵ディスプレイは、物理的に角が丸くなっています。Rounder は、角が直線的な外部モニターや古い MacBook ディスプレイで最も効果が分かりやすいです。

## Rounder はデータを送信しますか？

送信しません。Rounder はテレメトリや分析を収集しません。設定は macOS の `UserDefaults` にローカル保存されます。

## ダウンロードを検証するには？

GitHub はリリース asset の SHA-256 digest を表示します。最新リリースで `Rounder.zip` の詳細を開き、GitHub に表示されている digest とローカルのチェックサムを比較してください:

```bash
shasum -a 256 Rounder.zip
```
