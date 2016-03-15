module UI
using Reactive, SFML, Violet.ECS

export window, Draw

# NOTE: we won't use `able` suffix for component names

type Draw<:Component
  draw::Function
end

type Position<:Component
  position::Signal{Vector2f}
end

function makecircle()
  circle = SFML.CircleShape()

  pos = Signal(Vector2f(500.1, 200))
  updatepos = foreach((x) -> set_position(circle, x), pos)
  set_position(circle, value(pos))

  set_radius(circle, 40)
  set_fillcolor(circle, SFML.red)

  Entity([
    Draw((_, window) -> draw(window, circle)),
    Position(pos)])
end

function window(title::AbstractString, width::Integer, height::Integer)
  mode = VideoMode(width, height)
  ctx = ContextSettings(0, 0, 8, 3, 2)
  w = RenderWindow(mode, title, ctx, window_defaultstyle)
  set_framerate_limit(w, 60)
  w
end

function Base.run(window::RenderWindow, world=WORLD)
  event = SFML.Event()
  makecircle()
  while isopen(window)
    while pollevent(window, event)
      if get_type(event) == EventType.CLOSED
        close(window)
      end
    end
    clear(window, SFML.black)
    for e in entities(Draw)
      e(Draw).draw(e, window)
    end
    display(window)
    sleep(0)
  end
end

end #module
