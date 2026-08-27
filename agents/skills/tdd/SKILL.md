---
name: tdd
description: ユーザとTDDを実行する。実装を始めるときやplanモードで計画するときに参照する。
---

# TDD

## Overview

- kent beckの提唱するTDDをユーザとともに実行
- ユーザが実行することで学びがある場合に実施する。機械的な置き換えなどの場合は実行不要

## 注意点

### テストリストの管理

- テストリストはClaudeの出力に留めず、`.private-scratch/test-list.md`に保存する。会話がcompactionされたりセッションが切れたりしても参照できるようにするため
- テストリストの各項目は、関数・メソッド単位ではなく外部から観測できる振る舞い単位で書く。実装の詳細(内部でどう分割するか)に結合させない。そうすることでRefactorフェーズで実装を自由に変更してもテストが壊れないようにする
- 作業中に新しいテストケースの必要性に気づいたら、その場で`.private-scratch/test-list.md`に追記する

### スコープ

- 専用のテストケース・テストファイルを作るのはプロダクションコードに対してのみ。テスト用util/ヘルパーなど、プロダクションコードではないものは専用のテストを作らず、プロダクションコードに対する(既存または現在書いている)テストを通じて間接的に検証する
- テストがRedの間は実装を行わない

### 進行とフェーズの委譲

- Red / Green / Refactor の実際の作業は、このskillの中では行わない。それぞれ専用のコマンド
  `/tdd-red` `/tdd-green` `/tdd-refactor` に委譲する。これらは `disable-model-invocation: true`
  のためユーザーしか呼び出せない。フェーズが完了したら次のフェーズを勝手に進めず、ユーザーが
  対応するコマンドを呼ぶまで待つこと
- `/tdd-refactor`は次の`/tdd-red`の直前に呼んでもよい。次のテストケースが書きにくいと感じた場合(例: テストコードの重複をutilへ共通化したい等)は、先に`/tdd-refactor`で構造を整えてから`/tdd-red`に進む
- Green・Refactorが完了し全テストがパスしている状態になったら、区切りとして`git add`でステージングしておく(コミットするかどうかは都度判断する)
- 都度細かくストップし、ユーザーに確認をする。ユーザーが理解していることを確認する
- ユーザからの確認があった場合、テストと実装を確認し、修正箇所がある場合にはヒントを出しつつ修正依頼

### 品質のセルフチェック

- 差分をユーザーに提示する前に、AIが脱線している兆候(依頼されていない機能の実装、テストの削除・無効化・期待値の書き換え、想定より広い範囲・ファイルへの変更)に該当していないか自己点検する。該当する場合は提示前に修正するか、理由を添えて先に相談する

## 手順

テストリスト作成 -> Red -> Green -> Refactor -> テストリスト更新
を基本とする。

1. ユーザーの実装しようとしている内容、設計について議論して理解する
1. 今後のやるべきTODOリスト、テストリストを作成し、ユーザーに提示する。`.private-scratch/test-list.md`にも保存する
1. ユーザーに `/tdd-red` の実行を促し、呼ばれるまで待つ(自分から実行しない)
1. ユーザーに `/tdd-green` の実行を促し、呼ばれるまで待つ(自分から実行しない)
1. 必要であればユーザーに `/tdd-refactor` の実行を促し、呼ばれるまで待つ(自分から実行しない)
1. ユーザからの質疑があった場合は完璧な回答を提示するのではなく、ヒントとなるような説明を提供
1. リストが尽きるまで3に戻る

1. テスト、実装が完了したとき、"/code-review"と"/gen-test"を実施、完了後コミット
1. TODOリスト、テストリストの見直しを行う。`.private-scratch/test-list.md`も更新する

## Example

## Bad case

```
def test_fetch_url(){
  // TODO(human)
  // requeset = mock()
  // request.return = {
  //   "result": 0,
  //   "body": "test-content"
  // }
  // url = "test-url"

  // result = fetch_url(url)

  // assert result == "test-content"
}

def fetch_url(url)
{
  // TODO(human)
  // 1. res = request(url)
  // 2. if res.result != 0
  // 2.1. raise HTTPError
  // 3. content = parse(res.body)
  // 4. return content
}
```

## Good case

```
def test_fetch_url(){
  // TODO(human)
  // 1. Prepare mock object not to use `request()` directly
  // 2. Prepare url for testing purpose
  // 3. Call fetch_url
  // 4. Confirm the result
}

def fetch_url(url)
{
  // TODO(human)
  // 1. Send request to the URL
  // 2. Check the result of fetching
  // 3. Parse the request body
}
```
