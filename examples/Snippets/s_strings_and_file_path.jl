#: snippets around strings and file path.

sFNbody = raw"C:\tmp\plot."  # complete filename path without file extention, path must exist.
sFNext = ".pdf"               # options: "png", "svg", "pdf", "html", if not in the list skip "save" to file.

# --- clean strings and build complete file name:
sFNbody = rstrip(sFNbody, '.') # remove tailing character '.'
sFNext  = lstrip(sFNext, '.') # remove leading character '.'
sFNplt  = string(sFNbody, ".", sFNext)
println("\"sFNplt\": $sFNplt")
# --- build file path with the system specific path delimiter: "\" (MS-WIN), "/" (Linux, Mac OS):
sFNbody = joinpath(["c:\\", "tmp", "plot"])
println("\"sFNbody\": $sFNbody")
