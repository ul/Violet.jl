include("PortAudio.jl")
include("config.jl")

using PortAudio

function audiostream(config=CONFIG)
  devID = convert(PaDeviceIndex, -1)
  audiostream = open(devID, (config.inchannels, config.outchannels),
    config.samplerate, 1024)
  run(audiostream)
  audiostream
end

PortAudio.initialize()
server = listen(CONFIG.port)
stream = audiostream()

function clean()
  kill(stream)
  close(stream)
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
