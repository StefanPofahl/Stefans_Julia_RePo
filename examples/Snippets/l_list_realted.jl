#: --- snippets around lists:

#: validate that string is in a given list of strings:
sListExt = ["html", "pdf", "svg", "png"]
sFNext = ".pdf"
#: ---
sFNext  = lstrip(sFNext, '.') # remove leading character '.'
if any(x -> x == sFNext, sListExt)
    println("\"sFNext\" = $sFNext is in the list: $(sListExt))")
end


