require_relative 'synthesizer'
require_relative 'sequencer'

module Gibier
  class Audio
    attr_reader :context
    attr_reader :synth

    def initialize(params)
      @context = JS.global[:AudioContext].new

      if params['synthesizer']
        @synth = Gibier::Synthesizer.new(self, params['synthesizer'])
      end

      if params['sequencer']
        @sequencer = Gibier::Sequencer.new(self, params['sequencer'])
      end
    end

    def destination
      @context[:destination]
    end

    def play
      @sequencer.start
    end

    def stop
      @sequencer.stop
    end
  end
end
