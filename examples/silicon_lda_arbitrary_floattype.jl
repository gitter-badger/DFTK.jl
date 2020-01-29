using PyCall
using DFTK
using Printf
using DoubleFloats

# Calculation parameters
kgrid = [3, 3, 3]
Ecut = 10  # Hartree
T = Double64  # Try Double32, BigFloat (very slow!)

# Setup silicon lattice
a = 10.263141334305942  # Silicon lattice constant in Bohr
lattice = a / 2 .* [[0 1 1.]; [1 0 1.]; [1 1 0.]]
Si = Element(14, psp=load_psp("hgh/lda/Si-q4"))
atoms = [Si => [ones(3)/8, -ones(3)/8]]

# Setup LDA model and discretisation
model = model_dft(Array{T}(lattice), [:lda_x, :lda_c_vwn], atoms)
kpoints, ksymops = bzmesh_ir_wedge(kgrid, lattice, atoms)
basis = PlaneWaveBasis(model, Ecut, kpoints, ksymops)

# Run SCF, note Silicon metal is an insulator, so no need for all bands here
ham = Hamiltonian(basis, guess_density(basis, atoms))
n_bands = 4
scfres = self_consistent_field(ham, n_bands, tol=1e-6)

# Print obtained energies
print_energies(scfres.energies)
@assert eltype(sum(values(energies))) == T