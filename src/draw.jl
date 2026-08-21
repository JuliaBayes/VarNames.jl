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

function Base.show(io::IO, ::MIME"text/plain", draw::Draw)
    printstyled(io, "VarNames.Draw"; bold=true)
    print(io, "\n ├─ ")
    prms, extrs = parameters(draw), extras(draw)
    if isempty(prms)
        printstyled(io, "parameters"; bold=true)
        println(io, " (empty)")
    else
        printstyled(io, "parameters"; bold=true)
        print(io, "\n │  ")
        vnt_pretty_print(io, prms, " │  ", 0)
        println(io)
    end
    print(io, " └─ ")
    printstyled(io, "extras"; bold=true)
    if isempty(extrs)
        println(io, " (empty)")
    else
        nstats = length(extrs)
        for (index, (name, value)) in enumerate(pairs(extrs))
            print(io, index == nstats ? "\n    └─ " : "\n    ├─ ")
            printstyled(io, name; color=:blue)
            print(io, " = ")
            show(io, value)
        end
    end
    return nothing
end

function Base.:(==)(left::VarNames.Draw, right::VarNames.Draw)
    return parameters(left) == parameters(right) & extras(left) == extras(right)
end

function Base.isequal(left::VarNames.Draw, right::VarNames.Draw)
    return isequal(parameters(left), parameters(right)) &&
           isequal(extras(left), extras(right))
end
