module VarNameSerialisationTests

using InvertedIndices: Not, InvertedIndex
using VarNames
using Test

@testset "varname/serialize.jl" verbose = true begin
    @testset "roundtrip" begin
        y = ones(10)
        z = ones(5, 2)
        vns = [
            @vn(x),
            @vn(ä),
            @vn(x.a),
            @vn(x.a.b),
            @vn(var"x.a"),
            @vn(x[1]),
            @vn(var"x[1]"),
            @vn(x[1:10]),
            @vn(x[1:3:10]),
            @vn(x[1, 2]),
            @vn(x[1, 2:5]),
            @vn(x[:]),
            @vn(x.a[1]),
            @vn(x.a[1:10]),
            @vn(x[1].a),
            @vn(y[:]),
            @vn(y[begin:end], true),
            @vn(y[end], true),
            @vn(y[:], false),
            @vn(y[:], true),
            @vn(z[:], false),
            @vn(z[:], true),
            @vn(z[:][:], false),
            @vn(z[:][:], true),
            @vn(z[:, :], false),
            @vn(z[:, :], true),
            @vn(z[2:5, :], false),
            @vn(z[2:5, :], true),
            @vn(x[i=1]),
            @vn(x[j=2, i=1]),
            @vn(x[i=1, j=2]),
            @vn(x[].a[j=2].b[3, 4, 5, [6]]),
            @vn(x[[1, 2, 5, 6]]),
        ]
        for vn in vns
            @test string_to_varname(varname_to_string(vn)) == vn
        end
    end

    @testset "deserialisation fails for unconcretised dynamic indices" begin
        for vn in (@vn(x[1:end]), @vn(x[begin:end]), @vn(x[2:step:end]))
            @test_throws ArgumentError varname_to_string(vn)
        end
    end

    @testset "custom index types" begin
        vn = @vn(x[Not(3)])

        # This won't work as we don't yet know how to handle OffsetArray
        @test_throws MethodError varname_to_string(vn)

        # Now define the relevant methods
        VarNames.index_to_dict(o::InvertedIndex{I}) where {I} = Dict(
            "type" => "InvertedIndices.InvertedIndex",
            "skip" => VarNames.index_to_dict(o.skip),
        )
        VarNames.dict_to_index(::Val{Symbol("InvertedIndices.InvertedIndex")}, d) =
            InvertedIndex(VarNames.dict_to_index(d["skip"]))

        # Serialisation should now work
        @test string_to_varname(varname_to_string(vn)) == vn

        # Delete the methods to avoid side effects when running tests again.
        Base.delete_method(which(VarNames.index_to_dict, (InvertedIndex{Int},)))
        Base.delete_method(
            which(
                VarNames.dict_to_index,
                (Val{Symbol("InvertedIndices.InvertedIndex")}, Dict),
            ),
        )
    end
end

end # module
