```@setup log
@info "Scripts docs"
```

# Scripts

MIToS implements several useful scripts to **command line execution
(without requiring Julia coding)**. All this scripts are located in the `scripts` folder
of the MIToS directory. You can copy them to your working directory, use the path to
their folder or put them in the path
(look into the **Installation** section of this manual).  

```@contents
Pages = ["Scripts.md"]
Depth = 4
```   

## Buslje09.jl

```@repl
using MIToS
julia = Base.julia_cmd(); # path to the julia executable
scripts_folder = joinpath(pkgdir(MIToS), "scripts")
script_path = joinpath(scripts_folder, "Buslje09.jl")
run(`$julia --project=$scripts_folder $script_path -h`)
```  

## BLMI.jl

```@repl
using MIToS
julia = Base.julia_cmd(); # path to the julia executable
scripts_folder = joinpath(pkgdir(MIToS), "scripts")
script_path = joinpath(scripts_folder, "BLMI.jl")
run(`$julia --project=$scripts_folder $script_path -h`)
```  

## Conservation.jl

```@repl
using MIToS
julia = Base.julia_cmd(); # path to the julia executable
scripts_folder = joinpath(pkgdir(MIToS), "scripts")
script_path = joinpath(scripts_folder, "Conservation.jl")
run(`$julia --project=$scripts_folder $script_path -h`)
```  

## DownloadPDB.jl

```@repl
using MIToS
julia = Base.julia_cmd(); # path to the julia executable
scripts_folder = joinpath(pkgdir(MIToS), "scripts")
script_path = joinpath(scripts_folder, "DownloadPDB.jl")
run(`$julia --project=$scripts_folder $script_path -h`)
```  

## Distances.jl

```@repl
using MIToS
julia = Base.julia_cmd(); # path to the julia executable
scripts_folder = joinpath(pkgdir(MIToS), "scripts")
script_path = joinpath(scripts_folder, "Distances.jl")
run(`$julia --project=$scripts_folder $script_path -h`)
```  

## MSADescription.jl

```@repl
using MIToS
julia = Base.julia_cmd(); # path to the julia executable
scripts_folder = joinpath(pkgdir(MIToS), "scripts")
script_path = joinpath(scripts_folder, "MSADescription.jl")
run(`$julia --project=$scripts_folder $script_path -h`)
```  

## PercentIdentity.jl

```@repl
using MIToS
julia = Base.julia_cmd(); # path to the julia executable
scripts_folder = joinpath(pkgdir(MIToS), "scripts")
script_path = joinpath(scripts_folder, "PercentIdentity.jl")
run(`$julia --project=$scripts_folder $script_path -h`)
```  

## AlignedColumns.jl

```@repl
using MIToS
julia = Base.julia_cmd(); # path to the julia executable
scripts_folder = joinpath(pkgdir(MIToS), "scripts")
script_path = joinpath(scripts_folder, "AlignedColumns.jl")
run(`$julia --project=$scripts_folder $script_path -h`)
```  

## SplitStockholm.jl

```@repl
using MIToS
julia = Base.julia_cmd(); # path to the julia executable
scripts_folder = joinpath(pkgdir(MIToS), "scripts")
script_path = joinpath(scripts_folder, "SplitStockholm.jl")
run(`$julia --project=$scripts_folder $script_path -h`)
```

