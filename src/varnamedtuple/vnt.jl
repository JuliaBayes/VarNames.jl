using BangBang

"""
    VarNamedTuple{names,Values}

A `NamedTuple`-like structure with `VarName` keys.

`VarNamedTuple` is a data structure for storing arbitrary data, keyed by `VarName`s, in an
efficient and type stable manner. It is mainly used through `getindex`, `setindex!!`,
`templated_setindex!!`, and `haskey`, all of which only accept `VarName`s as keys. Other
notable methods are `merge` and `subset`.

`VarNamedTuple` has an ordering to its elements, and two `VarNamedTuple`s with the same keys
and values but in different orders are considered different for equality and hashing.
Iterations such as `keys` and `values` respect this ordering. The ordering is dependent on
the order in which elements were inserted into the `VarNamedTuple`, though isn't always
equal to it. More specifically

* Any new keys that have a joint parent `VarName` with an existing key are inserted after
  that key. For instance, if one first inserts, in order, `@vn(a.x)`, `@vn(b)`,
  and `@vn(a.y)`, the resulting order will be
  `(@vn(a.x), @vn(a.y), @vn(b))`.
* `Index` keys, like `@vn(a[3])` or `@vn(b[2,3,4:5])`, are always iterated
  in the same order an `Array` with the same indices would be iterated. For instance,
  if one first inserts, in order, `@vn(a[2])`, `@vn(b)`, and `@vn(a[1])`,
  the resulting order will be `(@vn(a[1]), @vn(a[2]), @vn(b))`.

Otherwise insertion order is respected.

`setindex!!` and `getindex` on `VarNamedTuple` are type stable as long as one does not store
heterogeneous data under different indices of the same symbol. That is, if either

* one sets `a[1]` and `a[2]` to be of different types, or
* if `a[1]` and `a[2]` both exist, one sets `a[1].b` without setting `a[2].b`,

then getting values for `a[1]` or `a[2]` will not be type stable.
"""
struct VarNamedTuple{Names,Values}
    data::NamedTuple{Names,Values}

    function VarNamedTuple(data::NamedTuple{Names,Values}) where {Names,Values}
        return new{Names,Values}(data)
    end
end

VarNamedTuple(; kwargs...) = VarNamedTuple((; kwargs...))

"""
    VarNamedTuple(d)
    VarNamedTuple(nt::NamedTuple)

Create a `VarNamedTuple` from a collection or a `NamedTuple`.

Any collection `d` is assumed to be an iterable of key-value pairs, where the keys are
`VarName`s. This could be a an `AbstractDict`, a vector of `Pair`s or `Tuple`s, etc.
Alternatively, a `NamedTuple` can be passed, in which case the keys (i.e., `Symbol`s) are
converted to `VarName`s.

Note that `VarNamedTuple` has an ordering to its elements, and two `VarNamedTuple`s with the
same keys and values but in different orders are considered different. If `d` does not
guarantee an iteration order, then the order of the elements in the resulting
`VarNamedTuple` is undefined.
"""
function VarNamedTuple(d)
    vnt = VarNamedTuple()
    for (k, v) in d
        vnt = setindex!!(vnt, v, k)
    end
    return vnt
end

Base.:(==)(vnt1::VarNamedTuple, vnt2::VarNamedTuple) = vnt1.data == vnt2.data
Base.isequal(vnt1::VarNamedTuple, vnt2::VarNamedTuple) = isequal(vnt1.data, vnt2.data)
Base.hash(vnt::VarNamedTuple, h::UInt) = hash("vnt", hash(vnt.data, h))

function Base.copy(vnt::VarNamedTuple{names}) where {names}
    # Make a shallow copy of vnt, except for any VarNamedTuple or PartialArray elements,
    # which we recursively copy.
    return VarNamedTuple(
        NamedTuple{names}(
            map(
                x -> x isa Union{VarNamedTuple,PartialArray} ? copy(x) : x,
                values(vnt.data),
            ),
        ),
    )
