if false
include("./MyAppReadToml.jl")
Main.MyAppReadToml.julia_main()
Main.MyAppReadToml.__init__()
end

using TOML

sentense_(_dict::Dict{<:AbstractString, Any}, _i::Int) = println(string(_dict["names"][_i], " is ", _dict["age"][_i], " years old."))

sentense_(_dict, _i) = println(string(_dict["names"][_i], " is ", _dict["age"][_i], " years old."))
sentense_(_dict, _i) = sentense_(_dict::Dict{<:AbstractString, Any}, _i::Int) 

input_toml_file = "/media/stefan/DATA/repos/own_repos/Stefans_Julia_RePo/AppDir/tmp_MyAppReadToml_compiled_j1.6.7_PCv2.1.5/input_files/default.toml"
_content = TOML.parsefile(input_toml_file) 

typeof_content = Core.typeof(_content)
@show typeof_content


sentense_(_content, 1)

println("\n ---------------------------------------- \n ")