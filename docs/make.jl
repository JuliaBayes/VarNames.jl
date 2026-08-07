using Pkg: Pkg
Pkg.develop(Pkg.PackageSpec(; path=dirname(@__DIR__)))

using Documenter
using VarNames

makedocs(;
    sitename="VarNames.jl",
    format=Documenter.HTML(),
    modules=[VarNames],
    pages=[
        "index.md",
        "varname.md",
        "VarNamedTuple" => [
            "vnt/motivation.md",
            "vnt/design.md",
            "vnt/implementation.md",
            "vnt/arraylikeblocks.md",
            "vnt/manipulation.md",
            "vnt/api.md",
        ],
    ],
    checkdocs=:exports,
    warnonly=false,
    doctest=false,
)

Documenter.deploydocs(;
    repo="github.com/JuliaBayes/VarNames.jl",
    target="build",
    push_preview=true,
)
