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

function unstream(stream)
  kill(stream)
  close(stream)
end

PortAudio.initialize()
server = listen(CONFIG.port)

function clean()
  PortAudio.terminate()
end

atexit(clean)
run(`sudo renice -19 $(getpid())`)

function fork(sock)
  stream = audiostream()
  ok = true
  @async while ok
    flush(stream)
    sleep(0)
  end
  while isopen(sock)
    write(stream, deserialize(sock))
    sleep(0)
  end
  ok = false
  unstream(stream)
end

while true
  sock = convert(IO, accept(server))
  @async fork(sock)
end
