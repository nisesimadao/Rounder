# **Rounder: macOS 画面コーナー丸角化ツール 仕様書**

## **1\. コアコンセプト**

Notch導入以前のMacBookや外部モニターの直線的な角を、ソフトウェア制御のオーバーレイによってモダンな丸角（Rounded Corners）に見せる。

## **2\. ウィンドウ設計 (Window Architecture)**

macOSのシステムUIを上書きするための特殊なウィンドウ設定。

### **ウィンドウレベル (Window Level)**

* **設定値**: NSWindow.Level.screenSaver (または statusBar \+ 1\)  
* **理由**: NSWindow.Level.mainMenu (メニューバー) より高いレベルに設定する必要がある。screenSaver レベルを使用することで、メニューバー、コントロールセンター、通知センターのすべてを覆うことが可能。

### **ウィンドウ属性 (Window Styles)**

* **Style Mask**: .borderless  
* **背景**: NSColor.clear  
* **不透明度**: isOpaque \= false  
* **影の無効化**: hasShadow \= false (角に余計な影が出ないようにする)

### **インタラクション設定 (Event Handling)**

* **マウスイベントの透過**: ignoresMouseEvents \= true  
  * これを設定しないと、画面の角にあるメニュー（Appleメニュー等）やボタンがクリック不能になる。  
* **スペース跨ぎ**: .canJoinAllSpaces  
  * 仮想デスクトップを切り替えても角が常に表示されるようにする。  
* **フルスクリーン対応**: .fullScreenAuxiliary  
  * 動画視聴やゲームなどのフルスクリーンモード時にもオーバーレイを維持する。

## **3\. 描画エンジンの仕様 (Graphics & Rendering)**

### **描画方式の選択**

1. **四隅分割方式（推奨）**: 四隅に小さな ![][image1] のウィンドウを4つ配置する。  
   * **メリット**: メモリ消費が極めて少なく、画面中央の描画更新に影響を与えない。  
2. **フルスクリーン・単一ウィンドウ方式**: 画面全体を1枚の透明な布のように覆う。  
   * **メリット**: 実装が単純。

### **シェイプの作成 (Drawing Logic)**

* **Core Graphics (Quartz 2D)** を使用。  
* **アルゴリズム**:  
  1. 四角形を描画。  
  2. そこから appendBezierPathWithArc 等を用いて円弧をくり抜く（サブトラクション）。  
  3. 塗りつぶし色は NSColor.black またはユーザー指定色。  
* **アンチエイリアス**: context.shouldAntialias \= true を設定し、ジャギー（階段状のガタつき）を完全に排除する。

## **4\. 機能要件 (Feature Requirements)**

### **ユーザーカスタマイズ**

* **Radius (半径) スライダー**: 0px 〜 40px 程度まで調整可能にする。  
* **カラー選択**: 黒以外のベゼル（シルバーや白）に対応するため、色の変更を許可。  
* **特定ディスプレイの無効化**: マルチディスプレイ環境で、すでに角が丸い本体（Notch付き）には適用しない設定。

### **システム連携**

* **画面解像度変更の監視**: NSApplication.didChangeScreenParametersNotification を受信し、リサイズやディスプレイ接続時にウィンドウ位置を自動再計算。  
* **メニューバー表示状態の監視**: メニューバーの「自動的に隠す」設定がオンの場合でも、描画が崩れないように座標を NSScreen.frame (絶対座標) ベースで計算する。

## **5\. 技術スタック案**

* **Language**: Swift 5.10+  
* **Framework**: AppKit (NSWindow, NSScreen) & SwiftUI (設定画面用)  
* **Persistence**: UserDefaults (設定の保存)

## **6\. 実装上の注意点 (Pitfalls)**

* **パフォーマンス**: draw(\_:) メソッドを頻繁に呼び出すとCPUを消費するため、CALayer にパスをキャッシュする手法を推奨。  
* **メニューバーとの隙間**: Retinaディスプレイでは1pxの隙間が目立つ場合があるため、描画座標を整数 (Int) ではなく浮動小数点 (CGFloat) で精密に制御し、わずかに（0.5px程度）外側へオーバーラップさせる調整が必要。  
* **事実確認**: コーディングには最適・最新・安定の情報が必須です。定期的に調べながら実装を続けましょう。

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAD4AAAAYCAYAAACiNE5vAAACaElEQVR4Xu2XO0hcQRSGd6OJlaBpEsnuzl1YuMlWgUVMYRA0IFkI9haJYJPKRqs0ISCYKhDRwt4UJoWFNraC5UKKkMIUIZDCIhHNQ0Qx+p/rmWT27NwnYRGZDw478//nzD1z784+cjmHw+G4pHQopfYRp0Z8I8PzvNsY/zY9aNu6EPOvom7837LtAdfcQRwbPRwitthbROwZHsWOXOCAjCaR0UVSJ3AjnsKblno7QQ/3uMd56RFR/ZP5PsyMKoR+LLV2gx5WqT/cgB7p1Wq1q9x/8C5oAcY7Tugz9VKp9BjaH9vGoS0UCoXrUg8DjQ1ITULHS2pxxDyYZ+RhHyPSC4AxRwnFYvG+qSs+M7xwp/A+mvMEdNJNlKImrPk4eOMnUidUxBEOgDlJCbjjE4b2xvf9brwuk1cul33D+6DHaahWq9dsjdi0JKDuDtXiwW0gHmFcRzw04jRybWx4iJNmtYZxg70X7NVpjgv0Yryg89IiNx/ZWAzo7S33NoOYNmIGfT4nDzmbsu4vOKu3OGmF5hh/0R60J+RhoSn2jrSXFb15Ckzz0k+KsUYLis83Ylh6TXBSAxu9iXipdWx4kDxorzF+gNcxsy4jV6KaTgqvEXa+fyVanxf5IRfCvI+9NellJNg0j+kHVHxzFvAA7nJfr6RHsBe/tk6kpxrm4QPuhvRSkrc0k2nzqFmnOs/y/V2pVLq4Z/v3twknWs8ve5+lnpaIDZrvgkRwT9Ya3Iwl8uiTXnotcGKv1ImwC6QBzYxKTZDH74h+KUrU+f8H+n/xHbGrzs/yJ/boOP5knXzK+x/H0+FwOBwXljMlhOby4b9XnQAAAABJRU5ErkJggg==>