# Shapes and particles

## Existing shapes
The package provides 3 built in basic shapes to put your random particles in,
you can plot them using:
```julia
using MultipleScattering

rectangle = Rectangle([0.0,-1.0],[1.0,2.0])
circle = Circle([-1.0,0.0],1.0)
timeofflight = TimeOfFlight([1.0,0.0],3.0)

using Plots; pyplot()
plot(rectangle, linecolor = :red)
plot!(circle, linecolor = :green)
plot!(timeofflight, linecolor = :blue)
```
![Plot the three shapes](../assets/shapes.png)

Time of flight is a shape which contains shapes from a half space which take at
most `t` time to reach from the listener.

## New shape
If you are feeling very adventurous, you can define your own shape
First you must import the package in order to add to existing functions
```julia
import MultipleScattering

type MyShape <: MultipleScattering.Shape
end
```

To describe the characteristics and behaviour of the function you must define
the following functions:
```julia
MultipleScattering.volume(shape::MyShape) = 0.0

MultipleScattering.name(shape::MyShape) = "MyShape"

MultipleScattering.bounding_box(shape::MyShape) = MultipleScattering.Rectangle()
```

When you have this, you can make use of your shape to generate particles in it