end

# PartialArrays and GrowableArrays are an implementation detail of VarNamedTuple, and should
# never be the return value of getindex. Thus, we automatically convert them to dense arrays
# if needed.
function Base.getindex(vnt::VarNamedTuple, vn::VarName)
    result = _getindex_optic(vnt, vn)
    return unwrap_internal_array(result)
end

Base.haskey(vnt::VarNamedTuple, vn::VarName) = _haskey_optic(vnt, vn)

"""
    templated_setindex!!(vnt, value, vn, template; allow_new=Val(true))

Assign `value` to the location in `vnt` specified by `vn`.

The argument `template` must be provided in order to guide the creation of `PartialArray`s,
as well as to concretise any dynamic indices in `vn`. It must be an object that has the
shape of the top-level symbol in `vn`. For example:

```julia
vnt = VarNamedTuple()
templated_setindex!!(vnt, 10, @vn(x[1]), rand(2, 2))
```

Here, `rand(2, 2)` is the template for the top-level symbol `x`, which tells `setindex!!`
that `x` should be a `PartialArray` that is backed by a matrix.

The actual data inside `template` is not needed, and `template` is never mutated by this
call.
"""
function templated_setindex!!(vnt::VarNamedTuple, value, vn::VarName, template)
    return _setindex_optic!!(
        vnt,
        value,
        varname_to_optic(vn),
        SkipTemplate{1}(template),
        AllowAll(),
    )
end

"""
    templated_setindex_no_overwrite!!(vnt, value, vn, template)

This is the same as `templated_setindex!!`, but throws an error if the location specified by
`vn` already has a value in `vnt`. This is useful for ensuring that values in a `VarNamedTuple`
are not set multiple times.
"""
function templated_setindex_no_overwrite!!(vnt::VarNamedTuple, value, vn::VarName, template)
    return _setindex_optic!!(
        vnt,
        value,
        varname_to_optic(vn),
        SkipTemplate{1}(template),
        MustNotOverwrite(vn),
    )
end

"""
    BangBang.setindex!!(vnt::VarNamedTuple, value, vn::VarName)

This is similar to `templated_setindex!!`, but does not take a `template` argument. In
effect the `template` passed through is `NoTemplate()`. It is often the case that the
template is not actually needed (for example, if you are setting a top-level VarName:
`@vn(a)`, or if the VarName only contains Property optics, or if the arrays already
exist and you are merely updating a value inside it). In such cases, this method will work
fine, but may throw an error if the template is actually needed. Specifically, this is
likely to happen if you set a VarName with dynamic optics or colons, since in those cases
the size and shape of the underlying arrays cannot be inferred without a template.

For example, this will error, since it is not known what `x` should be:

```julia
vnt = VarNamedTuple()
setindex!!(vnt, 10, @vn(x[1]))
```
"""
function BangBang.setindex!!(vnt::VarNamedTuple, value, vn::VarName)
    # NOTE(penelopeysm): I _thought_ that if you allow setindex!! to reuse whatever template
    # was inside the VNT, it would help with type stability. Essentially, check if
    # getsym(vn) is inside the type parameter of vnt, and if so, use vnt.data.$sym as the
    # template instead of NoTemplate(). But it actually made type stability worse. I don't
    # know why.
    return _setindex_optic!!(vnt, value, varname_to_optic(vn), NoTemplate())
end

"""
    _has_partial_array(::Type{VarNamedTuple{Names,Values}}) where {Names,Values}

Check if any of the types in the `Values` tuple is or contains a `PartialArray`.

Recurses into any sub-`VarNamedTuple`s.
"""
@generated function _has_partial_array(
    ::Type{VarNamedTuple{Names,Values}},
) where {Names,Values}
    for T in Values.parameters
        if _has_partial_array(T)
            return :(return true)
        end
    end
    return :(return false)
end

