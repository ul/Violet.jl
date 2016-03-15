typealias Sample Nullable{Float64}
typealias Time Float64
typealias AudioChannel Int
typealias AudioSignal Function
typealias AudioControl Union{AudioSignal,
                             Signal{Float64},
                             Signal{Array{Float64}},
                             Float64}
