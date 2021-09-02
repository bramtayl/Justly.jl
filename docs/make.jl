using Justly
using Documenter: deploydocs, makedocs

makedocs(
    sitename = "Justly.jl", 
    modules = [Justly], 
    doctest = false,
    pages = [
        "Public interface" => "index.md"
    ]
)
deploydocs(repo = "github.com/bramtayl/Justly.jl.git")
