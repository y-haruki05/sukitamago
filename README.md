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
- `Features/ExperienceDetailView.swift`：写真ミッション詳細、共通PlaceholderView
- `ContentView.swift`：標準TabViewと4タブ

体験の保存・履歴閲覧はIssue #9で追加しました。成長ロジック、設定、探索は未実装です。
SwiftDataの既存Itemモデルは互換性のため保持しています。
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


## 写真ミッション（Issue #5）

ホームのメインボタン／おすすめカード → ミッション詳細 →「体験をはじめる」→
撮影または写真選択 → プレビュー → 完了 → ホームの順に進みます。
撮影中はフルスクリーンでTabViewと分離し、完了後は詳細画面も閉じます。
「とじる」で詳細へ、「撮り直す」またはプレビューの「戻る」で写真取得へ戻れます。

- `Features/PhotoMission/CameraPicker.swift`：UIImagePickerControllerのラッパー、写真／キャンセル／取得失敗の通知
- `Features/PhotoMission/PhotoMissionState.swift`：一時画像、フェーズ、エラー、カメラ権限判定
- `Features/PhotoMission/MissionPhotoLoader.swift`：PhotosPicker画像の非同期読み込み後、ImageIOで長辺2048px以下に縮小デコード（向きを補正）
- `Features/PhotoMission/PhotoMissionView.swift`：写真取得、共通プレビュー、完了、設定アプリへの導線

カメラ利用目的は生成Info.plistのNSCameraUsageDescriptionに設定しています。
Simulatorではカメラ対応を返すランタイムもあるため、明示的に標準PhotosPickerの代替導線を使います。
実機ではカメラの利用可否を標準APIで確認します。
PhotosPickerは選択された写真だけを受け取るため、ライブラリ全体へのアクセス権限は要求しません。
端末でカメラ権限が拒否された場合は案内から設定を開けます。利用制限の場合も別の案内を表示します。

写真はPhotoMissionState内のUIImageをプレビューと完了画面で共有します。
振り返り完了時にSwiftDataとアプリ専用ファイルへ保存します。写真ライブラリには追加しません。
保存前にホームへ戻りフローが破棄されると下書きは解放されます。
バックグラウンドへ移ると取得処理を中断し、遅れて届く結果を無視します。
取得済みの写真はフローが生存している間は保持しますが、アプリ終了後の復元はありません。

PhotoMissionStateTestsで権限結果、カメラ非対応、キャンセル、中断、撮り直し、確定の制御、画像デコードを検証します。
PhotoMissionUITestsは実際のPhotosPickerを操作するため、Simulatorの写真ライブラリにテスト用画像を1枚以上追加してから実行してください。

```sh
xcrun simctl addmedia <SimulatorのUDID> /path/to/test-photo.png
```

Simulatorでは実機のカメラ撮影・権限ダイアログは検証できません。
実機の撮影・キャンセル・権限拒否／制限・設定からの復帰・撮影中のバックグラウンド移行は、別途実機で確認が必要です。


## 体験の振り返り（Issue #7）

写真プレビューの「この写真にする」で振り返りへ進みます。3つの気持ちから1つを選び、
「振り返りを終える」で初めて体験完了になります。感想は任意です。
どの気持ちにも同じお祝いを表示し、それぞれの気づきを肯定するメッセージを添えます。

- `Features/Reflection/ExperienceReflection.swift`：安定したrawValueを持つExperienceFeelingと確定済みのExperienceReflection
- `Features/Reflection/ExperienceReflectionView.swift`：気持ちカード、写真、任意の感想、完了操作
- `Features/Reflection/ReflectionNoteEditor.swift`：UIKitの複数行入力。日本語変換中のmarkedTextRangeは切り詰めず、確定後に200文字までに制限
- `PhotoMissionState`：ミッション・画像・回答の下書き・確定結果を同一セッションで保持

写真がない状態や気持ちが未選択の状態では完了できません。感想はSwiftのCharacter単位（絵文字も1文字）で制限し、
確定結果では前後の空白・改行を除去します。変換中は完了を無効にし、キーボード上の「キーボードを閉じる」でも変換確定できます。
入力欄と完了ボタンはスクロールでき、前のプレビューへ戻っても回答は保持します。
写真の撮り直し、ホームへ戻った後の新しい体験では前回の回答を引き継ぎません。

