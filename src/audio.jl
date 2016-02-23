include("PortAudio.jl")
include("config.jl")

using PortAudio

function init(port=31337,
              input_channels=CONFIG.input_channels,
              output_channels=CONFIG.output_channels,
              sample_rate=CONFIG.sample_rate,
              buffer_size=CONFIG.hardware_buffer_size)
  PortAudio.initialize()

  devID = convert(PaDeviceIndex, -1)
  global audiostream = open(devID,
                            (input_channels, output_channels),
                            sample_rate, buffer_size)
  global server = listen(port)
  start_stream(audiostream)
end

function clean()
  close(server)
  stop_stream(audiostream)
  close(audiostream)
  PortAudio.terminate()
end

atexit(clean)

function run()
  @async while true
    flush(audiostream)
  end

  while true
    stream = convert(IO, accept(server))
    @async while isopen(stream)
      write(audiostream, deserialize(stream))
    end
  end
end

init(map((x) -> parse(Int, x), ARGS)...)
run()
