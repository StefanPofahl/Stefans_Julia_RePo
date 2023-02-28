# --- code snippets useful to investigate environments: -------------------------------------------------------------------------

# --- cross-references:
# ---   > w_workspace_tools ->  Base.names()

# *******************************************************************************************************************************
# --- 
function find_uuid_in_current_environment(package::AbstractString="Revise")
    UUID = ""
    for (_key, _value) in TOML.tryparsefile(Base.active_project())
        # global UUID # not needed inside a function
        if isa(_value, Dict)
            # println("_value: ", _value)
            println("_key: ", _key)
            if cmp(_key, "deps") == 0
                if haskey(_value, package)
                    UUID = _value[package]
                end
            end
        end
    end
    return package, UUID
end


# --- or in one line:
TOML.parsefile(Base.active_project())["deps"]["Revise"]
# --- reference: https://discourse.julialang.org/t/missing-relocatability-of-tulip/94886/8

# --- in form of function:
show_uuid(package_name::AbstractString) = TOML.parsefile(Base.active_project())["deps"][package_name]

show_uuid("Revise")