using Reactive, GLAbstraction, Colors, GeometryTypes, GLVisualize

include("config.jl")
include("circularbuffer.jl")

maxscreenwidth = 4000

function init(port=31337,
              buffer_size=CONFIG.hardware_buffer_size)
  global gport = port
  global window = glscreen()
  global buffer = CircularBuffer(Float32, maxscreenwidth)
  global stream = convert(IO, connect(port))
  clock = fps(60)
  points = map(clock, window.inputs[:window_size]) do clock, size
    y₀ = size[2]/2
    n = buffer.write_cursor - size[1]
    if n < 0
      n += maxscreenwidth
    end
    Point2f0[(i - 1, y₀*(1 + buffer[i + n])) for i=1:size[1]]
  end
  view(visualize(points, :lines))
end

function clean()
  close(stream)
end

atexit(clean)

function run()
  @async renderloop(window)
  reconnect = false
  while true
    try
      if reconnect
        global stream = convert(IO, connect(gport))
        reconnect = false
      end
      append!(buffer, deserialize(stream))
    catch
      sleep(1)
      reconnect = true
    end
  end
end

init(map((x) -> parse(Int, x), ARGS)...)
run()
