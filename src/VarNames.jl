module VarNames

include("varname/optic.jl")
include("varname/varname.jl")
include("varname/subsumes.jl")
include("varname/hasvalue.jl")
include("varname/leaves.jl")
include("varname/prefix.jl")
include("varname/serialize.jl")

export AbstractOptic,
    Iden,
    Index,
    Property,
    with_mutation,
    ohead,
    otail,
    olast,
    oinit,
    # VarName
    VarName,
    getsym,
    getoptic,
    concretize,
    concretize_top_level,
    is_dynamic,
    @vn,
    varname,
    @opticof,
    varname_to_optic,
    optic_to_varname,
    append_optic,
    # other functions
    subsumes,
    prefix,
    unprefix,
    hasvalue,
    getvalue,
    canview,
    varname_leaves,
    varname_and_value_leaves,
    # Serialisation
    index_to_dict,
    dict_to_index,
    varname_to_string,
    string_to_varname

using Accessors: set
export set

include("varnamedtuple/types.jl")
include("varnamedtuple/partial_array.jl")
include("varnamedtuple/vnt.jl")
include("varnamedtuple/getset.jl")
include("varnamedtuple/map.jl")
include("varnamedtuple/show.jl")
include("varnamedtuple/macro.jl")
include("varnamedtuple/skeleton.jl")

export VarNamedTuple,
    map_pairs!!,
    map_values!!,
    apply!!,
    templated_setindex!!,
    templated_setindex_no_overwrite!!,
    densify!!,
    skeleton,
    subset,
    NoTemplate,
    SkipTemplate,
    @vnt

using BangBang: push!!, empty!!, setindex!!
export push!!, empty!!, setindex!!

end # module VarNames
