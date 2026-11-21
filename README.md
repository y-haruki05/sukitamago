# sukitamago
小さな体験から、自分だけの「好き」を育てるiOSアプリ。

## 起動

Xcode 16.2以降で `sukitamago/sukitamago.xcodeproj` を開き、
Scheme「sukitamago」とiPhone Simulatorを選択してRunしてください。対応OSはiOS 17以上です。
外部ライブラリや追加設定は不要です。

## UI構成

- `DesignSystem/AppTheme.swift`：ライト・ダーク対応パレット、PrimaryButton
- `DesignSystem/EggCharacterView.swift`：ベクターキャラクター、表情、浮遊・呼吸・タップ反応
- `DesignSystem/ExperienceCard.swift`：体験の表示モデル、カード、カメライラスト
- `Features/HomeView.swift`：ホーム、設定の準備中案内、体験への導線
- `Features/ExperienceDetailView.swift`：体験の仮詳細、共通PlaceholderView
- `ContentView.swift`：標準TabViewと4タブ

撮影、体験保存、成長ロジック、設定、探索、記録機能は未実装です。
SwiftDataの既存テンプレートは保持しており、今回の画面はデータの読み書きを行いません。
キャラクターのExpressionは表示用で、将来の成長モデルから指定できます。

## 検証

Simulatorビルド：

```sh
xcodebuild -project sukitamago/sukitamago.xcodeproj -scheme sukitamago \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

UIテスト `sukitamagoUITests/testHomeNavigationAndTabs` は設定、2つの体験導線、4タブを確認します。
Dynamic Type、VoiceOver、動きを減らす設定、ダークモードは実装していますが、
各設定での手動確認もリリース前に実施してください。
