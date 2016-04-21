using Base.Collections

immutable Event
  f::Function
  start::Beat
  args::Vector
end

Event(f, start) = Event(f, start, [])

function Base.isless(e1::Event, e2::Event)
  isless(e1.start, e2.start)
end

@guarded function Base.call(event::Event)
  event.f(event.args...)
end

typealias EventQueue PriorityQueue{Event, Time}
EventQueue() = PriorityQueue(Event, Time)

type EventList
  events::EventQueue
  pending_events::Vector{Event}
  beat::Beat
  tempo::Tempo
end

EventList(tempo::Tempo) = EventList(Event[], tempo)

function EventList(events::Vector{Events}=Event[], tempo::Tempo=60.0)
  pq = EventQueue()
  for e in events
    pq[e] = e.start
  end
  EventList(pq, Event[], 0.0, tempo)
end

Base.append!(eventlist::EventList, events::Vector{Event}) = append!(eventlist.pending_events, events)
Base.push!(eventlist::EventList, event::Event) = push!(eventlist.pending_events, event)
Base.empty!(eventlist::EventList) = empty!(eventlist.events)
Base.isempty(eventlist::EventList) = isempty(eventlist.events)
Base.delete!(eventlist::EventList, event::Event) = delete!(eventlist.events, event)

"Wraps an event with other top-level functions."
function wrap_event(f, pre_args, event::Event)
  args = copy(pre_args)
  push!(args, event)
  Event(f, event.start, args)
end

"Utility function to create a new Event using the same values as the passed-in event and new start time."
alter_event_time(start, event::Event) = Event(event.f, start, event.args)

events(f, args...) = map((xs) -> Event(f, xs...), args)

"Merges pending-events with the PriorityQueue of known events.
Adjusts start times of events to *tempo*."
function merge_pending!(eventlist::EventList)
  events = eventlist.pending_events
  for e in events
    e = alter_event_time(eventlist.beat + e.start, e)
    eventlist.events[e] = e.start
  end
  empty!(events)
end

seconds_to_beats(seconds::Time, tempo::Tempo) = seconds*tempo/60.0
beats_to_seconds(beats::Beat, tempo::Tempo) = 60.0beats/tempo

function Base.call(eventlist::EventList, endtime::Time)
  merge_pending!(eventlist)
  beat = seconds_to_beats(endtime, eventlist.tempo)
  events = eventlist.events
  while length(events) > 0 && peek(events)[2] < beat
    dequeue!(events)()
  end
  eventlist.beat = beat
  !isempty(eventlist)
end
