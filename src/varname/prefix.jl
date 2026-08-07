_unprefix_optic(o, ::Iden) = o
function _unprefix_optic(optic, optic_prefix)
    head = ohead(optic)
    head_prefix = ohead(optic_prefix)
    if head != head_prefix
        msg = "cannot remove prefix $(optic_prefix) from optic $(optic)"
        throw(ArgumentError(msg))
    end
    return _unprefix_optic(otail(optic), otail(optic_prefix))
end

"""
    unprefix(vn::VarName, prefix::VarName)

Remove a prefix from a VarName.

```jldoctest
julia> unprefix(@vn(y.x), @vn(y))
x

julia> unprefix(@vn(y.x.a), @vn(y))
x.a

julia> unprefix(@vn(y[1].x), @vn(y[1]))
x

julia> unprefix(@vn(y), @vn(n))
ERROR: ArgumentError: cannot remove prefix n from VarName y
[...]

julia> unprefix(@vn(y[1]), @vn(y))
ERROR: ArgumentError: optic_to_varname: can only convert Property optics to VarName
[...]
```
"""
function unprefix(
    vn::VarName{sym_vn},
    prefix::VarName{sym_prefix},
) where {sym_vn,sym_prefix}
    if sym_vn != sym_prefix
        msg = "cannot remove prefix $(prefix) from VarName $(vn)"
        throw(ArgumentError(msg))
    end
    optic_vn = getoptic(vn)
    optic_prefix = getoptic(prefix)
    return optic_to_varname(_unprefix_optic(optic_vn, optic_prefix))
end

"""
    prefix(vn::VarName, prefix::VarName)

Add a prefix to a VarName.

```jldoctest
julia> prefix(@vn(x), @vn(y))
y.x

julia> prefix(@vn(x.a), @vn(y))
y.x.a

julia> prefix(@vn(x.a), @vn(y[1]))
y[1].x.a
```
"""
function prefix(vn::VarName{sym_vn}, prefix::VarName{sym_prefix}) where {sym_vn,sym_prefix}
    new_optic_vn = varname_to_optic(vn) ∘ getoptic(prefix)
    return VarName{sym_prefix}(new_optic_vn)
end
