module VarNameSubsumesTests

using VarNames
using Test

@testset "varname/subsumes.jl" verbose = true begin
    @testset "varnames that are equal" begin
        @test subsumes(@vn(x), @vn(x))
        @test subsumes(@vn(x[1]), @vn(x[1]))
        @test subsumes(@vn(x.a), @vn(x.a))
        @test subsumes(@vn(x[:]), @vn(x[:]))
    end

    uncomparable(vn1, vn2) = !subsumes(vn1, vn2) && !subsumes(vn2, vn1)
    @testset "uncomparable varnames" begin
        @test uncomparable(@vn(x), @vn(y))
        @test uncomparable(@vn(x.a), @vn(y.a))
        @test uncomparable(@vn(a.x), @vn(a.y))
        @test uncomparable(@vn(a.x[1]), @vn(a.x.z))
        @test uncomparable(@vn(x[1]), @vn(y[1]))
        @test uncomparable(@vn(x[1]), @vn(x.y))
    end

    strictly_subsumes(vn1, vn2) = subsumes(vn1, vn2) && !subsumes(vn2, vn1)
    @testset "strict subsumption - no index comparisons" begin
        @test strictly_subsumes(@vn(x), @vn(x.a))
        @test strictly_subsumes(@vn(x), @vn(x[1]))
        @test strictly_subsumes(@vn(x), @vn(x[2:2:5]))
        @test strictly_subsumes(@vn(x), @vn(x[10, 20]))
        @test strictly_subsumes(@vn(x.a), @vn(x.a.b))
        @test strictly_subsumes(@vn(x[1]), @vn(x[1].a))
        @test strictly_subsumes(@vn(x.a), @vn(x.a[1]))
        @test strictly_subsumes(@vn(x[1:10]), @vn(x[1:10][2]))
    end

    @testset "strict subsumption - index comparisons" begin
        @testset "integer vectors" begin
            @test strictly_subsumes(@vn(x[1:10]), @vn(x[1]))
            @test strictly_subsumes(@vn(x[1:10]), @vn(x[1:5]))
            @test strictly_subsumes(@vn(x[1:10]), @vn(x[4:6]))
            @test strictly_subsumes(@vn(x[1:10, 1:10]), @vn(x[1:5, 1:5]))
            @test strictly_subsumes(@vn(x[[5, 4, 3, 2, 1]]), @vn(x[[2, 4]]))
        end

        @testset "non-integer indices" begin
            @test strictly_subsumes(@vn(x[:a]), @vn(x[:a][1]))
        end

        @testset "colon" begin
            @test strictly_subsumes(@vn(x[:]), @vn(x[1]))
            @test strictly_subsumes(@vn(x[:, 1:10]), @vn(x[1:10, 1]))
        end

        @testset "dynamic indices" begin
            @test strictly_subsumes(@vn(x), @vn(x[begin]))
            @test subsumes(@vn(x[begin]), @vn(x[begin]))
            @test strictly_subsumes(@vn(x[:]), @vn(x[begin]))
            @test strictly_subsumes(@vn(x), @vn(x[end]))
            @test subsumes(@vn(x[end]), @vn(x[end]))
            @test strictly_subsumes(@vn(x[:]), @vn(x[end]))
            @test strictly_subsumes(@vn(x[:]), @vn(x[1:end]))
            @test strictly_subsumes(@vn(x[:]), @vn(x[end-3]))
            @test uncomparable(@vn(x[begin]), @vn(x["a"]))
            @test uncomparable(@vn(x[begin]), @vn(x[1:5]))
        end

        @testset "keyword indices" begin
            @test strictly_subsumes(@vn(x), @vn(x[a=1]))
            @test strictly_subsumes(@vn(x[a=1:10, b=1:10]), @vn(x[a=1:10]))
            @test strictly_subsumes(@vn(x[a=1:10, b=1:10]), @vn(x[a=1:5, b=1:5]))
            @test strictly_subsumes(@vn(x[a=:]), @vn(x[a=1]))
            @test uncomparable(@vn(x[a=1:10, b=5]), @vn(x[a=5, b=1:10]))
            @test uncomparable(@vn(x[a=1]), @vn(x[b=1]))
        end
    end
end

end # module
