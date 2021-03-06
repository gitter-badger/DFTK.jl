using OrderedCollections
"""
A simple struct to contain a vector of energies, and utilities to print them in a nice format.
"""
struct Energies{T <: Number}
    # energies["TermName"]
    # parametrization on T acts as a nice check that all terms return correct type
    energies::OrderedDict{String, T}
end

function Base.show(io::IO, energies::Energies)
    println("Energy breakdown:")
    for (name, value) in energies.energies
        @printf "    %-20s%-10.7f\n" string(name) value
    end
    @printf "\n    %-20s%-15.12f\n" "total" sum(values(energies))
end
Base.getindex(energies::Energies, i) = energies.energies[i]
Base.values(energies::Energies) = values(energies.energies)
Base.keys(energies::Energies) = keys(energies.energies)
Base.pairs(energies::Energies) = pairs(energies.energies)
Base.iterate(energies::Energies) = iterate(energies.energies)
Base.iterate(energies::Energies, state) = iterate(energies.energies, state)
Base.haskey(energies::Energies, key) = haskey(energies.energies, key)


function Energies(term_types::Vector, energies::Vector{T}) where {T}
    # nameof is there to get rid of parametric types
    Energies{T}(OrderedDict([string(nameof(typeof(term))) => energies[i]
                          for (i, term) in enumerate(term_types)]...))
end
