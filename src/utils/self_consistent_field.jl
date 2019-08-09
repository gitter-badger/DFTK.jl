"""
    self_consistent_field(ham::Hamiltonian, n_bands::Int, n_electrons::Int;
                          ρ=nothing, tol=1e-6, max_iter=100, algorithm=:scf_nlsolve,
                          lobpcg_prec=PreconditionerKinetic(ham, α=0.1))

Run a self-consistent field iteration for the Hamiltonian `ham`, returning the
self-consistnet density, Hartree potential values and XC potential values.
`n_bands` selects the number of bands to be computed, `n_electrons` the number of
electrons, `ρ` is the initial density, e.g. constructed via a SAD guess.
`lobpcg_prec` specifies the preconditioner used in the LOBPCG algorithms used
for diagonalisation. Possible `algorithm`s are `:scf_nlsolve` or `:scf_damped`.
"""
function self_consistent_field(ham::Hamiltonian, n_bands::Int, n_electrons::Int;
                               ρ=nothing, tol=1e-6,
                               lobpcg_prec=PreconditionerKinetic(ham, α=0.1),
                               max_iter=100, algorithm=:scf_nlsolve, damping=0.2, m=5, den_scaling = 0.0)
    function compute_occupation(basis, energies, Psi)
        occupation_zero_temperature(basis, energies, Psi, n_electrons)
    end
    if ρ === nothing
        ρ = guess_hcore(ham, n_bands, compute_occupation, lobpcg_prec=lobpcg_prec)
    end
    if algorithm == :scf_nlsolve
        fp_solver = scf_nlsolve_solver(m)
    elseif algorithm == :scf_anderson
        fp_solver = scf_anderson_solver(m)
    elseif algorithm == :scf_CROP
        fp_solver = scf_CROP_solver(m)
    elseif algorithm == :scf_damped
        fp_solver = scf_damping_solver(damping)
    else
        error("Unknown algorithm " * string(algorithm))
    end
    res = scf(ham, n_bands, compute_occupation, ρ, fp_solver, tol=tol,
              lobpcg_prec=lobpcg_prec, max_iter=max_iter, den_scaling=den_scaling)

    res
end
