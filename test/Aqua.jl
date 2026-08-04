module AquaTests

using Aqua: Aqua
using Varnames: Varnames

@info "Testing Aqua.jl"
Aqua.test_all(Varnames)

end
