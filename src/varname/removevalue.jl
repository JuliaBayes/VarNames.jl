"""
    remove_value(values::NamedTuple, vn::VarName)

Remove the named field selected by `vn`, including through positional array indices.
Retain empty ancestors and array positions. Missing paths return `values` unchanged.
Copy arrays along the changed path and share unaffected values.

Only `NamedTuple` roots and named-field removal are supported.

# Examples
```jldoctest
julia> remove_value((child=(x=1.0,),), @vn(child.x))
(child = NamedTuple(),)
```
"""
function remove_value(values::NamedTuple, vn::VarName)
    hasvalue(values, vn) || return values
    return _remove_value(values, varname_to_optic(vn))
end

function _remove_value(values::NamedTuple, optic::Property{sym}) where {sym}
    optic.child isa Iden && return Base.structdiff(values, NamedTuple{(sym,)})
    child = _remove_value(getproperty(values, sym), optic.child)
    return merge(values, NamedTuple{(sym,)}((child,)))
end

function _remove_value(values, optic::Union{Property,Index})
    head, tail = ohead(optic), otail(optic)
    return set(values, head, _remove_value(head(values), tail))
end

_remove_value(values, ::Iden) =
    throw(ArgumentError("remove_value can only remove named fields of a NamedTuple"))
