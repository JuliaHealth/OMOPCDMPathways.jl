using OMOPCDMPathways
using Documenter

DocMeta.setdocmeta!(OMOPCDMPathways, :DocTestSetup, :(using OMOPCDMPathways); recursive=true)

makedocs(;
    modules=[OMOPCDMPathways],
    authors="Jay-sanjay <landgejay124@gmail.com> and contributors",
    sitename="OMOPCDMPathways.jl",
    format=Documenter.HTML(;
        canonical="https://Jay-sanjay.github.io/OMOPCDMPathways.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Jay-sanjay/OMOPCDMPathways.jl",
    devbranch="main",
)
