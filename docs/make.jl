using OMOPCDMPathways
using Documenter
using DocumenterVitepress

# DocMeta.setdocmeta!(OMOPCDMPathways, :DocTestSetup, :(using OMOPCDMPathways); recursive=true)

pgs=[
    "Home" => "index.md",
    "Tutorials" => "tutorials.md",
    "Api" => "api.md",
    "Contributing" => "contributing.md"
]

fmt  = DocumenterVitepress.MarkdownVitepress(
    repo="https://github.com/JuliaHealth/OMOPCDMPathways.jl",
    devbranch = "main",
    deploy_url = "juliahealth.org/OMOPCDMPathways.jl",
    devurl = "dev"
)

makedocs(;
    modules = [OMOPCDMPathways],
    authors = "Jay-sanjay <landgejay124@gmail.com>, Jacob Zelko <jacobszelko@gmail.com>, and contributors",
    sitename = "OMOPCDMPathways.jl",
    format = fmt,
    pages = pgs,
    warnonly = true,
    draft = false,
    source = "src",
    build = "build",
    checkdocs=:all
)

deploydocs(;
    repo="github.com/JuliaHealth/OMOPCDMPathways.jl",
    target="build", # this is where Vitepress stores its output
    devbranch = "main",
    branch = "gh-pages",
    push_preview = true
)
