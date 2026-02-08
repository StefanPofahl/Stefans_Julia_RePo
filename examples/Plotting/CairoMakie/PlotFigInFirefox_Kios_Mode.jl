#: I do not know if package "GLMakie" is better here?
#: I prefere "CairoMakie" because of the option to plot in vector formats (e.g. SVG)
using CairoMakie

function display_in_FF(_fig::Makie.FigureAxisPlot, _fn::AbstractString, _kioskmode::Bool=true,
    _browser_path::AbstractString=raw"C:\Program Files\Mozilla Firefox\firefox.exe")
    # ---
    CairoMakie.save(_fn, _fig)
    _uri = "file:///" * replace(replace(_fn, "\\"=>"/"), "C:"=>"C%3A")
    if _kioskmode
        println("--- Plot in Firefox Kiosk Mode! ---")
        run(`$_browser_path --kiosk $_uri`)
    else
        println("--- Plot in Firefox Standard Mode! ---")
        run(`$_browser_path $_uri`)
    end
end
FNfig = raw"c:\tmp\plt.html"
fig = CairoMakie.scatter(rand(10), rand(10))
display_in_FF(fig, FNfig);
