"""
VarNamesDistributionsExt

This extension provides extra methods for `hasvalue` and `getvalue`,
specifically, to deal with cases where a dictionary may not have mappings for
*complete* variables (e.g. `x` where `x` is a vector or matrix), but may have
mappings for *individual elements* of that variable.

In such a case, it is necessary to verify that all elements of that variable
are present in the dictionary. Doing this requires some knowledge of the shape
of `x`, which in this extension, is inferred from the distribution that `x` is
to be sampled from, leading to these two methods:

    getvalue(vals, vn, dist)
    hasvalue(vals, vn, dist)

The functionality in this extension should, in general, not be used unless
absolutely necessary. For example, if the dictionary was provided by a user,
the user should be expected to provide a single value for `x` rather than
individual elements. To accomplish this, the original two-argument
implementations

    getvalue(vals, vn)
    hasvalue(vals, vn)

should be used.

This extension primarily exists because in MCMCChains.jl, each individual
element of `x` will be stored separately. Information about the original shape
of `x` is lost once a `Chains` object has been created. Thus, reconstructing
the original values of `x` requires the use of the three-argument methods in
this extension.
"""
module VarNamesDistributionsExt

using VarNames
using Distributions: Distributions, Distribution, LKJCholesky
using Accessors: Accessors
using LinearAlgebra: Cholesky, LowerTriangular, UpperTriangular

"""
    get_optics(dist::MultivariateDistribution)
    get_optics(dist::MatrixDistribution)
    get_optics(dist::LKJCholesky)

Return a complete set of optics for each element of the type returned by `rand(dist)`.
"""
function get_optics(
    dist::Union{Distributions.MultivariateDistribution,Distributions.MatrixDistribution},
)
    indices = CartesianIndices(size(dist))
    return map(idx -> Index(idx.I, (;), Iden()), indices)
end
function get_optics(dist::Distributions.LKJCholesky)
    is_up = dist.uplo == 'U'
    cartesian_indices = filter(CartesianIndices(size(dist))) do cartesian_index
        i, j = cartesian_index.I
        is_up ? i <= j : i >= j
    end
    # there is an additional layer as we need to access `.L` or `.U` before we
    # can index into it
    function make_lens(idx)
        if is_up
            Property{:U}(Index(idx.I, (;), Iden()))
        else
            Property{:L}(Index(idx.I, (;), Iden()))
        end
    end
    return map(make_lens, cartesian_indices)
end

"""
    make_empty_value(dist::MultivariateDistribution)
    make_empty_value(dist::MatrixDistribution)
    make_empty_value(dist::LKJCholesky)

Construct a fresh value filled with zeros that corresponds to the size of `dist`.

For all distributions that this function accepts, it should hold that
`o(make_empty_value(dist))` is zero for all `o` in `get_optics(dist)`.
"""
function make_empty_value(
    dist::Union{Distributions.MultivariateDistribution,Distributions.MatrixDistribution},
)
    return zeros(size(dist))
end
function make_empty_value(dist::Distributions.LKJCholesky)
    if dist.uplo == 'U'
        return Cholesky(UpperTriangular(zeros(size(dist))))
    else
        return Cholesky(LowerTriangular(zeros(size(dist))))
    end
end

"""
    hasvalue(
        vals::Union{AbstractDict,NamedTuple},
        vn::VarName,
        dist::Distribution;
        error_on_incomplete::Bool=false
    )

Check if `vals` contains values for `vn` that is compatible with the
distribution `dist`.

This is a more general version of `hasvalue(vals, vn)`, in that even if
`vn` itself is not inside `vals`, it further checks if `vals` contains
sub-values of `vn` that can be used to reconstruct `vn` given `dist`.

The `error_on_incomplete` flag can be used to detect cases where _some_ of
the values needed for `vn` are present, but others are not. This may help
to detect invalid cases where the user has provided e.g. data of the wrong
shape.

Note that this check is only possible if a Dict is passed, because the key type
of a NamedTuple (i.e., Symbol) is not rich enough to carry indexing
information. If this method is called with a NamedTuple, it will just defer
to `hasvalue(vals, vn)`.

For example:

```jldoctest; setup=:(using Distributions, LinearAlgebra))
julia> d = Dict(@varname(x[1]) => 1.0, @varname(x[2]) => 2.0);

julia> hasvalue(d, @varname(x), MvNormal(zeros(2), I))
true

julia> hasvalue(d, @varname(x), MvNormal(zeros(3), I))
false

julia> hasvalue(d, @varname(x), MvNormal(zeros(3), I); error_on_incomplete=true)
ERROR: only partial values for `x` found in the dictionary provided
[...]
```
"""
function VarNames.hasvalue(
    vals::NamedTuple,
    vn::VarName,
    dist::Distributions.Distribution;
    error_on_incomplete::Bool=false,
)
    # NamedTuples can't have such complicated hierarchies, so it's safe to
    # defer to the simpler `hasvalue(vals, vn)`.
    return hasvalue(vals, vn)
