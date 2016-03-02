using Base.Collections

export Event, EventList, eventlist_tick!

immutable Event
  f
  start
  args
end

typealias EventQueue PriorityQueue{Event, Time}
EventQueue() = PriorityQueue(Event, Time)

type EventList
  events::EventQueue
  pending_events::Vector{Event}
  current_beat::Time
  config::Config
end

function Base.isless(e1::Event, e2::Event)
  isless(e1.start, e2.start)
end

function EventList(config=CONFIG)
  EventList(Event[], config)
end

function EventList(events, config)
  pq = EventQueue()
  for e in events
    pq[e] = e.start
  end
  EventList(pq, Event[], 0.0, config)
end

Base.append!(eventlist::EventList, events::Vector{Event}) = append!(eventlist.pending_events, events)
Base.push!(eventlist::EventList, event::Event) = push!(eventlist.pending_events, event)
Base.empty!(eventlist::EventList) = empty!(eventlist.events)
Base.isempty(eventlist::EventList) = isempty(eventlist.events)
# FIXME
Base.delete!(eventlist::EventList, event::Event) = delete!(eventlist.events, event)

@guarded function fire_event(event::Event)
  event.f(event.args...)
end

"Wraps an event with other top-level functions."
function wrap_event(f, pre_args, event::Event)
  args = copy(pre_args)
  push!(args, event)
  Event(f, event.start, args)
end

"Utility function to create a new Event using the same values as the passed-in event and new start time."
alter_event_time(start, event::Event) = Event(event.f, start, event.args)

events(f, args...) = map((xs) -> Event(f, xs...), args)

"Merges pending-events with the PriorityQueue of known events. Adjusts start times of events to *tempo*."
function merge_pending!(eventlist::EventList)
  while !isempty(eventlist.pending_events)
    # FIXME make atomic
    new_events = copy(eventlist.pending_events)
    empty!(eventlist.pending_events)
    timed_events = map((e::Event) -> alter_event_time(eventlist.current_beat + e.start, e), new_events)
    for e in timed_events
      eventlist.events[e] = e.start
    end
  end
end

seconds_to_beats(seconds, tempo) = seconds * tempo / 60
beats_to_seconds(beats, tempo) = beats * 60 / tempo

function eventlist_tick!(eventlist::EventList)
  merge_pending!(eventlist)
  Δt = seconds_to_beats(eventlist.config.buffer_size/eventlist.config.sample_rate, eventlist.config.tempo)
  end_time = eventlist.current_beat + Δt
  # REVIEW Queue, in, take!
  while length(eventlist.events) > 0 && peek(eventlist.events)[2] < end_time
    fire_event(dequeue!(eventlist.events))
  end
  eventlist.current_beat = end_time
  !isempty(eventlist)
end
