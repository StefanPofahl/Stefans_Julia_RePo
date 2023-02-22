module MyAppHelloTulip
import Tulip
if VERSION >= v"1.7.0"
    using LLVMExtra_jll
end

# ---
function julia_main()::Cint
    try
        if isempty(ARGS)
            real_main(string("Tulip Version: v", Tulip.version()))
        else
            real_main(ARGS[1])
        end
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
return 0 # if things finished successfully
end                                                                               
  
function real_main(_s::AbstractString) 
    return println(_s)
end

end # module
