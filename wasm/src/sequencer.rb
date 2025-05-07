module Gibier
  class Sequencer
    def initialize(audio, params)
      tempo = params['tempo'] || 120
      @interval_milisec = 1000.0 * 60 / tempo / 2
      puts "interval_milisec = #{@interval_milisec}"

      @tracks = params['tracks'].map do |track_params|
        Track.new(audio, track_params)
      end

      @callbacks = @tracks.map(&:callback)
    end

    def note_off_timing(milisec)
      JS.global.setTimeout(-> {
        @callbacks.each do |cb|
          cb.call(false)
        end
      }, milisec)
    end

    def interval_func(offset)
      JS.global.setTimeout(-> {
        Fiber.new do
          prev = JS.global[:Date].now().valueOf().to_i

          note_off_timing(@interval_milisec * 0.8)

          @callbacks.each do |cb|
            cb.call(true)
          end

          now = JS.global[:Date].now().valueOf().to_i

          interval_func(now - prev) unless @stop
        end.transfer
      }, @interval_milisec - offset)
    end

    def start
      @stop = false
      interval_func(0)
    end

    def stop
      @stop = true
      @tracks.each(&:stop)
    end
  end

  class Track
    CONCERT_A_FREQ = 440;
    CONCERT_A_NOTENUM = 69;

    def initialize(audio, params)
      @synth = audio.synth
      @notes = params['notes'].clone
      @cv_out = params['cv_out'] || []
      @gate_out = params['gate_out'] || []
    end

    def convert_to_frequency(notenum)
      from_concert_a = notenum - CONCERT_A_NOTENUM;

      # 十二平均律では2音の最小の周波数差は`2^(1/12)`となる  
      JS.try_convert((2 ** (from_concert_a / 12.0)) * CONCERT_A_FREQ)
    end

    def callback
      count = 0
      length = 0

      -> (on) {
        if on
          if count == 0
            note = @notes.shift
            if note
              length = @notes.shift - 1
              @synth.update_cv(convert_to_frequency(note), @cv_out) unless note == 0
              @synth.note_on(@gate_out) unless note == 0
            else
              length = 0
            end
          end
          count += 1
          count = 0 if count > length
        else
          if count == length
            @synth.note_off(@gate_out)
          end
        end
        nil
      }
    end

    def stop
      @synth.note_off(@gate_out)
    end
  end
end
