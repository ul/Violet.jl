immutable Config
  samplerate::Int
  buffersize::Int
  inchannels::Int
  outchannels::Int
  tempo::Tempo
  port::Int
end

Config() = Config(44100, 1024, 0, 2, 60.0, 31337)

"Default config"
CONFIG = Config()
