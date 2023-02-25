# --- MyEnvTools.jl --------------------------------------------------------------------------------------------.
# Collection of functions to analyse harmonic signals in time series data.
#
# Copyright (C) 2022   Stefan N.Pofahl (Graz, Austria)
#
# File Owner:
#   - Stefan Pofahl(till 07-Jul-2022)
#
# History:
# v0.9(15-07-2022), Stefan Pofahl
#   - initial version
# ---------------------------------------------------------------------------------------------------------------------------
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# --------------------------------------------------------------------------------------------------------------------------
# Markdown notation: https://docs.julialang.org/en/v1/stdlib/Markdown/
# --------------------------------------------------------------------------------------------------------------------------

module MyEnvTools

import Pkg
export MyLib_select_primary_env, MyLib_add_primary_env

# ---
function MyLib_select_primary_env(_environment::AbstractString="")
    b_dbg = false
    prim_env_dir = []
    if VERSION < VersionNumber(1, 6, 7)
        error("Julia too old! Please upgrade to v > v1.6.7!")
    else
        env_dir = joinpath(Pkg.envdir(), string("v", VERSION)[1:end-2])
    end
    # env_dir = Pkg.envdir()
    dir_list = readdir(env_dir, join= false)
    dir_list_full = readdir(env_dir, join= true)
    env_list = []
    for i_ = eachindex(dir_list)
        if isdir(dir_list_full[i_]) 
            # println(dir_list[i_])
            push!(env_list, dir_list[i_]) 
        end
    end
    if isempty(_environment)
        Pkg.activate()
        if isempty(env_list)
            println("No additional environments found!")
        else
            if b_dbg
                println("----   Number of available environments: ", length(env_list), "  ----")
                for i_ = eachindex(env_list)
                    println(i_, ".) ",env_list[i_])
                end
                println("------------------------------------------------")
            end
        end
    else
        prim_env_dir = joinpath(env_dir, _environment)
        if any(occursin.(_environment, string.(env_list)))
            if splitpath(Base.active_project())[end-1] != _environment
                Pkg.activate(prim_env_dir)
            else
                @info(string("Environment \"", _environment, "\" is already loaded!"))
            end
        else
            @warn(string("Julia Pkg-environment: \"", _environment, "\" not found!"))
            @info("Call function without argument to list available environments.")
        end
    end
    return env_list
end

function MyLib_add_primary_env(_environment::AbstractString="")
    curr_dir = pwd()
    env_dir = joinpath(Pkg.envdir(), string("v", VERSION)[1:end-2])
    # env_dir = Pkg.envdir()
    dir_list = readdir(env_dir, join= false)
    dir_list_full = readdir(env_dir, join= true)
    env_list = []
    for i_ = eachindex(dir_list)
        if isdir(dir_list_full[i_]) 
            # println(dir_list[i_])
            push!(env_list, dir_list[i_]) 
        end
    end
    if isempty(_environment) ||  ~any(occursin.(_environment, string.(env_list)))
        cd(env_dir)
        Pkg.activate(_environment)
        Pkg.add("Revise")
        cd(curr_dir)
        println("current dir: ", pwd())
    end
    return env_list
end

# --- found in the julia forum:
# --- https://discourse.julialang.org/t/proper-way-to-create-sysimage-with-all-dependencies-of-a-given-package/91460/6
function _find_deps(do_not_include::Vector{String}=["PackageCompiler"])
    # Get all packages from Project.toml
	all_packages = String[]
	for (uuid, dep) in Pkg.dependencies()
		dep.is_direct_dep || continue
		dep.version === nothing && continue
		push!(all_packages, dep.name)
	end
	# Remove not needed packages
	package_list = filter(x -> x ∉ do_not_include, all_packages)
    return package_list
end




end ## --- end module ------------------------------------------------------------------------------------------------------
