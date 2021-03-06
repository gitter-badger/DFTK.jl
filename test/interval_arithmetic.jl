import Base: cbrt
import DFTK: determine_grid_size
using Test
using DFTK
using IntervalArithmetic
using SpecialFunctions

include("testcases.jl")

# Monkey-patch cbrt for Intervals ... should be done more properly by changing
# the rounding mode ...
# TODO Remove this once https://github.com/JuliaIntervals/IntervalArithmetic.jl/issues/310
#      is dealt with.
cbrt(i::Interval) = Interval(prevfloat(cbrt(i.lo)), nextfloat(cbrt(i.hi)))
SpecialFunctions.erfc(i::Interval) = Interval(prevfloat(erfc(i.lo)), nextfloat(erfc(i.hi)))

function determine_grid_size(lattice::AbstractMatrix{T}, Ecut;
                             kwargs...) where T <: Interval
    # This is done to avoid a call like ceil(Int, ::Interval)
    # in the above implementation of determine_grid_size,
    # where it is in general cases not clear, what to do.
    # In this case we just want a reasonable number for Gmax,
    # so replacing the intervals in the lattice with
    # their midpoints should be good.
    determine_grid_size(mid.(lattice), Ecut; kwargs...)
end

function discretised_hamiltonian(T, testcase)
    Ecut = 10  # Hartree

    spec = ElementPsp(testcase.atnum, psp=load_psp(testcase.psp))
    atoms = [spec => testcase.positions]
    model = model_DFT(Array{T}(testcase.lattice), atoms, [:lda_x, :lda_c_vwn])
    kpoints, ksymops = bzmesh_uniform([1, 1, 1.])

    # For interval arithmetic to give useful numbers,
    # the fft_size should be a power of 2
    fft_size = nextpow.(2, determine_grid_size(model.lattice, Ecut))
    basis = PlaneWaveBasis(model, Ecut, kpoints, ksymops, fft_size=fft_size)

    ham = Hamiltonian(basis; ρ=guess_density(basis))
end


@testset "Application of an LDA Hamiltonian with Intervals" begin
    T = Float64
    ham = discretised_hamiltonian(T, silicon)
    hamInt = discretised_hamiltonian(Interval{T}, silicon)

    hamk = ham.blocks[1]
    hamIntk = hamInt.blocks[1]

    x = randn(Complex{T}, length(G_vectors(ham.basis.kpoints[1])))
    ref = hamk * x
    res = hamIntk * Interval.(x)

    # Difference between interval arithmetic and normal application less than 1e-12
    @test maximum(mid, abs.(res .- ref)) < 1e-10

    # Maximal error done by interval arithmetic less than
    @test maximum(radius, abs.(res)) < 1e-10
end
