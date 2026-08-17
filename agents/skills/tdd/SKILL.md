---
name: tdd
description: ユーザとTDDを実行する。実装を始めるときやplanモードで計画するときに参照する。
---

# TDD

## Overview

- kent beckの提唱するTDDをユーザとともに実行
- ユーザが実行することで学びがある場合に実施する。機械的な置き換えなどの場合は実行不要

## 注意点

- テストリストはClaudeの出力に留めず、`.nunoya_private/test-list.md`に保存する。会話がcompactionされたりセッションが切れたりしても参照できるようにするため
- テストがRedの間は実装を行わない
- 都度細かくストップし、ユーザーに確認をする。ユーザーが理解していることを確認する
- ユーザからの確認があった場合、テストと実装を確認し、修正箇所がある場合にはヒントを出しつつ修正依頼
- Red / Green / Refactor の実際の作業は、このskillの中では行わない。それぞれ専用のコマンド
  `/tdd-red` `/tdd-green` `/tdd-refactor` に委譲する。これらは `disable-model-invocation: true`
  のためユーザーしか呼び出せない。フェーズが完了したら次のフェーズを勝手に進めず、ユーザーが
  対応するコマンドを呼ぶまで待つこと

## 手順

テストリスト作成 -> Red -> Green -> Refactor -> テストリスト更新
を基本とする。

1. ユーザーの実装しようとしている内容、設計について議論して理解する
1. 今後のやるべきTODOリスト、テストリストを作成し、ユーザーに提示する。`.nunoya_private/test-list.md`にも保存する
1. ユーザーに `/tdd-red` の実行を促し、呼ばれるまで待つ(自分から実行しない)
1. ユーザーに `/tdd-green` の実行を促し、呼ばれるまで待つ(自分から実行しない)
1. 必要であればユーザーに `/tdd-refactor` の実行を促し、呼ばれるまで待つ(自分から実行しない)
1. ユーザからの質疑があった場合は完璧な回答を提示するのではなく、ヒントとなるような説明を提供
1. リストが尽きるまで3に戻る

1. テスト、実装が完了したとき、"/code-review"と"/gen-test"を実施、完了後コミット
1. TODOリスト、テストリストの見直しを行う。`.nunoya_private/test-list.md`も更新する

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
