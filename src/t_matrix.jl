
"""
Returns a 2M+1 by 2M+1 T-matrix for particle with specific shape, physical
properties in a medium with a specific physical property at a specific angular
wavenumber.
"""
function t_matrix(shape::Shape{T}, inner_medium::PhysicalProperties{Dim,FieldDim,T}, outer_medium::PhysicalProperties{Dim,FieldDim,T}, ω::T, M::Integer)::AbstractMatrix{T} where {Dim,FieldDim,T<:AbstractFloat}
    # Returns error unless overloaded for specific type
    error("T-matrix function is not yet written for $(name(inner_medium)) $(name(shape)) in a $(name(outer_medium)) medium")
end

"""
Returns vector of T-matrices from a vector of particles in a specific domain.
Can save computation if multiple of the same kind of particle are present in the
vector.
"""
function get_t_matrices(medium::PhysicalProperties, particles::Vector, ω::AbstractFloat, Nh::Integer)::Vector

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
            if congruent(p, cp)
                t_matrices[p_i] = unique_t_matrices[cp_i]
                found = true
                break
            end
        end

        # Congruent particle was not found, we must calculate this t-matrix
        if !found
            t_matrices[p_i] = t_matrix(p.shape, p.medium, medium, ω, Nh)
            push!(unique_particles, particles[p_i])
            push!(unique_t_matrices, t_matrices[p_i])
        end

    end

    return t_matrices
end

# T-matrix for a 2D circlular acoustic particle in a 2D acoustic medium
function t_matrix(circle::Circle{T}, inner_medium::Acoustic{2,T}, outer_medium::Acoustic{2,T}, ω::T, M::Integer)::Diagonal{Complex{T}} where T<:AbstractFloat

    # Check for material properties that don't make sense or haven't been implemented
    if isnan(inner_medium.c*inner_medium.ρ)
        throw(DomainError("Scattering from a particle with zero density or zero phase speed is not defined"))
    elseif isnan(outer_medium.c*outer_medium.ρ)
        throw(DomainError("Wave propagation in a medium with zero density or zero phase speed is not defined"))
    elseif iszero(outer_medium.c)
        throw(DomainError("Wave propagation in a medium with zero phase speed is not defined"))
    elseif iszero(outer_medium.ρ) && iszero(inner_medium.c*inner_medium.ρ)
        throw(DomainError("Scattering in a medium with zero density from a particle with zero density or zero phase speed is not defined"))
    elseif iszero(circle.radius)
        throw(DomainError("Scattering from a circle of zero radius is not implemented yet"))
    end

    "Returns a ratio used in multiple scattering which reflects the material properties of the particles"
    function Zn(m::Integer)::Complex{T}
        m = T(abs(m))
        ak = circle.radius*ω/outer_medium.c

        # set the scattering strength and type
        if isinf(inner_medium.c) || isinf(inner_medium.ρ)
            numer = diffbesselj(m, ak)
            denom = diffhankelh1(m, ak)
        elseif iszero(outer_medium.ρ)
            γ = outer_medium.c/inner_medium.c #speed ratio
            numer = diffbesselj(m, ak) * besselj(m, γ * ak)
            denom = diffhankelh1(m, ak) * besselj(m, γ * ak)
        else
            q = (inner_medium.c*inner_medium.ρ)/(outer_medium.c*outer_medium.ρ) #the impedance
            γ = outer_medium.c/inner_medium.c #speed ratio
            numer = q * diffbesselj(m, ak) * besselj(m, γ * ak) - besselj(m, ak)*diffbesselj(m, γ * ak)
            denom = q * diffhankelh1(m, ak) * besselj(m, γ * ak) - hankelh1(m, ak)*diffbesselj(m, γ * ak)
        end

        return numer / denom
    end

    # Get Zns for positive m
    Zns = map(Zn,0:M)

    return Diagonal(vcat(reverse(Zns), Zns[2:end]))
end
