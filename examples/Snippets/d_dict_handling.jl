# --- code snippets to handle dicts:

# --- Values inside nested dicts: ---

sample_dict = Dict("TopLevel_Key1" => Dict("Level2k1" => Dict("Level3k3" => "Hello Julia!")),
"TopLevel_Key2" => Dict("Level2k2" => 1.0),
"TopLevel_Key3" => "Roof top terrace :-)",
);
# ---
function _retrieve(dict::AbstractDict, key_of_interest::AbstractString, output = []) # default value is an empty array    
    for (key, value) in dict
        println("key: ", key, ", typeof(key): ", typeof(key)) # you may comment out this line
        if key == key_of_interest
            push!(output, value)
        end
        if value isa AbstractDict
            _retrieve(value, key_of_interest, output)
        end
    end
    if size(output)[1] == 1
        output = output[]
    end
    return output
end
# ---
_retrieve(sample_dict, "Level3k3")
# --- source: https://discourse.julialang.org/t/package-or-function-to-find-and-access-keys-in-a-nested-dicts/91909/8
