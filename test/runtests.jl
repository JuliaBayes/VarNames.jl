using Test

@testset "VarNames.jl" begin
    include("Aqua.jl")
    include("varname/optic.jl")
    include("varname/varname.jl")
    include("varname/subsumes.jl")
    include("varname/hasvalue.jl")
    include("varname/leaves.jl")
    include("varname/serialize.jl")
    include("varnamedtuple.jl")
end
