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

## オンボーディング（Issue #3）

初回はウェルカム → 気持ちの単一選択 → 最初の体験紹介 → ホームの順に進みます。
途中では保存せず、戻る操作では選択を維持します。途中終了後は最初から表示します。
完了時に `@AppStorage` で `onboarding.startingMood`（安定した識別子）を保存し、
`onboarding.completed` を最後にtrueにして、AppRootViewから既存ContentViewへ切り替えます。

- `Features/Onboarding/AppRootView.swift`：初回起動の分岐と完了保存
- `Features/Onboarding/OnboardingState.swift`：ステップ、気持ち、遷移の排他制御
- `Features/Onboarding/OnboardingView.swift`：3ステップ、選択カード、下部の操作と進捗

DEBUGではホーム右上の設定 →「オンボーディングをリセット」で完了と気持ちを消去できます。
Releaseにはリセット操作を含みません。UIテスト用の起動引数
`-resetOnboardingForUITests` もDEBUG限定で、通常起動の保存状態には影響しません。

新規UIテスト `OnboardingUITests` では初回、単一選択、未選択の制御、戻る、途中終了、
完了後の再起動、DEBUGリセットを検証します。既存ホームのUIテストも最初にオンボーディングを完了します。
`OnboardingStateTests` は未選択の制御・遷移中の連続操作の防止・戻ったときの選択保持を検証します。
