using Documenter
include(Pkg.dir("Dyn3d")*"/src/Dyn3d.jl")
using Dyn3d

makedocs(
    format =:html,
    sitename = "Dyn3d.jl",
    pages = [
        "Home" => "index.md",
        "Manual" => ["manual/system.md"
        #             "manual/elements.md",
        #             "manual/velocities.md",
        #             "manual/timemarching.md",
        #             "manual/noflowthrough.md",
        #             "manual/motions.md"
                     ]
        #"Internals" => [ "internals/properties.md"]
    ],
    assets = ["assets/custom.css"],
    strict = true
)


if "DOCUMENTER_KEY" in keys(ENV)
    deploydocs(
     repo = "github.com/ruizhi92/Dyn3d.jl.git",
     target = "build",
     deps = nothing,
     make = nothing,
     julia = "0.6"
    )
end
