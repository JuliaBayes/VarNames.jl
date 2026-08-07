module VarNamesComponentArraysExt

using VarNames
using VarNames:
    PartialArray,
    AllowAll,
    SetPermissions,
    _setindex_optic!!,
    _getindex_optic,
    make_leaf,
    make_leaf_singleindex,
    _is_multiindex,
    make_leaf_multiindex

using ComponentArrays: ComponentArrays, ComponentArray, ComponentVector

# Helper: convert a Property optic label S to an integer Index optic
function _property_to_index(template::ComponentVector, optic::Property{S}) where {S}
    ax = ComponentArrays.getaxes(template)[1]
    idx = first(ax[S].idx)
    return Index((idx,), NamedTuple(), optic.child)
end

function VarNames.make_leaf(value, optic::Property{S}, template::ComponentVector) where {S}
    return if optic.child isa Iden
        index_optic = _property_to_index(template, optic)
        make_leaf(value, index_optic, template)
    else
        # This branch is needed to handle nested axes in ComponentArrays: the idea is that
        # if x is e.g. ComponentArray(a=(b=1)) and we are trying to set `x.a.b`, then we
        # first index into `x.a` to get the slice of the ComponentArray. The easiest way to
        # handle this is to call the default method.
        invoke(
            VarNames.make_leaf,
            Tuple{Any,Property{S},AbstractArray},
            value,
            optic,
            template,
        )
    end
end

function VarNames._setindex_optic!!(
    pa::PartialArray{<:Any,<:Any,<:ComponentVector},
    value,
    optic::Property{S},
    template,
    permissions::SetPermissions=AllowAll(),
) where {S}
    index_optic = _property_to_index(pa.data, optic)
    return _setindex_optic!!(pa, value, index_optic, template, permissions)
end

function VarNames._getindex_optic(
    pa::PartialArray{<:Any,<:Any,<:ComponentVector},
    optic::Property{S},
    orig_vn,
) where {S}
    index_optic = _property_to_index(pa.data, optic)
    return _getindex_optic(pa, index_optic, orig_vn)
end

end
