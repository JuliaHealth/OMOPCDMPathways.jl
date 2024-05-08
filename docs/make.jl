using OMOPCDMPathways
using Documenter, DocumenterVitepress

DocMeta.setdocmeta!(OMOPCDMPathways, :DocTestSetup, :(using OMOPCDMPathways); recursive=true)

pgs=[
        "Home" => "index.md",
]

fmt  = DocumenterVitepress.MarkdownVitepress(
    repo="https://github.com/JuliaHealth/OMOPCDMPathways",
    devurl = "dev",
    # deploy_url = "yourgithubusername.github.io/OMOPCDMPathways.jl",
    build_vitepress = false,
)
# )

makedocs(;
    modules = [OMOPCDMPathways],
    authors = "Jay-sanjay <landgejay124@gmail.com> and contributors",
    repo = "https://github.com/JuliaHealth/OMOPCDMPathways",
    sitename = "OMOPCDMPathways.jl",
    format = fmt,
    pages= pgs,
    warnonly = true,
)

deploydocs(;
    repo="https://github.com/JuliaHealth/OMOPCDMPathways",
    target="build", # this is where Vitepress stores its output
    branch = "gh-pages",
    devbranch = "main",
    push_preview = true,
)


"""
To build docs locally run ths in the docs folder: npm run docs:dev
"""