_has_partial_array(::Type{T}) where {T} = false
_has_partial_array(::Type{<:PartialArray}) = true

Base.empty(::VarNamedTuple) = VarNamedTuple()

"""
    empty!!(vnt::VarNamedTuple)

Create an empty version of `vnt` in place.

This differs from `Base.empty` in that any `PartialArray`s contained within `vnt` are kept
but have their contents deleted, rather than being removed entirely. This means that

1) The result has a "memory" of how many dimensions different variables had, and you cannot,
   for example, set `a[1,2]` after emptying a `VarNamedTuple` that had only `a[1]` defined.
2) Memory allocations may be reduced when reusing `VarNamedTuple`s, since the internal
   `PartialArray`s do not need to be reallocated from scratch.
"""
@generated function BangBang.empty!!(vnt::VarNamedTuple{Names,Values}) where {Names,Values}
    if !_has_partial_array(VarNamedTuple{Names,Values})
        return :(return VarNamedTuple())
    end
    # Check all the fields of the NamedTuple, and keep the ones that contain PartialArrays,
    # calling empty!! on them recursively.
    new_names = ()
    new_values = ()
    for (name, ValType) in zip(Names, Values.parameters)
        if _has_partial_array(ValType)
            new_values = (new_values..., :(BangBang.empty!!(vnt.data.$name)))
            new_names = (new_names..., name)
        end
    end
    return quote
        return VarNamedTuple(NamedTuple{$new_names}(($(new_values...),)))
    end
end

@generated function Base.isempty(vnt::VarNamedTuple{Names,Values}) where {Names,Values}
    if isempty(Names)
        return :(return true)
    end
    if !_has_partial_array(VarNamedTuple{Names,Values})
        return :(return false)
    end
    exs = Expr[]
    for (name, ValType) in zip(Names, Values.parameters)
        if !_has_partial_array(ValType)
            return :(return false)
        end
        push!(exs, quote
            val = vnt.data.$name
            if val isa VarNamedTuple || val isa PartialArray
                if !Base.isempty(val)
                    return false
                end
            else
                return false
            end
        end)
    end
    push!(exs, :(return true))
    return Expr(:block, exs...)
end

"""
    NamedTuple(vnt::VarNamedTuple)

Convert a `VarNamedTuple` to a standard `NamedTuple`, provided all keys in the
`VarNamedTuple` are `VarName`s with top-level symbols. If any key is a `VarName`
with a non-identity optic (e.g., `@vn(x.a)` or `@vn(x[1])`), this will
throw an `ArgumentError`.

# Examples

```jldoctest
julia> using VarNames, BangBang

julia> vnt = VarNamedTuple(); vnt = setindex!!(vnt, 10, @vn(x))
VarNamedTuple
└─ x => 10

julia> NamedTuple(vnt)
(x = 10,)

julia> vnt2 = setindex!!(vnt, 20, @vn(y.a))
VarNamedTuple
├─ x => 10
└─ y => VarNamedTuple
        └─ a => 20

julia> NamedTuple(vnt2)
ERROR: ArgumentError: Cannot convert VarNamedTuple containing non-identity VarNames to NamedTuple. To create a NamedTuple, all keys in the VarNamedTuple must be top-level symbols.
[...]
```
"""
@generated function Base.NamedTuple(vnt::VarNamedTuple{names,vals}) where {names,vals}
    if isempty(names)
        return :(NamedTuple())
    end
    nt = Expr(:tuple)
    for (n, v) in zip(names, vals.parameters)
        if v <: VarNamedTuple ||
           VarNamedTuple <: v ||
           v <: PartialArray ||
           PartialArray <: v
            throw(
                ArgumentError(
                    "Cannot convert VarNamedTuple containing non-identity VarNames to NamedTuple. To create a NamedTuple, all keys in the VarNamedTuple must be top-level symbols.",
                ),
            )
        end
        push!(nt.args, :($n = vnt.data.$n))
    end
    return nt
end
