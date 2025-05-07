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

    def conv(param_name)
      nil
    end

    def output_conv=(conv)
      puts "output_conv #{@name}"
      @output_conv = conv
    end

    def output_conv(val)
      if @output_conv
        @output_conv.call(val)
      else
        val
      end
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
      @node[:type] = params['shape'] if params['shape']
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

    BASE_FREQ = 50.0

    def initialize(audio, params)
      @audio = audio
      @name = params['name']
      @node = audio.context.createBiquadFilter()
      @node[:type] = 'lowpass'
      @amount = params['amount'] || 0.5
      @q = params['q'] || 50.0
      @node[:Q][:value] = @q / 5
      @node[:frequency][:value] = 300.0 + (BASE_FREQ + 30) ** 2 / 10
    end

    def conv(param_name)
      case param_name
      when 'frequency'
        -> (val) {
          freq = [100.0, BASE_FREQ + val * @amount * 100.0].min
          300.0 + 2 ** ((freq + 30) / 10)
        }
      else
        nil
      end
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
      @max = params['max'] || 1.0
      @attack = params['attack'] || 0.01
      @decay = params['decay'] || 0.2
      @sustain = params['sustain'] || 0.5
      @release = params['release'] || 0.01
    end

    def output=(output)
      @audio_param = output
    end

    def note_on
      @audio_param.setTargetAtTime(output_conv(@max), @audio.context[:currentTime], @attack)
      @audio_param.setTargetAtTime(output_conv(@sustain), JS.try_convert(@audio.context[:currentTime].to_f + @attack), @decay)
    end

    def note_off
      @audio_param.cancelScheduledValues(@audio.context[:currentTime])
      @audio_param.setTargetAtTime(output_conv(0.0), @audio.context[:currentTime], @release)
    end
  end


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

      outputs_table.each do |node_name, outputs|
        node = @audio_nodes[node_name]
        outputs.each do |output|
          (mod, param) = output.split('.')
          if mod == nil || mod == ''
            if param == 'destination'
              node.output = audio.destination
            end
          else
            output_node = @audio_nodes[mod]
            if param == nil
              node.output = output_node.node
            else
              node.output = output_node.node[param.to_sym]
              conv = output_node.conv(param)
              node.output_conv = conv if conv
            end
          end
        end
      end

      @audio_nodes.each_value do |node|
        node.start if node.respond_to?(:start)
      end
    end

    def update_cv(cv, cv_out)
      cv_out.each do |node_name|
        @audio_nodes[node_name].update_cv(cv)
      end
    end

    def note_on(gate_out)
      gate_out.each do |node_name|
        @audio_nodes[node_name].note_on
      end
    end

    def note_off(gate_out)
      gate_out.each do |node_name|
        @audio_nodes[node_name].note_off
      end
    end
  end
end
