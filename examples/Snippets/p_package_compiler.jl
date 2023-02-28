# --------------------------
# *******************************************************************************************************************************
# --- Relocatibility / Resolve Relocatibility issues:
# old:
const _TULIP_VERSION = Ref{VersionNumber}()         
function __init__()
    # Read Tulip version from Project.toml file
    tlp_ver = VersionNumber(TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))["version"])
    _TULIP_VERSION[] = tlp_ver
end

# new: from Frederik Ekre
# Read Tulip version from Project.toml file
const TULIP_VERSION = let project = joinpath(@__DIR__, "..", "Project.toml")
    Base.include_dependency(project)
    VersionNumber(TOML.parsefile(project)["version"])
end
# --- reference: https://discourse.julialang.org/t/missing-relocatability-of-tulip/94886/6

# *************************************************************************************************
# --- Test directory for input output files of project module during development phase
# --- 1.) declare variable references IS_TEST, TEST_DIR as constants 
# --- 2.) check if inside __init__() if we run a binary (compiled version) or a module (not compiled version)
# --- 3.) establish global variable "IS_TEST"
const IS_TEST           = Ref{Bool}()  # some kind of pointer
const TEST_DIR          = Ref{AbstractString}()

function __init__()
    Base.@info(string("--- Enter \"__init__()\" ------------------------------------------- \n "))
    _tmp = Base.@__DIR__
    IS_TEST[] = (Base.cmp(_tmp[2:6], "media") == 0)
    if IS_TEST[]
        _tmp, _ = splitdir(_tmp)
        TEST_DIR[], _ = splitdir(_tmp)
    end
    if IS_DBG; Base.@info(string(" --- Exit \"__init__()\" ------------------------------------------- ")) ; end
end

