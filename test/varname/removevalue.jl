module RemoveValueTests

using VarNames, Test

@testset "remove_value" begin
    values = (child=(x=1.0, y=2.0),)
    @test remove_value(values, @vn(child.x)) == (child=(y=2.0,),)
    @test remove_value(values, @vn(child)) == NamedTuple()
    @test remove_value((child=(x=1.0,),), @vn(child.x)) == (child=NamedTuple(),)

    shared = [3.0]
    values = (groups=Any[(children=[(x=1.0, y=shared), (x=2.0, y=shared)],)],)
    result = remove_value(values, @vn(groups[1].children[1].x))
    @test result == (groups=[(children=[(y=shared,), (x=2.0, y=shared)],)],)
    @test values.groups[1].children[1] == (x=1.0, y=shared)
    @test result.groups !== values.groups
    @test result.groups[1].children !== values.groups[1].children
    @test result.groups[1].children[1].y === shared

    @test remove_value(values, @vn(groups[1].children[1].missing)) === values
    @test_throws ArgumentError remove_value(values, @vn(groups[1].children[1]))
end

end
