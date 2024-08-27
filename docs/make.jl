using OMOPCDMPathways
using Documenter
using DocumenterVitepress

DocMeta.setdocmeta!(OMOPCDMPathways, :DocTestSetup, :(using OMOPCDMPathways); recursive=true)

pgs=[
    "Home" => "index.md",
    "Tutorials" => [
            "Tutorials" => "tutorials.md",
            "Beginner Tutorial 🐣" => "beginner_tutorial.md",
            ],
    "Api" => "api.md",
    "How It Works" => "workflows.md",
    "Contributing" => "contributing.md"
]

fmt  = DocumenterVitepress.MarkdownVitepress(
    repo="https://github.com/JuliaHealth/OMOPCDMPathways.jl",
)

makedocs(;
    modules = [OMOPCDMPathways],
    repo = Remotes.GitHub("JuliaHealth", "OMOPCDMPathways.jl"),
    authors = "Jay-sanjay <landgejay124@gmail.com>, Jacob Zelko <jacobszelko@gmail.com>, and contributors",
    sitename = "OMOPCDMPathways.jl",
    format = fmt,
    pages = pgs,
)

deploydocs(;
    repo="github.com/JuliaHealth/OMOPCDMPathways.jl",
    target="build", # this is where Vitepress stores its output
    devbranch = "main",
    branch = "gh-pages",
    push_preview = true
)
