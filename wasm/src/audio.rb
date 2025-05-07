module Gibier
  module AudioNode
    attr_reader :node

    def update_cv(cv)
    end

    def note_on
    end

    def note_off
    end

    def output=(output)
      @node.connect(output)
    end
  end

  class NoiseGenerator
    include AudioNode

    def initialize(audio, params)
      audio.context[:audioWorklet].addModule("/js/white-noise-processor.js").await
      @node = JS.global[:AudioWorkletNode].new(
        audio.context,
        "white-noise-processor"
      )
    end
  end

  class VCO
    include AudioNode

    def initialize(audio, params)
      @audio = audio
      @node = audio.context.createOscillator()
    end

    def start
      @node.start()
    end

    def update_cv(cv)
      @node[:frequency][:value] = cv
    end
  end

  class VCF
    include AudioNode

    def initialize(audio, params)
      @audio = audio
      @node = audio.context.createBiquadFilter()
    end
  end

  class VCA
    include AudioNode

    def initialize(audio, params)
      @audio = audio
      @node = audio.context.createGain()
      @node[:gain][:value] = params['value'] || 0
    end
  end

  class EG
    include AudioNode

    def initialize(audio, params)
      @audio = audio
      @attack = params['attack'] || 0
      @decay = params['decay'] || 0.2
      @sustain = params['sustain'] || 0.5
      @release = params['release'] || 0
    end

    def output=(output)
      @audio_param = output
    end

    def note_on
      @audio_param[:value] = 0
      @audio_param.linearRampToValueAtTime(1, JS.try_convert(@audio.context[:currentTime].to_f + @attack))
      @audio_param.exponentialRampToValueAtTime(@sustain, JS.try_convert(@audio.context[:currentTime].to_f + @attack + @decay))
    end

    def note_off
      @audio_param.linearRampToValueAtTime(0, JS.try_convert(@audio.context[:currentTime].to_f + @release))
    end
  end

  class Synthesizer
    CCLASSES = {
      'vca' => VCA,
      'vco' => VCO,
      'noise_generator' => NoiseGenerator,
      'eg' => EG
    }

    def initialize(audio, params)
      @audio_nodes = {}
      outputs = {}
      params['synthesizer'].each do |node|
        @audio_nodes[node['name']] = CCLASSES[node['type']].new(audio, node['params'] || {})
        outputs[node['name']] = node['outputs']
      end

      outputs.each do |node_name, outputs|
        outputs.each do |output|
          (mod, param) = output.split('.')
          if mod == nil || mod == ''
            if param == 'destination'
              @audio_nodes[node_name].output = audio.destination
            end
          elsif param == nil
            @audio_nodes[node_name].output = @audio_nodes[mod].node
          else
            @audio_nodes[node_name].output = @audio_nodes[mod].node[param.to_sym]
          end
        end
      end

      @audio_nodes.each_value do |node|
        node.start if node.respond_to?(:start)
      end
    end

    def update_cv(cv)
      puts "update_cv: #{cv}"
      @audio_nodes.each_value do |node|
        node.update_cv(cv)
      end
    end

    def note_on
      @audio_nodes.each_value do |node|
        node.note_on
      end
    end

    def note_off
      @audio_nodes.each_value do |node|
        node.note_off
      end
    end
  end

  class Audio
    CONCERT_A_FREQ = 440;
    CONCERT_A_NOTENUM = 69;
    NOTES = [60, 62, 64, 65, 67, 69, 71, 72]

    attr_reader :context

    def initialize
      @context = JS.global[:AudioContext].new
    end

    def start(params)
      @synth = Synthesizer.new(self, params)

      @notes = []

      interval = JS.global.setInterval(-> {
        Fiber.new do
          note = @notes.shift
          @synth.note_off
          if note
            @synth.update_cv(convert_to_frequency(note))
            @synth.note_on
          end
          nil
        end.transfer
      }, 500)
    end

    def destination
      @context[:destination]
    end

    def convert_to_frequency(notenum)
      from_concert_a = notenum - CONCERT_A_NOTENUM;

      # 十二平均律では2音の最小の周波数差は`2^(1/12)`となる  
      JS.try_convert((2 ** (from_concert_a / 12.0)) * CONCERT_A_FREQ)
    end

    def play
      @notes.clear
      NOTES.each do |note|
        @notes << note
      end
    end
  end
end