確定結果は `state.reflection` から、関連するミッションは `state.experience`、同じ画像の参照は `state.photo` から取得できます。
保存前の写真・回答はメモリに保持し、Issue #9の保存処理が両方成功した時点で完了します。

ExperienceReflectionTestsは未選択の制御、選択変更、空欄の感想、200文字（絵文字を含む）、空白除去、
戻る／撮り直し／新しい体験の状態、完了メッセージを検証します。
ReflectionNoteEditorTestsはUIKitの未確定文字列APIを使って変換中と確定後の制限を検証します。
ExperienceReflectionUITestsは実際のPhotosPickerから振り返り・入力・戻る・完了・新しい体験を通して確認します。
実際の日本語キーボードでの候補選択・音声入力等は、別途手動確認してください。


## 体験記録・履歴（Issue #9）

振り返りを終える → 写真と記録の保存 → 完了 → ホーム →「きろく」→ 詳細、の流れです。
空の履歴からは「体験を探してみる」でホームに戻れます。記録は日時の降順、同日時はUUID文字列の昇順です。

- `Persistence/ExperienceRecord.swift`：SwiftDataモデル。セッションUUIDを一意キーにし、ミッションID、タイトルのスナップショット、日時、気持ちのrawValue、任意の感想、写真の相対ファイル名を保存します。
- `Persistence/ExperiencePhotoStore.swift`：Application Support/ExperiencePhotos/<UUID>.jpg。長辺2048px以下、向き補正、縦横比維持、JPEG品質0.82で保存します。DBと写真は端末／iCloudバックアップに含める方針です（クラウド同期機能は追加しません）。
- `Persistence/ExperienceRecordStore.swift`：写真保存後に一覧と共通のmainContextでDBを保存（他の未保存編集があれば開始せずエラー）。失敗時はrollbackと写真削除を行い、下書きは維持します。同一セッションIDの再保存は既存記録を返すのと同等に扱い、追加しません。
- `Persistence/ExperiencePersistence.swift`：既存ストアにモデルを登録。テスト用in-memory構成とDEBUG限定の分離した永続ストアに対応します。
- `Features/History/`：LazyVStackの履歴、詳細、確認付き削除、写真の非同期縮小デコードと欠損時の代替表示です。

削除は圧縮JPEGの一時バックアップをメモリに保持して写真を削除し、その後DBを保存します。
写真削除失敗ならDBは変更せず、DB失敗ならrollbackして写真を復元します。復元自体の失敗もエラーとして通知します。
ファイルとDBを跨ぐ完全な原子性はないため、操作中のOS強制終了等では欠損／孤立ファイルが残る可能性があります。
欠損写真でも履歴表示・削除を継続できます。通常の保存失敗では作成ファイルを清掃し、完了には進みません。
コンテナの初期化失敗時は記録を消さず、起動エラー画面を表示します。

全UIテストはDEBUG限定 `-experienceTestStore <UUID>` を指定し、Application Support/UITests/<UUID>/以下の
専用DBと写真フォルダ、および `sukitamago.UITests.<UUID>` の専用UserDefaultsを使用します。同じIDで再起動すると保存を検証でき、実ユーザーの記録は削除しません。
ユニットテストはin-memory DBと一時写真フォルダを使用します。
`ExperienceRecordStoreTests` が保存・復元・失敗・再試行・重複防止・削除・安定ソートを、
`ExperienceHistoryUITests` が実際のPhotosPickerから保存、再起動、詳細、削除、空表示まで検証します。


Issue #9の検証環境はXcode 16.2 / Swift 6.0.3（プロジェクト設定Swift 5）/ iPhone SE（第3世代）iOS 18.2です。
新規の保存・削除テストと、既存のオンボーディング・写真・振り返り・ホームのテストを実行します。
実機撮影、iOS 17実行、VoiceOver・Dynamic Typeの全設定での手動確認は別途必要です。

Xcode 16.2でテスト先をUUID指定すると、同じUUID・OS・デバイス名の候補を2件表示する警告が出ます。
`simctl list devices available` と `xcodebuild -showdestinations` では該当デバイスは1台です。
プロジェクトのビルド設定変更によるものではなく、Xcode側の候補解決に由来すると判断しています。
Simulatorの削除・初期化やビルド設定変更は行っていません。
