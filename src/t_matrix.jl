"""
Returns a 2M+1 by 2M+1 T-matrix for particle with specific shape, physical
properties in a medium with a specific physical property at a specific angular
wavenumber. See doc/T-matrix.pdf for details.
"""
function t_matrix(p::AbstractParticle{T,Dim}, medium::PhysicalProperties{T,Dim}, ω::T, M::Integer)::AbstractMatrix{T} where {T<:AbstractFloat,Dim}

    error("T-matrix function is not yet written for $(name(p.medium)) $(name(p.shape)) in a $(name(medium)) medium")
end

"""
Returns vector of T-matrices from a vector of particles in a specific domain.
Can save computation if multiple of the same kind of particle are present in the
vector.
"""
function get_t_matrices(medium::PhysicalProperties, particles::AbstractParticles, ω::AbstractFloat, Nh::Integer)::Vector

    t_matrices = Vector{AbstractMatrix}(length(particles))

    # Vector of particles unique up to congruence, and the respective T-matrices
    unique_particles = Vector{AbstractParticle}(0)
    unique_t_matrices = Vector{AbstractMatrix}(0)

    for p_i in eachindex(particles)
        p = particles[p_i]

        # If we have calculated this T-matrix before, just point to that one
        found = false
        for cp_i in eachindex(unique_particles)
            cp = unique_particles[cp_i]
            if iscongruent(p, cp)
                t_matrices[p_i] = unique_t_matrices[cp_i]
                found = true
                break
            end
        end

        # Congruent particle was not found, we must calculate this t-matrix
        if !found
            t_matrices[p_i] = t_matrix(p, medium, ω, Nh)
            push!(unique_particles, particles[p_i])
            push!(unique_t_matrices, t_matrices[p_i])
        end

    end

    return t_matrices
end