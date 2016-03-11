module ECS

export World, WORLD, Component, entities, Entity

typealias Entity Symbol
typealias Entities Set{Entity}

abstract Component

#typealias Component2Instance Dict{Type{Component}, Component}
typealias Component2Instance Dict{Any, Component}
typealias Entity2Components Dict{Entity, Component2Instance}
#typealias Component2Entities Dict{Type{Component}, Entities}
typealias Component2Entities Dict{Any, Entities}

type World
  entity2components::Entity2Components
  component2entities::Component2Entities
end

const WORLD = World(Entity2Components(), Component2Entities())

function Base.convert{T<:Component}(world::World, t::Type{T}, e::Entity)
  world.entity2components[e][t]
end

Base.convert{T<:Component}(t::Type{T}, e::Entity) = convert(WORLD, t, e)

function Base.in{T<:Component}(world::World, t::Type{T}, e::Entity)
  haskey(world.component2entities, t) && e in world.component2entities[t]
end

Base.in{T<:Component}(t::Type{T}, e::Entity) = in(WORLD, t, e)

function Base.push!(world::World, c::Component, e::Entity)
  t = typeof(c)
  if haskey(world.entity2components, e)
    world.entity2components[e][t] = c
  else
    world.entity2components[e] = Component2Instance(t => c)
  end
  if !haskey(world.component2entities, t)
    world.component2entities[t] = Entities()
  end
  push!(world.component2entities[t], e)
end

Base.push!(c::Component, e::Entity) = push!(WORLD, c, e)

function Base.delete!{T<:Component}(world::World, t::Type{T}, e::Entity)
  delete!(world.entity2components[e], t)
  delete!(world.component2entities[t], e)
end

Base.delete!{T<:Component}(t::Type{T}, e::Entity) = delete!(WORLD, t, e)

function Entity(world::World, components::Vector{Component})
  e = gensym()
  for c in components
    push!(world, c, e)
  end
  e
end

Entity(components::Vector{Component}) = Entity(WORLD, components)

function Base.delete!(world::World, e::Entity)
  ts = keys(world.entity2components[e])
  delete!(world.entity2components, e)
  for t in ts
    delete!(world.component2entities[t], e)
  end
end

Base.delete!(e::Entity) = delete!(WORLD, e)

function entities{T<:Component}(world::World, t::Type{T})
  world.component2entities[t]
end

entities{T<:Component}(t::Type{T}) = entities(WORLD, t)

call{T<:Component}(e::Entity, t::Type{T}) = convert(t, e)

end
