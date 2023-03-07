
s_module = "MyAppHelloTulip.jl"
fn_module = joinpath(@__DIR__, s_module)
s_julia = raw"C:\bin\juliaLTS\bin\julia.exe"
# ---
if ~isfile(fn_module)
    error("File \"$fn_module\" not found!" )
end

if false
    include(fn_module)
    Main.MyAppHelloTulip.__init__()
    Main.MyAppHelloTulip.julia_main()
    @info(string("\nMyAppHelloTulip.version(): ", Main.MyAppHelloTulip.version()))
else
    _sub_dir, _ = splitdir(@__DIR__())
    _root_dir, _ = splitdir(_sub_dir)
    _tmp_test_bat = joinpath(_root_dir, "tmp_test_module.bat")
    _tmp_command = string(s_julia, " ", fn_module        )    
    # _tmp_command = string(s_julia, " ", fn_module, " \"Hello Julia!\""        )    
    _tmp_command = string(s_julia, " ", fn_module, " \"Hello Julia!\" \"dbg\""        )    
    io = open(_tmp_test_bat, "w")
        println(io, _tmp_command)
    close(io)
    cmd_ = Cmd(`cmd /c start \"\" $_tmp_test_bat`; windows_verbatim=true, detach=true)
    println(cmd_)
    run(cmd_; wait=false)
end


