using Overt
using Documenter

makedocs(;
    modules=[Overt],
    authors="Amir Maleki, Chelsea Sidrane",
    repo="https://github.com/amaleki2/Overt.jl/blob/{commit}{path}#L{line}",
    sitename="Overt.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://amaleki2.github.io/Overt.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/amaleki2/Overt.jl",
)
