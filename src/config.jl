immutable Config
  samplerate::Int
  buffersize::Int
  inchannels::Int
  outchannels::Int
  tempo::Float64
end

Config() = Config(44100, 1024, 0, 2, 60.0)

"Default config"
CONFIG = Config()
