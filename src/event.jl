using Base.Collections

immutable Event
  f::Function
  args::Tuple
end

Event(f) = Event(f, [])

@guarded function Base.call(event::Event)
  event.f(event.args...)
end

#events(f, args...) = map((xs) -> Event(f, xs...), args)

typealias EventQueue PriorityQueue{Event, Time}

EventQueue() = PriorityQueue(Event, Time)

function Base.empty!(q::EventQueue)
  while length(q) > 0
    dequeue!(q)
  end
end

function Base.call(q::EventQueue, endtime::Time)
  while length(q) > 0 && peek(q)[2] < endtime
    dequeue!(q)()
  end
  !isempty(q)
end

Base.schedule(q::EventQueue, start::Time, f::Function, args...) =
  q[Event(f, args)] = start
