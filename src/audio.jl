include("PortAudio.jl")
include("config.jl")

using PortAudio

function audiostream(config=CONFIG)
  devID = convert(PaDeviceIndex, -1)
  audiostream = open(devID, (config.input_channels, config.output_channels),
    config.sample_rate, config.buffer_size)
  start_stream(audiostream)
  audiostream
end

function Base.kill(audiostream::PaStreamWrapper)
  stop_stream(audiostream)
  close(audiostream)
end

PortAudio.initialize()
server = listen(31337)
stream = audiostream()

function clean()
  kill(stream)
  PortAudio.terminate()
end

atexit(clean)

@async while true
  flush(stream)
  sleep(0)
end

while true
  sock = convert(IO, accept(server))
  @async while isopen(sock)
    write(stream, deserialize(sock))
    sleep(0)
  end
end
