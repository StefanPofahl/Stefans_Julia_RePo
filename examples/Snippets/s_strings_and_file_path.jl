#: snippets around strings and file path.

sFNbody = raw"C:\tmp\plot."  # complete filename path without file extention, path must exist.
sFNext = ".pdf"               # options: "png", "svg", "pdf", "html", if not in the list skip "save" to file.

# --- clean strings and build complete file name:
# --- clean strings and build complete file name:
sFNbody_in = "Pritty File Name."
sFNext_in  = ".pdf"
sFNbody = rstrip(replace(sFNbody_in, " " => ""), '.') # remove tailing character '.'
sFNext  = lstrip(sFNext_in, '.') # remove leading character '.'
sFNplt  = string(sFNbody, ".", sFNext)
println("sFNbody_in: \"", sFNbody_in, "\", sFNext_in: \"", sFNext_in, "\", sFNplt: \"", sFNplt, "\".")

# --- build file path with the system specific path delimiter: "\" (MS-WIN), "/" (Linux, Mac OS):
sFNbody = joinpath(["c:\\", "tmp", "plot"])
println("\"sFNbody\": $sFNbody")

# --- build path:
fullpath_of_file = joinpath(homedir(), ".local", "bin", "test_script.sh")
# --- ensure file path exists:
mkpath(dirname(fullpath_of_file))

# --- strip file-extention from full path
path_without_ext = splitext(fullpath_of_file)[1]

#: --- Vollständiger Dateipfad => Dateiname und Pfad:
dirname(fullpath_of_file)   # → "C:\\temp\\data\\log\\plt"
basename(fullpath_of_file)  # → "speed_and_forces_DBG_slow.html"
