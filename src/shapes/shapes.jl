"""
Abstract idea which defines the external boundary of object.
"""
abstract type Shape{Dim} end

Symmetry(::Shape{Dim}) where {Dim} = WithoutSymmetry{Dim}()

dim(::S) where {Dim,S<:Shape{Dim}} = Dim

"""
    origin(shape::Shape)::SVector

Origin of shape, typically the center
"""
origin(shape::Shape) = shape.origin

"""
    number_type(shape::Shape)::DataType

Number type which is used to describe shape, defaults to the eltype of the origin vector.
"""
number_type(shape::Shape) = eltype(origin(shape))

"""
    Shape(shape::Shape; addtodimensions = 0.0, vector_translation = zeros(...), kws...)

Alter the shape depending on the keywords.
"""
Shape(shape::Shape) = shape

"""
    iscongruent(p1::Shape, p2::Shape)::Bool
    ≅(p1::Shape, p2::Shape)::Bool

True if shapes are the same but in different positions (origins), standard mathematical definition.
"""
iscongruent(s1::Shape, s2::Shape) = false # false by default, overload in specific examples

# Define synonym for iscongruent ≅, and add documentation
≅(s1::Shape, s2::Shape) = iscongruent(s1, s2)
@doc (@doc iscongruent(::Shape, ::Shape)) (≅(::Shape, ::Shape))

"""
    congruent(s::Shape, x)::Shape

Create shape congruent to `s` but with origin at `x`
"""
function congruent end

"Generic helper function which tests if boundary coordinate is between 0 and 1"
function check_boundary_coord_range(t)
    if t < 0 || t > 1
        throw(DomainError("Boundary coordinate must be between 0 and 1"))
    end
end

# Concrete shapes
# include("rectangle.jl")
include("box.jl")
include("sphere.jl")
include("halfspace.jl")
include("plate.jl")
include("time_of_flight.jl")
include("time_of_flight_from_point.jl")
include("empty_shape.jl")

"""
    points_in_shape(Shape; res = 20, xres = res, yres = res,
             exclude_region = EmptyShape(region), kws...)

returns `(x_vec, region_inds)` where `x_vec` is a vector of points that cover a box which bounds `Shape`, and `region_inds` is an array of linear indices such that `x_vec[region_inds]` are points contained `Shape`. For 3D we use `zres` instead of `yres`.

"""
function points_in_shape(region::Shape{2};
        res::Number = 20, xres::Number = res, yres::Number = res,
        exclude_region::Shape = EmptyShape(region),
        kws...) where T

    rect = bounding_box(region)

    #Size of the step in x and y direction
    x_vec_step = rect.dimensions ./ [xres, yres]
    bl = bottomleft(rect)
    x_vec = [SVector{2}(bl + x_vec_step .* [i,j]) for i=0:xres, j=0:yres][:]
    region_inds = findall(x -> !(x ∈ exclude_region) && x ∈ region, x_vec)

    return x_vec, region_inds
end

function points_in_shape(region::Shape{3};
        y = zero(number_type(region)),
        res::Number = 20, xres::Number = res, zres::Number = res,
        exclude_region::Shape = EmptyShape(region))

    box = bounding_box(region)

    #Size of the step in x and z direction
    x_vec_step = [box.dimensions[1] / xres, zero(number_type(region)), box.dimensions[3] / zres]

    bl = corners(box)[1]
    x_vec = [SVector{3}(bl + x_vec_step .* [i,y,j]) for i = 0:xres, j = 0:zres][:]
    region_inds = findall(x -> !(x ∈ exclude_region) && x ∈ region, x_vec)

    return x_vec, region_inds
end


"Returns a set of points on the boundary of a 2D shape."
function boundary_points(shape2D::Shape{2}, num_points::Int = 4; dr = 0)
    T = number_type(shape2D)
    x, y = boundary_functions(shape2D)
    v(τ) = SVector(x(τ),y(τ)) + dr * (SVector(x(τ),y(τ)) - origin(shape2D))
    return [ v(τ) for τ in LinRange(zero(T),one(T),num_points+1)[1:end-1] ]
end

"Returns a set of points on the boundary of a 3D shape."
function boundary_points(shape3D::Shape{3}, num_points::Int = 4; dr = 0)
    T = number_type(shape3D)
    x, y, z = boundary_functions(shape3D)
    v(τ,s) = SVector(x(τ,s),y(τ,s),z(τ,s)) + dr * (SVector(x(τ,s),y(τ,s),z(τ,s)) - origin(shape3D))
    mesh = LinRange(zero(T),one(T),num_points+1)[1:end-1]
    return [v(τ,s) for τ in mesh, s in mesh]
end

"Returns box which completely encloses the shapes"
bounding_box(shape1::Shape, shape2::Shape) = bounding_box([shape1, shape2])

# Create a box which bounds an array of shapes
function bounding_box(shapes::Vector{S}) where S<:Shape
    boxes = bounding_box.(shapes)
    corners_mat = hcat(vcat((corners.(boxes))...)...)

    maxdims = maximum(corners_mat, dims=2)
    mindims = minimum(corners_mat, dims=2)

    c = (maxdims + mindims) ./ 2
    dimensions = maxdims - mindims

    return Box(c[:], dimensions[:])
end

# Docstrings
"""
    name(shape::Shape)::String

Name of a shape
"""
function name end

"""
    outer_radius(shape::Shape)

The radius of a circle which completely contains the shape
"""
function outer_radius end

"""
    volume(shape::Shape)

Volume of a shape
"""
function volume end

"""
    volume(shape::Shape)::NTuple{Function,Dim)

Returns Tuple of Dim Functions which define outer boundary of shape when given boundary coordinate t∈[0,1]
"""
function boundary_functions end

"""
    issubset(shape1, shape2)::Bool

Returns true if shape1 is entirely contained within shape2, false otherwise (also works with particles).
"""
function issubset(s1::Shape,s2::Shape) throw(MethodError(issubset, (s1,s2))) end

"""
    in(vector, shape)::Bool

Returns true if vector is in interior of shape, false otherwise.
"""
function in(::AbstractVector,::Shape) end