end
function VarNames.hasvalue(
    vals::AbstractDict,
    vn::VarName,
    dist::Distributions.Distribution;
    error_on_incomplete::Bool=false,
)
    @warn "`hasvalue(vals, vn, dist)` is not implemented for $(typeof(dist)); falling back to `hasvalue(vals, vn)`."
    return hasvalue(vals, vn)
end
function VarNames.hasvalue(
    vals::AbstractDict,
    vn::VarName,
    ::Distributions.UnivariateDistribution;
    error_on_incomplete::Bool=false,
)
    # TODO(penelopeysm): We could also implement a check for the type to catch
    # invalid values. Unsure if that is worth it. It may be easier to just let
    # the user handle it.
    return hasvalue(vals, vn)
end
function VarNames.hasvalue(
    vals::AbstractDict{<:VarName},
    vn::VarName{sym},
    dist::Union{
        Distributions.MultivariateDistribution,
        Distributions.MatrixDistribution,
        Distributions.LKJCholesky,
    };
    error_on_incomplete::Bool=false,
) where {sym}
    # If `vn` is present as-is, then we are good
    hasvalue(vals, vn) && return true
    # If not, then we need to check inside `vals` to see if a subset of
    # `vals` is enough to reconstruct `vn`. For example, if `vals` contains
    # `x[1]` and `x[2]`, and `dist` is `MvNormal(zeros(2), I)`, then we
    # can reconstruct `x`. If `dist` is `MvNormal(zeros(3), I)`, then we
    # can't.
    # To do this, we get the size of the distribution and iterate over all
    # possible indices. If every index can be found in `subsumed_keys`, then we
    # can return true.
    optics = get_optics(dist)
    original_optic = getoptic(vn)
    expected_vns = map(o -> VarName{sym}(o ∘ original_optic), optics)
    if all(sub_vn -> hasvalue(vals, sub_vn), expected_vns)
        return true
    else
        if error_on_incomplete && any(sub_vn -> hasvalue(vals, sub_vn), expected_vns)
            error("only partial values for `$vn` found in the dictionary provided")
        end
        return false
    end
end

"""
    VarNames.getvalue(
        vals::Union{AbstractDict,NamedTuple},
        vn::VarName,
        dist::Distribution
    )

Retrieve the value of `vn` from `vals`, using the distribution `dist` to
reconstruct the value if necessary.

This is a more general version of `getvalue(vals, vn)`, in that even if `vn`
itself is not inside `vals`, it can still reconstruct the value of `vn`
from sub-values of `vn` that are present in `vals`.

Note that this reconstruction is only possible if a Dict is passed, because the
key type of a NamedTuple (i.e., Symbol) is not rich enough to carry indexing
information. If this method is called with a NamedTuple, it will just defer
to `getvalue(vals, vn)`.

For example:

```jldoctest; setup=:(using Distributions, LinearAlgebra))
julia> d = Dict(@varname(x[1]) => 1.0, @varname(x[2]) => 2.0);

julia> getvalue(d, @varname(x), MvNormal(zeros(2), I))
2-element Vector{Float64}:
 1.0
 2.0

julia> # Use `hasvalue` to check for this case before calling `getvalue`.
       getvalue(d, @varname(x), MvNormal(zeros(3), I))
ERROR: `x` was not found in the dictionary provided
[...]
```
"""
function VarNames.getvalue(vals::NamedTuple, vn::VarName, dist::Distributions.Distribution)
    # NamedTuples can't have such complicated hierarchies, so it's safe to
    # defer to the simpler `getvalue(vals, vn)`.
    return getvalue(vals, vn)
end
function VarNames.getvalue(
    vals::AbstractDict,
    vn::VarName,
    dist::Distributions.Distribution;
)
    @warn "`getvalue(vals, vn, dist)` is not implemented for $(typeof(dist)); falling back to `getvalue(vals, vn)`."
    return getvalue(vals, vn)
