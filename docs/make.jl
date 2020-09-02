using Justly
using Documenter

makedocs(;
    modules=[Justly],
    authors="Brandon Taylor <brandon.taylor221@gmail.com> and contributors",
    repo="https://github.com/bramtayl/Justly.jl/blob/{commit}{path}#L{line}",
    sitename="Justly.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://bramtayl.github.io/Justly.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/bramtayl/Justly.jl",
)
