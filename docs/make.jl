using Justly
using Documenter: deploydocs, makedocs

makedocs(sitename = "Justly.jl", modules = [Justly], doctest = false)
deploydocs(repo = "github.com/bramtayl/Justly.jl.git")