end
function VarNames.getvalue(
    vals::AbstractDict,
    vn::VarName,
    ::Distributions.UnivariateDistribution;
)
    # TODO(penelopeysm): We could also implement a check for the type to catch
    # invalid values. Unsure if that is worth it. It may be easier to just let
    # the user handle it.
    return getvalue(vals, vn)
end
function VarNames.getvalue(
    vals::AbstractDict{<:VarName},
    vn::VarName{sym},
    dist::Union{
        Distributions.MultivariateDistribution,
        Distributions.MatrixDistribution,
        Distributions.LKJCholesky,
    },
) where {sym}
    # If `vn` is present as-is, then we can just return that
    hasvalue(vals, vn) && return getvalue(vals, vn)
    # If not, then we need to start looking inside `vals`, in exactly the
    # same way we did for `hasvalue`.
    optics = get_optics(dist)
    original_optic = getoptic(vn)
    expected_vns = map(o -> VarName{sym}(o ∘ original_optic), optics)
    if all(sub_vn -> hasvalue(vals, sub_vn), expected_vns)
        # Reconstruct the value index by index.
        value = make_empty_value(dist)
        for (o, sub_vn) in zip(optics, expected_vns)
            # Retrieve the value of this given index
            sub_value = getvalue(vals, sub_vn)
            # Set it inside the value we're reconstructing.
            # Note: `o` is normally non-mutating. We have to use the mutating version,
            # because Cholesky distributions are broken by
            # https://github.com/JuliaObjects/Accessors.jl/issues/203.
            Accessors.set(value, with_mutation(o), sub_value)
        end
        return value
    else
        error("$(vn) was not found in the dictionary provided")
    end
end

# TODO(mhauru) The following methods mimic the structure of those in
# AbstractPPLDistributionsExtension, and fall back on converting any PartialArrays to
# dictionaries, and calling the AbstractPPL methods. We should eventually make
# implementations of these directly for PartialArray, and maybe move these methods
# elsewhere. Better yet, once we no longer store VarName values in Dictionaries anywhere,
# and FlexiChains takes over from MCMCChains, this could hopefully all be removed.
#
# NOTE(penelopeysm) See https://github.com/TuringLang/DynamicPPL.jl/issues/1262 for
# explanation of these methods.
VarNames.hasvalue(vals::VarNamedTuple, vn::VarName, ::Distribution) = haskey(vals, vn)
VarNames.getvalue(vals::VarNamedTuple, vn::VarName, ::Distribution) = vals[vn]
function VarNames.hasvalue(vnt::VarNamedTuple, vn::VarName, dist::LKJCholesky)
    if !haskey(vnt, vn)
        # Can't even find the parent VarName, there is no hope.
        return false
    end
    # Note that _getindex_optic, rather than Base.getindex, skips the need to denseify
    # PartialArrays.
    val = VarNames._getindex_optic(vnt, vn)
    if !(val isa VarNamedTuple || val isa PartialArray)
        # There is _a_ value. Whether it's the right kind, we do not know, but returning
        # true is no worse than `hasvalue` returning true for e.g. UnivariateDistributions
        # whenever there is at least some value.
        return true
    end
    # Convert to VarName-keyed Dict.
    et = val isa VarNamedTuple ? Any : eltype(val)
    dval = Dict{VarName,et}()
    for k in keys(val)
        # VarNamedTuples have VarNames as keys, PartialArrays have Index optics.
        subvn = val isa VarNamedTuple ? prefix(k, vn) : append_optic(vn, k)
        dval[subvn] = VarNames._getindex_optic(val, k, subvn)
    end
    return hasvalue(dval, vn, dist)
end

function VarNames.getvalue(vnt::VarNamedTuple, vn::VarName, dist::LKJCholesky)
    # Note that _getindex_optic, rather than Base.getindex, skips the need to denseify
    # PartialArrays.
    val = VarNames._getindex_optic(vnt, vn)
    if !(val isa VarNamedTuple || val isa PartialArray)
        return val
    end
    # Convert to VarName-keyed Dict.
    et = val isa VarNamedTuple ? Any : eltype(val)
    dval = Dict{VarName,et}()
    for k in keys(val)
        # VarNamedTuples have VarNames as keys, PartialArrays have Index optics.
        subvn = val isa VarNamedTuple ? prefix(k, vn) : append_optic(vn, k)
        dval[subvn] = VarNames._getindex_optic(val, k, subvn)
    end
    return getvalue(dval, vn, dist)
end

end # module
