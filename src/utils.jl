export Sample, Time, AudioChannel

typealias Sample Nullable{Float64}
typealias Time Float64
typealias AudioChannel Int

function fop(op, f₁::Function, f₂::Function)
  function (τ::Time, ι::AudioChannel)
    x₁ = f₁(τ, ι)
    isnull(x₁) && return Sample()

    x₂ = f₂(τ, ι)
    isnull(x₂) && return Sample()

    Sample(op(get(x₁), get(x₂)))
  end
end

Base.(:+)(f₁::Function, f₂::Function) = fop(+, f₁, f₂)

Base.(:*)(f₁::Function, f₂::Function) = fop(*, f₁, f₂)

function Base.(:*)(a::Float64, f::Function)
  function (τ::Time, ι::AudioChannel)
    x = f(τ, ι)
    isnull(x) && return Sample()
    Sample(a*get(x))
  end
end
