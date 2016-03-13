module ECS

export World, WORLD, Component, entities, Entity

typealias Entity Symbol
typealias Entities Set{Entity}

abstract Component
typealias ComponentType{T<:Component} Type{T}

typealias Component2Instance Dict{ComponentType, Component}
typealias Entity2Components Dict{Entity, Component2Instance}
typealias Component2Entities Dict{ComponentType, Entities}

type World
  entity2components::Entity2Components
  component2entities::Component2Entities
end

const WORLD = World(Entity2Components(), Component2Entities())

function Base.convert{T<:Component}(t::Type{T}, e::Entity, world=WORLD)
  world.entity2components[e][t]
end

function Base.in{T<:Component}(t::Type{T}, e::Entity, world=WORLD)
  haskey(world.component2entities, t) && e in world.component2entities[t]
end

function Base.push!(c::Component, e::Entity, world=WORLD)
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

function Base.delete!{T<:Component}(t::Type{T}, e::Entity, world=WORLD)
  delete!(world.entity2components[e], t)
  delete!(world.component2entities[t], e)
end

function Entity(components::Vector{Component}, world=WORLD)
  e = gensym()
  for c in components
    push!(c, e, world)
  end
  e
end

function Base.delete!(e::Entity, world=WORLD)
  ts = keys(world.entity2components[e])
  delete!(world.entity2components, e)
  for t in ts
    delete!(world.component2entities[t], e)
  end
end

function entities{T<:Component}(t::Type{T}, world=WORLD)
  if haskey(world.component2entities, t)
    world.component2entities[t]
  else
    Entities()
  end
end

call{T<:Component}(e::Entity, t::Type{T}, world=WORLD) = convert(t, e, world)

end
  
