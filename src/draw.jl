"""
    Draw{P<:VarNamedTuple,S<:NamedTuple}

A struct that bundles a set of parameter values stored as a `VarNamedTuple`, along with a
`NamedTuple` of extra information associated with this set of values (for example, this can
be used to store log-probability values, etc.).

In VarNames.jl, this struct is not used at all; however, it is defined here so that other
packages can dispatch on it easily.
"""
struct Draw{P<:VarNamedTuple,S<:NamedTuple}
    parameters::P
    extras::S
end

"""
    VarNames.parameters(draw::Draw)::VarNamedTuple

Returns the parameters of the draw as a `VarNamedTuple`.
"""
function parameters(draw::Draw)
    return draw.parameters
end

"""
    VarNames.extras(draw::Draw)::NamedTuple

Returns the extra information of the draw as a `NamedTuple`.
"""
function extras(draw::Draw)
    return draw.extras
end
