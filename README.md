# AnythingBar

AnythingBarは、クリップボードの文字列を判定し、その内容に合う操作を素早く実行するmacOSネイティブのコマンドバーです。メニューバーに常駐し、外部サーバー、データベース、LLM、外部AI APIを使わず、すべてローカルで処理します。

## 対応している内容

| 種類 | 判定 | 操作 |
| --- | --- | --- |
| URL | `http` / `https`スキームとホストを持つ有効な`URL` | ブラウザで開く、URLをコピー、Markdownリンクでコピー、ドメインをコピー |
| メールアドレス | 一般的なメールアドレス形式 | 新規メールを作成、アドレスをコピー、ドメインをコピー |
| 日本株の証券コード | 前後の空白を除いた半角数字4桁 | 企業IRをGoogle検索、TDnetを検索、EDINETを検索、コードをコピー |
| 通常テキスト | 上記以外 | Google検索、コピー、文字数を表示、履歴へ保存 |

Markdownリンクのタイトルにはドメイン名を使います。Webページの取得は行いません。証券コードが実在するかどうかも外部APIでは検証しません。

## 操作方法

1. 別のアプリでテキストをコピーします。
2. `Command＋Shift＋Space`を押します。
3. 画面中央の操作バーで候補を選びます。
4. `Enter`で実行します。通常は実行後に操作バーが閉じます。

初期ショートカットは設定画面から変更できます。設定したショートカットはKeyboardShortcutsによって`UserDefaults`へ保存されます。

### キーボード操作

| キー | 動作 |
| --- | --- |
| `↑` / `↓` | 前後の操作を選択 |
| `Enter` | 選択中の操作を実行 |
| `Esc` | 操作バーを閉じる |
| `Command＋C` | 取得中の内容をコピー |
| 文字入力 | タイトル、サブタイトル、keywordsから候補を絞り込む |

## メニューバー

メニューバーから以下を利用できます。

- AnythingBarを開く
- 設定
- 履歴
- Accessibility対応が今後追加予定であることの表示
- AnythingBarを終了

`LSUIElement`を有効にしているため、Dockアイコンは表示されません。

## 履歴とプライバシー

成功した操作は、設定が有効な場合にローカルのJSONファイルへ保存されます。保存件数は直近50件です。

保存項目は、取得内容、正規化後の内容、判定種類、取得日時、実行した操作、実行日時です。同じ内容は連続して重複保存しません。

- 履歴保存は設定で無効化できます。
- メールアドレスの履歴保存は個別に有効化できます。初期値は無効です。
- 設定画面または履歴画面から履歴をすべて削除できます。
- クリップボード、分類、履歴、操作実行はすべてMac内で処理します。
- 取得内容や履歴を外部へ送信しません。

履歴ファイルの保存場所：

```text
~/Library/Application Support/AnythingBar/history.json
```

設定とショートカットは、通常は次の`UserDefaults`ドメインへ保存されます。

```text
~/Library/Preferences/com.mamorukomo.AnythingBar.plist
```

## 技術構成

- Swift 6
- SwiftUI
- AppKit（`NSPanel`、`NSWorkspace`、`NSPasteboard`、メニューバー）
- macOS 14.0以降
- Xcodeプロジェクト
- Swift Package Manager
- [KeyboardShortcuts 3.0.1](https://github.com/sindresorhus/KeyboardShortcuts)
- JSONファイルによるローカル履歴

操作バーの表示、前面化、中央配置、キーイベントはAppKitが担当し、内容表示と候補一覧はSwiftUIで構成しています。

## ディレクトリ構成

```text
AnythingBar/
├── AnythingBar.xcodeproj/       # App / Core / CoreTestsターゲット
├── Config/
│   └── Info.plist               # LSUIElement、バンドル情報
├── Sources/
│   ├── AnythingBar/             # AppKit・SwiftUIアプリ層
│   │   ├── App/                 # AppDelegate、Coordinator、メニューバー
│   │   ├── Features/            # 操作バー、設定、履歴UI
│   │   └── Services/            # Clipboard、Executor、Hotkey、設定
│   └── AnythingBarCore/         # UI非依存のモデル・分類・候補・URL・履歴
├── Tests/
│   └── AnythingBarCoreTests/    # Swift Testingによる単体テスト
└── Package.swift                # CoreのCLIビルド・テスト用
```

`AnythingBarCore`をUI非依存にし、取得、分類、候補生成、URL生成、履歴を個別にテストできるようにしています。App層では`NSPasteboard`と`NSWorkspace`をサービスの背後に置き、Viewから直接操作しません。

## ビルド方法

必要環境：

- macOS 14以降
- Swift 6.2を含むXcode 26以降、またはKeyboardShortcuts 3.0.1を解決できる互換Xcode

手順：

1. `AnythingBar.xcodeproj`をXcodeで開きます。
2. XcodeがSwift Package Managerの依存関係を解決するまで待ちます。
3. 必要に応じてAnythingBarターゲットのSigning Teamを選択します。
4. `AnythingBar`スキームと`My Mac`を選び、Runします。

コマンドラインでビルドする場合：

```bash
xcodebuild \
  -project AnythingBar.xcodeproj \
  -scheme AnythingBar \
  -destination 'platform=macOS' \
  build
```

## テスト方法

Xcodeまたは`xcodebuild`から、Appと同じ共有スキームでCoreテストを実行できます。

```bash
xcodebuild \
  -project AnythingBar.xcodeproj \
  -scheme AnythingBar \
  -destination 'platform=macOS' \
  test
```

CoreだけをSwift Package Managerでテストすることもできます。

```bash
swift test
```

テスト対象には、URL・メール・証券コード・通常テキストの分類、前後空白の除去、検索URLのエンコード、種類別の操作候補、履歴の50件制限、連続重複防止が含まれます。

## 現在の制限

- MVPではクリップボードの文字列だけを取得します。
- 他アプリで選択中のテキストを直接取得する機能はありません。
- 画像、ファイル、リッチテキスト固有の処理には対応していません。
- Markdownタイトルはページタイトルではなくドメイン名です。
- 証券コードの実在確認は行いません。
- TDnetとEDINETは、各公式ドメインを対象にしたGoogle検索を開きます。APIやスクレイピングは使いません。
- 履歴は暗号化せず、ユーザーのApplication Supportフォルダに保存します。機密内容を扱う場合は履歴を無効にしてください。

今後、Accessibility APIを使って他アプリで選択中のテキストを取得する機能を追加する予定です。MVPではAccessibility権限を要求しません。
