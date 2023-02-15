using WGLMakie
using JSServe, Chain
using Markdown
# --- local functions:
function save_html(_plt::Makie.FigureAxisPlot, _fn::AbstractString)
    _, fn_ext = splitext(_fn)
    if cmp(uppercase(fn_ext), ".HTML") != 0
        error("Wrong file type!")
    end
    plt_dir, fn_ = splitdir(_fn)
    exp_fn = joinpath(plt_dir, "index.html")
    JSServe.export_standalone(App(hdl_plt), plt_dir; single_html=true);
    try
        mv(exp_fn, _fn; force = true)
    catch exptn
        @warn "Problems to rename output file \"index.html\"" exception=(exptn, catch_backtrace())
    end    
end
# --- source: https://www.juliabloggers.com/how-to-check-the-version-of-a-package/
get_pkg_version(name::AbstractString) =
    @chain Pkg.dependencies() begin
        values
        [x for x in _ if x.name == name]
        only
        _.version
end

# --- plot:
Page(exportable=true, offline=true) # for Franklin, you still need to configure
WGLMakie.activate!()
hdl_plt = scatter(1:4, color=1:4)
# display(hdl_plt) does not work inside VScode

# --- save to html:
fn_ = "/home/stefan/tmp/plt/foo.html"
if get_pkg_version("JSServe") < v"2.1"
    save_html(hdl_plt, fn_)
else
    JSServe.export_static(fn_, App(hdl_plt))
end



