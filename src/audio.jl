include("PortAudio.jl")
include("config.jl")

using PortAudio

function init(port=31337,
              input_channels=CONFIG.input_channels,
              output_channels=CONFIG.output_channels,
              sample_rate=CONFIG.sample_rate,
              buffer_size=CONFIG.hardware_buffer_size)
  global gport = port

  PortAudio.initialize()

  devID = convert(PaDeviceIndex, -1)
  global audiostream = open(devID,
                            (input_channels, output_channels),
                            sample_rate, buffer_size)
  global stream = convert(IO, connect(port))
  start_stream(audiostream)
end

function clean()
  close(stream)
  stop_stream(audiostream)
  close(audiostream)
  PortAudio.terminate()
end

atexit(clean)

function run()
  @async while true
    flush(audiostream)
    yield()
  end

  reconnect = false
  while true
    try
      if reconnect
        global stream = convert(IO, connect(gport))
        reconnect = false
      end
      write(audiostream, deserialize(stream))
    catch
      sleep(1)
      reconnect = true
    end
  end
end

init(map((x) -> parse(Int, x), ARGS)...)
run()
