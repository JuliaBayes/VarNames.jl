module VarNamePrefixTests

using Test
using VarNames

@testset "varname/prefix.jl" verbose = true begin
    @testset "basic cases" begin
        @test prefix(@vn(y), @vn(x)) == @vn(x.y)
        @test prefix(@vn(y), @vn(x[1])) == @vn(x[1].y)
        @test prefix(@vn(y), @vn(x.a)) == @vn(x.a.y)
        @test prefix(@vn(y[1]), @vn(x)) == @vn(x.y[1])
        @test prefix(@vn(y.a), @vn(x)) == @vn(x.y.a)

        @test unprefix(@vn(x.y[1]), @vn(x)) == @vn(y[1])
        @test unprefix(@vn(x[1].y), @vn(x[1])) == @vn(y)
        @test unprefix(@vn(x.a.y), @vn(x.a)) == @vn(y)
        @test unprefix(@vn(x.y.a), @vn(x)) == @vn(y.a)
        @test_throws ArgumentError unprefix(@vn(x.y.a), @vn(n))
        @test_throws ArgumentError unprefix(@vn(x.y.a), @vn(x[1]))
    end

    @testset "round-trip + type stability" begin
        # This tuple is probably overkill, but the tests are super fast
        # anyway.
        vns = (
            @vn(p),
            @vn(q),
            @vn(r[1]),
            @vn(s.a),
            @vn(t[1].a),
            @vn(u[1].a.b),
            @vn(v.a[1][2].b.c.d[3])
        )
        for vn1 in vns
            for vn2 in vns
                prefixed = @inferred prefix(vn1, vn2)
                @test subsumes(vn2, prefixed)
                unprefixed = @inferred unprefix(prefixed, vn2)
                @test unprefixed == vn1
            end
        end
    end
end

end # module
