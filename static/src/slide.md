# ブラウザで動くRubyをどう選ぶか?{#cover}

%author: Yoh Osaki a.k.a @youchan
![icon](images/youchan_square.jpeg)

## Who am I

- youchan
- ANDPAD Inc.
- Author of [Gibier2](https://github.com/youchan/gibier2)
- RubyKaigi
  - Writing web application in Ruby (2015)
  - Isomorphic web programming in Ruby (2016)
  - dRuby on Browser (2017)
  - dRuby on Browser Again! (2025)

![cat](images/cat.jpg)

## Gibier2

- このスライドツール
- ruby.wasmで実装
- dRubyを使っている

## RubyKaigi2025

![druby_on_browser_again](images/dRuby-on-Browser-Again.png)

## dRuby on Browser Again!

- RubyKaigi2025
- ruby.wasmでブラウザ上にdRubyを実装
- Gibier2
  - ruby.wasmで実装
- [https://rubykaigi.org/2025/presentations/youchan.html](https://rubykaigi.org/2025/presentations/youchan.html)

---

![thinking_face](images/think.png)

# ブラウザで動くRubyをどう選ぶか?

## RubyKaigi2017

![druby_on_browser](images/dRuby-on-Browser.png)

## dRuby on Browser

- RubyKaigi2017
- Opalでブラウザ上にdRubyを実装
- Gibier (version 1)
  - Opalで実装

---

![ruby_wasm_vs_opal](images/ruby.wasm_vs_opal.png)

## ruby.wasm

- WebAssembly(wasm)で動く
- CRubyをwasmにコンパイル
  - CRubyとの互換性が高い
- gemがつかえる、native extensionも使える
  - Gibier2ではmarkly(cmark-gfm)というmarkdownパーサーを使っている

## Opal

- Rubyで書かれたプログラムをJavaScriptに変換する
- JavaScriptとの親和性は高い
  - CRubyとの互換性の問題
- CRubyのgemが使えないことが多い
  - Gibierではサーバーサイドでmarkdownをパース

## Pros/Cons

**ruby.wasm**
- フットプリント-> 大
- 実行速度 -> 速
- ビルドやパッキングが必要

**Opal**
- フットプリント-> 小
- 実行速度 -> 遅
- sprocketでコンパイルされるので特別な操作は不要
  - webpack化などの議論も進んでいる

## CRubyとの互換性

**ruby.wasm**
- 基本的にCRubyと同じものが動く
- ただし、wasmのランタイムの制約を受ける
  - ファイルシステム、ネットワーク、スレッド
- wasmの制約を受けないものであればnative extensionもつかえる

**Opal**
- プリミティブな型はJavaScriptの値をバインドする
- JavaScriptの制約を受ける
- gemは専用に書くのが無難

## JavaScriptとの親和性

**ruby.wasm**
- wasmの世界で動くのでJSのコードの実行は環境の間の行き来が起こる
- 特に非同期処理で問題が起きる
- JSとの値の受け渡しで型の変換が必要

**Opal**
- プリミティブな型はそのままJavaScriptと可換
- 非同期処理を自然に書ける

## どう使い分けるべきか？

- JavaScriptの代わりに使うような普通のWebフロントエンド開発にはOpal
- 実行速度が必要な箇所にピンポイントにruby.wasmを使う
- どうしても使いたいgemがある場合にruby.wasmを使う
- いずれにしてもruby.wasmを使えばロード時間の問題があるので、ローカルで使うようなアプリが向いている
- ruby.wasmはゲーム開発にも向いてますね！

# Happy Hacking!
