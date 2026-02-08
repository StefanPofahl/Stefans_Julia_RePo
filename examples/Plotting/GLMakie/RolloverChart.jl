#: --- Rollover Charts: Plot the Phenomena of "rollover" ---------------------------------------- #
#: Unsigned integer rollover wraps around from the maximum value to zero,                         #
#: and from zero to the maximum value when underflowing, forming modular arithmetic modulo 2ⁿ.    #
#: Case below refers back to:                                                                     #
#: an Odometer output in form of UINT16/UInt16 values, ascending or descending                    #
#: Task:                                                                                          #
#: Determine the distance between current and previous value of odometer output                   #
#: ---------------------------------------------------------------------------------------------- #
#: Tricks / methods used:
#: * GLMakie: Easy handling of multiple axis inside a plot. 
#: * Symbol(): utilize this function to use a string variable instead of a literal "string".
#: * any(x -> x == sFNext, sListExt): To analyse if string is inside a list.
#: * lstrip(), rstrip(): To ensure proper filename, with only one point "." before the file name extention
#: --- Version / Date / Author ------------------------------------------------------------------ #
#: Version: 1.0, Date: 27-Jan-2026, Author: Stefan N. Pofahl                                      #
#: --- load packages and define constants: ------------------------------------------------------ #
using GLMakie
using Statistics
using CairoMakie
sListExt = ["html", "pdf", "svg", "png"]
# --- User Params: ------------------------------------------------------------------------------ #
xAscending = true
nSize = 70000           # number of points 
uiStepZize::UInt16 = 1  # x-distance of plotted points
#: distance between current and previous point.
uiDist::UInt16 = 1000   # max: 65535, half: 32767.5, last operational: 32768
uiStartValue::UInt16 = 30000 # start point of the plot
sFNbody = raw"C:\tmp\plot."  # complete filename path without file extention, path must exist.
sFNext = "pdf"               # options: "png", "svg", "pdf", "html", if not in the list skip "save" to file.

# --- clean strings and build complete file name:
sFNbody = rstrip(sFNbody, '.') # remove tailing character '.'
sFNext  = lstrip(sFNext, '.') # remove leading character '.'
sFNplt  = string(sFNbody, ".", sFNext)

# --- to handle global <-> local variables issue outside the for-loop, we put all in a function.
function plotme()
    Xvec = collect(Int64, 1:nSize);
    VectorDistValues = collect(Int64, 1:nSize);
    VectorCurrent    = collect(Int64, 1:nSize);
    VectorPrivious   = collect(Int64, 1:nSize);
    # uiAvec = collect(UInt16, 1:nSize); 
    # Parameter
    uiNext::UInt16 = 0
    uiPrev::UInt16 = 0
    # --- script ------------------------------------
    for i = 1:nSize
        Xvec[i] = i
        if i == 1
            uiNext = uiStartValue
        else
            if xAscending
                uiNext = uiNext + uiStepZize
            else
                uiNext = uiNext - uiStepZize
            end
        end
        if xAscending
            uiPrev = uiNext - uiDist
        else
            uiPrev = uiNext + uiDist
        end
        VectorCurrent[i]    = uiNext
        VectorPrivious[i]   = uiPrev
        VectorDistValues[i] = min(uiNext - uiPrev, uiPrev - uiNext)
    end
    fig = Figure()
    ax1 = Axis(fig[1, 1], yticklabelcolor = :blue)
    ax2 = Axis(fig[1, 1], yticklabelcolor = :red, yaxisposition = :right)
    hln1 = lines!(ax1, Xvec, VectorDistValues)
    hln2 = lines!(ax2, Xvec, VectorCurrent,  color = :red)
    hln3 = lines!(ax2, Xvec, VectorPrivious, color = :orange)    
    display(fig)
    println("Mean Dist: $(Statistics.mean(VectorDistValues))")
    if any(x -> x == sFNext, sListExt)
        if cmp(sFNext, "pdf")==0 || cmp(sFNext, "svg")==0
            println("CairoMakie.activate!()")
            CairoMakie.activate!(type = Symbol(sFNext))
        end
        save(sFNplt, fig)
        println("\"$sFNplt\" plotted!")
    else
        println("File extention: $sFNext is not in the list of suitable file extentions!")
    end
end
# ---
plotme()
