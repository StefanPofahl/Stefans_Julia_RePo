# *********************************************************************************************** #
# ---  about the soft-scope inside "try-catch"                                                --- #
# *********************************************************************************************** #
global content_outer_global_A = []; global content_outer_global_B = []; content_outer_A = [] 

# *********************************************************************************************** #
# ---  remark: it is redundant to declare variables on the top main level as global           --- #
# ---  2nd remark: if you use try-catch in project for stand alone applications via           --- #
# ---  "PackageCompiler" the behaviour of the soft-scope try-catch environment might be       --- #
# ---  might differ from the behaviour outside an compiled binary.                            --- #
# *********************************************************************************************** #

fn_ = tempname(); 
io  = open(fn_, "w");       write(io, "Hello Julia!");      close(io)

# --- local functions:
function f1(_fn::AbstractString)
    try
        global _content = read(_fn, String)
        println("f1, inside try-catch: ", _content)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    println("f1, outside try-catch: ", _content)
end

function f2(_fn::AbstractString)
    global _content = ""
    try
        _content = read(_fn, String)
        println("f2, inside try-catch: ", _content)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    println("f2, outside try-catch: ", _content)
end

function f3(_fn::AbstractString)
    try
        content_outer_global_B = read(_fn, String)
        println("f3, inside try-catch: ", content_outer_global_B)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    println("f3, outside try-catch: ", content_outer_global_B)
end

function f4(_fn::AbstractString)
    try
        global content_outer_global_B = read(_fn, String)
        println("f4, inside try-catch: ", content_outer_global_B)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    println("f4, outside try-catch: ", content_outer_global_B)
end

function f5(_fn::AbstractString)
    try
        content_outer_A = read(_fn, String)
        println("f5, inside try-catch: ", content_outer_A)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
    end
    println("f5, outside try-catch: ", content_outer_A)
end

# --- main ----------------------------------------------------------------------------------------
println("\n--- Case 1: create a new global variable inside of soft scope of try-catch")
try
    global content_ = read(fn_, String)    
    println("Main, inside try-catch: ", content_)
catch
    Base.invokelatest(Base.display_error, Base.catch_stack())
end
println("Main, outside try-catch: ", content_)

# -------------------------------------------------------------------------------------------------
println("\n--- Case 2: map inside soft scope with an outside global variable")
try
    # -- inside try-catch we are in soft scope, 
    # -- put global to map with the global variable of the same name
    global content_outer_global_A = read(fn_, String)    
    println("Main, inside try-catch, content_outer_global_A: ", content_outer_global_A)
catch
    Base.invokelatest(Base.display_error, Base.catch_stack())
end
println("Main, outside try-catch, content_outer_global_A: ", content_outer_global_A)

# -------------------------------------------------------------------------------------------------
println("\n--- Case 3: f1()")
f1(fn_)
# -------------------------------------------------------------------------------------------------
println("\n--- Case 4: f2()")
f2(fn_)
# -------------------------------------------------------------------------------------------------
println("\n--- Case 5: f3(), use in soft scope variable declared as global on top level")
f3(fn_)
# -------------------------------------------------------------------------------------------------
println("\n--- Case 6: f4()")
f4(fn_)
# -------------------------------------------------------------------------------------------------
println("\n--- Case 7: f5()")
f5(fn_)

