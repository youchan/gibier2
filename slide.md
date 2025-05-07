# ruby.wasmでシンセサイザーをつくる方法 {#cover}

%author: Yoh Osaki a.k.a @youchan
![icon](images/youchan_square.jpeg)

## Who am I

- youchan
- ANDPAD Inc.
- Author of [Gibier2](https://github.com/youchan/gibier2)
- RubyKaigi 2025
  - 「dRuby on Browser Again!」

# 今日はアナログシンセサイザーの話をします

## 私のヒーロー

![keith_emerson](images/keith_emerson.jpg)

%center: キース・エマーソン

## Moog シンセサイザー {#moog}

What's moog

- アナログシンセサイザーの元祖的な存在
- モジュラーシンセサイザー
- 箪笥

![right](images/moog.jpeg)

## アナログシンセサイザー

![analog_synth](images/analog_synth.png)

%center: すべて電圧で制御されるアナログの電子回路

## デジタル時代のシンセサイザー

- FM音源
- サンプリング
- 物理モデリング
- アナログモデリング

![DX7](images/YAMAHA_DX7.jpg)

## なぜアナログなのか？

- デジタルならばどんな音も作れてしまう
  - 生楽器の音を再現することに関してはかなり近づいている
  - 現在のデジタルシンセサイザーはハイブリッド
- シンセサイザーの楽器としての音とは何か？
  - 制約のあるアナログシンセサイザーのシンセサイザーらしさ
  - チップチューンがひとつの分野を築いている
  - もちろんデジタルシンセサイザーの音というのもある。FM音源とか80's

# Demo

%center: アナログシンセサイザーっぽい音

## アナログシンセサイザーを作る {#demo}

- 実際はアナログモデリングシンセサイザーです
- Gibier2で動く！
  - もしかしたら世界初のシンセサイザー搭載のプレゼンツールかも
- モジュラー構造で拡張可能
- Web Audio APIでブラウザで動く
- ruby.wasmでRubyで実装する
- 参考
  - [websynthv2](https://aikelab.net/websynthv2/)
  - [https://www.g200kg.com/jp/docs/webaudio/index.html](https://www.g200kg.com/jp/docs/webaudio/index.html)

## Gibier Synth

![gibier_synth](images/gibier_synth.png)

## Web Audio API

VCO

```javascript
let context = new AudioContext();
let oscillator = context.createOscillator();
```

VCF

```javascript
let filter = context.createBiquadFilter();
```

VCA

```javascript
let gain = context.createGain();
```

## ruby.wasm

VCO

```ruby
context = JS.global[:AudioContext].new
oscillator = context.createOscillator()
```

VCF

```ruby
filter = context.createBiquadFilter()
```

VCA

```ruby
gain = context.createGain()
```

## Synthesizer class

```ruby
class Synthesizer
  CCLASSES = {
    'vca' => VCA,
    'vco' => VCO,
    'vcf' => VCF,
    'noise_generator' => NoiseGenerator,
    'eg' => EG
  }

  def initialize(audio, nodes)
    @audio_nodes = {}
    outputs_table = {}
    nodes.each do |node|
      @audio_nodes[node['name']] = CCLASSES[node['type']].new(audio, node || {})
      outputs_table[node['name']] = node['outputs'] if node['outputs']
    end
    # ...snip
  end
end
```

## Synthesizer params

```yaml
synthesizer:
  - 
    type: vco
    name: vco
    outputs:
      - vca
  - 
    type: vca
    name: vca
    outputs:
      - .destination
  - 
    type: eg
    name: eg
    attack: 0.1
    #...snip
    outputs:
      - vca.gain

```

## AudioParam

- Web Audio APIの`AudioParam`クラス
- EG(Envelop Generator)に使用
- Web Audio APIは各種パラメータが`AudioParam`として表わされている

```ruby
class EG
  def note_on
    crrent_time = @audio.context[:currentTime].to_f
    @audio_param.setTargetAtTime(@max, current_time, @attack)
    @audio_param.setTargetAtTime(@sustain, current_time + @attack, @decay)
  end

  def note_off
    @audio_param.setTargetAtTime(0.0, @audio.context[:currentTime], @release)
  end
end
```

## Sequencer

- シーケンサーは音程と長さだけ
- JSの`setTimeout`で実現している => インターバルを短かくすると不安定になる
- すべて`AudioParam`で制御してもよかったかもしれないがモジュール構成との共存が難しい

```yaml
sequencer:
  tempo: 145
  tracks:
  - 
    name: track1
    notes: 
      [69, 2, 69, 2, 67, 1, 72, 2, 65, 4, 60, 1, 62, 1, 64, 2, 55, 17, ...]
    cv_out:
      - vco1
    gate_out:
      - eg1
      - eg2
```

# Demo

## Asakusa.rb {#ruby_tuesday}

%center: Asakusa.rbから来ました。Ruby Tuesdayに活動しています。

![asakusa](images/asakusa.png)

## もっとつくりたかったものたち

- MIDI入力
- FM音源
- 音声ファイルの再生
  - 効果音
  - ドラム音源
- 音声のビジュアライズ
  - スペクトル
  - 波形
  - ビジュアルエフェクト
- ボコーダー
- エディター

---

まだまだ開発したいものがいっぱい！！！
otoイベントの次回も期待しています！
