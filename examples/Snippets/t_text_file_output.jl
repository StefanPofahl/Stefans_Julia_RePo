#: --- snippets around text file output: ---

#: --- File Extention, ensure FNbody + dot + FNextention
# --- clean strings and build complete file name:
sFNbody_in = "Pritty File Name."
sFNext_in  = ".pdf"
sFNbody = rstrip(replace(sFNbody_in, " " => ""), '.') # remove tailing character '.'
sFNext  = lstrip(sFNext_in, '.') # remove leading character '.'
sFNplt  = string(sFNbody, ".", sFNext)
println("sFNbody_in: \"", sFNbody_in, "\", sFNext_in: \"", sFNext_in, "\", sFNplt: \"", sFNplt, "\".")

#: --- File Name Handling
fn = raw"C:\temp\data.csv"

#: --- Write Linux Bash script
if Sys.islinux()
    fn_script = joinpath(homedir(), ".local", "bin", "test_script.sh")
    if isfile(fn_script)
        rm(fn_script, force = true)
    end
    fid = open(fn_script, "a")
    println(fid, "#! /bin/bash")
    println(fid, "echo \"Hello world!\"")
    close(fid)
    # --- make executable:
    Base.Filesystem.chmod(fn_script, 0o500) # +500= a.) execute by user= 100, b.) read by user= 400
    # --- execute:
    cmd_ = Cmd(`konsole --noclose --show-menubar --separate -e ./$fn_script \&`; windows_verbatim=true, detach=true)
    @show cmd_
    # run(cmd_; wait=false)
else
    @warn("works only on linux systems!")
end

