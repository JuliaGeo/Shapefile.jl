using Shapefile
using Documenter

makedocs(;
    modules=[Shapefile],
    repo="https://github.com/JuliaGeo/Shapefile.jl/blob/{commit}{path}#{line}",
    sitename="Shapefile.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaGeo.github.io/Shapefile.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGeo/Shapefile.jl",
    devbranch="main",
)
