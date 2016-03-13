immutable Config
  sample_rate::Int
  buffer_size::Int
  input_channels::Int
  output_channels::Int
  tempo::Float64
end

Config() = Config(44100, 1024, 0, 2, 60.0)

"Default config"
CONFIG = Config()
