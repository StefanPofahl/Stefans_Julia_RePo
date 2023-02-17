using MacroTools, JuliaVariables
using MLStyle # macro @when (used in "GeneralizedGenerated")
using DataStructures: nil, cons, list, LinkedList # definition of nil()/Nil()
using Base.Threads: SpinLock
# using Base.Threads: lock, unlock, SpinLock
import Serialization # need serialize()
# --- local structs ----------------------------------------------------------------------------------------------------------------------
# --- struc taken from "GeneralizedGenerated.jl" -----------------------------------------------------------------------------------------
struct GGUnset end # original "Unset"
GGunset = GGUnset() # original "GGunset"

struct GGRuntimeFn{Args, Kwargs, Body, Name} end

struct GGBitsValue{L}
    value::L
end

struct GGBuf{N}
    units::NTuple{N, UInt8}
end

struct GGCall{F, Args<:Tuple}
    f::F
    args::Args
end

struct GGExprMeta
    complexity::Int
    inner_lns::Vector{Tuple{Int, GGExprMeta}}
    lns::Vector{Tuple{Int, LineNumberNode}}
end

struct GGTypeLevel{T, BufData} end

struct GGSimpleMeta
    complexity::Int
end

GGSimpleMeta(meta::GGExprMeta) = GGSimpleMeta(meta.complexity)
GGSimpleMeta(meta::GGSimpleMeta) = meta

struct GGFuncHeader  # original "FuncHeader"
    name::Any
    args::Any
    kwargs::Any
    ret::Any
    fresh::Any
end

GGFuncHeader() = GGFuncHeader(GGunset, GGunset, GGunset, GGunset, GGunset)

struct GGFuncArg
    name::Any
    type::Any
    default::Any
end

struct GGArgument
    name::Symbol
    type::Union{Nothing,Any}
    default::Union{GGUnset,Any}
end

# --- constants --------------------------------------------------------------------------------------------------------------------------
const GGCacheComplexityDepthFactor = 2
const GGCacheComplexityThres = 32
const GGRevShiftBits = 2
const GGShiftBits = sizeof(UInt) * 8 - GGRevShiftBits
const GGHAS_FLAGS = UInt(0b11) << GGShiftBits
const GGFLAGS = (Any = UInt(0), Expr = UInt(1), GGCall = UInt(2))
const GGCompactExpr{Args} = Tuple{Symbol, Args}
const GGExprPool = GGCompactExpr[]
const GGExprIndex = Dict{GGCompactExpr, UInt}()
const GGRefValPool = Any[]
const GGRefValIndex = Base.IdDict{Any,UInt}()
const GG_lock = SpinLock()
const GGleaf_meta = GGSimpleMeta(0)
    

# --- local function and macro definitions: ----------------------------------------------------------------------------------------------
# --- functions taken from "GeneralizedGenerated.jl" -------------------------------------------------------------------------------
function gg_compress(val)
    meta, encoded = GG_compress_impl!(val)
    meta isa GGSimpleMeta && return encoded
    (gg_meta_to_tuple(meta), encoded)
end

function gg_get_from_tuple(xs::Tuple, key, default)
    for (k, v) in xs
        k == key && return v
    end
    return default
end

function gg_ass_positional_args!(
    assign_block::Vector{Expr},
    args::LinkedList{GGArgument},
    ninput::Int,
    pargs::Symbol,
    )
    i = 1
    for arg in args
        ass = arg.name
        if arg.type !== nothing
            ass = :($ass::$(arg.type))
        end
        if i > ninput
            arg.default === Unset() && error("Input arguments too few.")
            ass = :($ass = $(arg.default))
        else
            ass = :($ass = $pargs[$i])
        end
        push!(assign_block, ass)
        i += 1
    end
end

function gg_mk_function(ex)
    gg_mk_function(@__MODULE__, ex)
end

function gg_mk_function(mod::Module, ex)
    ex = macroexpand(mod, ex)
    ex = simplify_ex(ex)
    ex = solve!(ex)
    fn = _closure_conv(mod, ex)
    if !(fn isa GGRuntimeFn)
        error("Expect an unnamed function expression. ")
    end
    fn
end

function gg_mk_function(mod::Module, args, kwargs, body)
    gg_mk_function(mod, Expr(:function, :($(args...), ; $(kwargs...)), body))
end
function gg_mk_function(args, kwargs, body)
    gg_mk_function(Main, args, kwargs, body)
end

@generated function gg_field_update(main::T, field::Val{Field}, value) where {T,Field}
    fields = fieldnames(T)
    quote
        $T($([field !== Field ? :(main.$field) : :value for field in fields]...))
    end
end

function gg_meta_to_tuple(meta::GGExprMeta)
    Tuple((i, gg_meta_to_tuple(m)) for (i, m) in meta.inner_lns),
    Tuple((i, ln_to_tuple(l)) for (i, l) in meta.lns)
end

function gg_lens_compile(ex, cache, value)
    @when :($a.$(b::Symbol).$(c::Symbol) = $d) = ex begin
        updated = Expr(
            :let,
            Expr(:block, :($cache = $cache.$b), :($value = $d)),
            :($gg_field_update($cache, $(Val(c)), $value)),
        )
        gg_lens_compile(:($a.$b = $updated), cache, value)
        @when :($a.$(b::Symbol) = $c) = ex
        Expr(
            :let,
            Expr(:block, :($cache = $a), :($value = $c)),
            :($gg_field_update($cache, $(Val(b)), $value)),
        )
        @otherwise
        error("Malformed update notation $ex, expect the form like 'a.b = c'.")
    end
end

function GGwith(ex) # original "with"
    cache = gensym("cache")
    value = gensym("value")
    gg_lens_compile(ex, cache, value)
end
macro GGwith(ex)
    esc(GGwith(ex))
end

function gg_of_args(::GGUnset)
    GGArgument[]
end
function gg_of_args(args::AbstractArray{GGFuncArg})
    ret = GGArgument[]
    for (i, each) in enumerate(args)
        name = each.name === GGunset ? gensym("_$i") : each.name
        type = each.type === GGunset ? nothing : each.type
        arg = GGArgument(name, type, each.default)
        push!(ret, arg)
    end
    return ret
end

function gg_func_arg(@nospecialize(ex))::GGFuncArg
    @switch ex begin
        @case :(::$ty)
        @GGwith gg_func_arg(gensym("_")).type = ty
        @case :($var::$ty)
        @GGwith gg_func_arg(var).type = ty
        @case Expr(:kw, var, default)
        @GGwith gg_func_arg(var).default = default
        @case Expr(:(=), var, default)
        @GGwith gg_func_arg(var).default = default
        @case var::Symbol
        GGFuncArg(var, GGunset, GGunset)
        @case Expr(:..., _)
        error(
            "GG does not support variadic argument($ex) so far.\n" *
            "Try\n" *
            "  f(x...) = _f(x)\n" *
            "  @gg _f(x) = ...\n" *
            "See more at: https://github.com/JuliaStaging/GeneralizedGenerated.jl/issues/38",
        )
        @case _
        error("GG does not understand the argument $ex.")
    end
end


function gg_func_header(@nospecialize(ex))::GGFuncHeader
    @switch ex begin
        @case :($hd::$ret)
        @GGwith gg_func_header(hd).ret = ret

        @case :($f($(args...); $(kwargs...)))
        inter = @GGwith gg_func_header(f).args = map(gg_func_arg, args)
        @GGwith inter.kwargs = map(gg_func_arg, kwargs)

        @case :($f($(args...)))
        @GGwith gg_func_header(f).args = map(gg_func_arg, args)

        @case :($f where {$(args...)})
        @GGwith gg_func_header(f).fresh = args

        @case Expr(:tuple, Expr(:parameters, kwargs...), args...)
        inter = @GGwith GGFuncHeader().args = map(gg_func_arg, args)
        @GGwith inter.kwargs = map(gg_func_arg, kwargs)

        @case Expr(:tuple, args...)
        @GGwith GGFuncHeader().args = map(gg_func_arg, args)

        @case f
        @GGwith GGFuncHeader().name = f
    end
end

function gg_typed_list(::Type{T}, args::T...) where {T}
    foldr(args, init = nil(T)) do e, last
        cons(e, last)
    end
end

function gg_assign_id(pool::AbstractVector, flag::UInt)
    i = length(pool)
    if iszero(i & GGHAS_FLAGS)
        return UInt(i) | (flag << GGShiftBits)
    else
        throw(OverflowError("pool too long"))
    end
end

function GG_lookup!(pool, idx::Integer)
    lock(GG_lock)
    try
        pool[idx]
    finally
        unlock(GG_lock)
    end
end


@static if VERSION < v"1.1"
    function GG_get!(default::Function, d::Base.IdDict{K,V}, @nospecialize(key)) where {K,V}
        val = get(d, key, Base.secret_table_token)
        if val === Base.secret_table_token
            val = default()
            if !isa(val, V)
                val = convert(V, val)::V
            end
            setindex!(d, val, key)
            return val
        else
            return val::V
        end
    end
end
GG_get!(f, d, key) = get!(f, d, key)

function GG_get_id!(pool, index, val, flag)
    lock(GG_lock)
    try
        GG_get!(index, val) do
            id = gg_assign_id(pool, flag)
            push!(pool, val)
            index[val] = id
            id
        end
    finally
        unlock(GG_lock)
    end
end

function gg_from_type(::Type{GGTypeLevel{T, GGBufData}}) where {T, GGBufData}
    compressed = Serialization.deserialize(IOBuffer(UInt8[GGBufData.units...]))
    gg_decompress(compressed)::T
end

decompress_impl(encoded::Symbol, ::Tuple) = encoded
decompress_impl(encoded::GGBitsValue, ::Tuple) = encoded.value
function decompress_impl(encoded::UInt, meta::Tuple)
    flag = (encoded >> GGShiftBits)
    if flag == GGFLAGS.Any
        return GG_lookup!(GGRefValPool, (encoded << GGRevShiftBits >> GGRevShiftBits) + 1)
    elseif flag == GGFLAGS.Expr
        encoded = GG_lookup!(GGExprPool, (encoded << GGRevShiftBits >> GGRevShiftBits) + 1)
        return decompress_impl(encoded, meta)
    elseif flag == GGFLAGS.GGCall
        encoded = GG_lookup!(CallPool, (encoded << GGRevShiftBits >> GGRevShiftBits) + 1)
        return decompress_impl(encoded, meta)
    else
        error("invalid flag $flag")
    end
end
function decompress_impl(encoded::GGCall, ::Tuple)
    f = encoded.f
    args = decompress.(encoded.args)
    f(args...)
end
function decompress_impl(encoded::Tuple, meta::Tuple)
    inner_lns, lns = meta
    head, args = encoded
    ex = Expr(head)
    j = 1
    for i in eachindex(args)
        while j <= length(lns) && lns[j][1] < i
            line, file = lns[j][2]
            push!(ex.args, LineNumberNode(line, file))
            j += 1
        end
        default_meta = ((), ())
        push!(ex.args, decompress_impl(args[i], gg_get_from_tuple(inner_lns, i, default_meta)))
    end
    ex
end

function gg_decompress(encoded::Tuple)
    meta, encoded = encoded
    decompress_impl(encoded, meta)
end
function gg_decompress(encoded)
    default_meta = ((), ())
    decompress_impl(encoded, default_meta)
end

# --- Begin GG_compress_impl! ---
function GG_compress_impl!(val::Ptr{T}) where {T}
    GGleaf_meta, GGCall(Constructor{Ptr{T}}(), tuple(GGBitsValue(UInt(val))))
end
function GG_compress_impl!(val)
    if isbits(val)
        GGleaf_meta, GGBitsValue(val)
    else
        GGleaf_meta, GG_get_id!(GGRefValPool, GGRefValIndex, val, GGFLAGS.Any)
    end
end

GG_compress_impl!(val::Symbol) = (GGleaf_meta, val)
function GG_compress_impl!(ex::Expr)
    args = Any[]
    inner_lns = Tuple{Int, GGExprMeta}[]
    lns = Tuple{Int, LineNumberNode}[]
    i = 0
    maxcomplexity = 1
    for each in ex.args
        if each isa LineNumberNode
            push!(lns, (i, each))
        else
            i += 1
            meta, a = GG_compress_impl!(each)
            push!(args, a)
            if meta !== GGleaf_meta # leaf
                if meta isa GGSimpleMeta || isempty(meta.inner_lns) && isempty(meta.lns)
                else
                    push!(inner_lns, (i, meta))
                end
                maxcomplexity =
                    max(meta.complexity + GGCacheComplexityDepthFactor, maxcomplexity)
            end
        end
    end

    base = (ex.head, Tuple(args))
    if maxcomplexity < GGCacheComplexityThres
        base = GG_get_id!(GGExprPool, GGExprIndex, base, GGFLAGS.Expr)
    end
    GGExprMeta(maxcomplexity, inner_lns, lns), base
end
function GG_compress_impl!(arg::GGArgument)
    meta, default = GG_compress_impl!(arg.default)
    encoded = GGCall(
        Constructor{GGArgument}(),
        tuple(compress(arg.name), compress(arg.type), default),
    )
    may_cache_call(meta, encoded)
end

# --- end GG_compress_impl!() ---

function GG_to_type(x::T) where {T}
    io = IOBuffer()
    Serialization.serialize(io, gg_compress(x))
    seek(io, 0)
    GGTypeLevel{T,GGBuf(Tuple(take!(io)))}
end

function _mkngg(
    name::Symbol,
    args::Vector{GGArgument},
    kwargs::Vector{GGArgument},
    @nospecialize(ex)
    )
    Args = GG_to_type(gg_typed_list(GGArgument, args...))
    Kwargs = GG_to_type(gg_typed_list(GGArgument, kwargs...))
    Ex = GG_to_type(ex)
    return GGRuntimeFn{Args, Kwargs, Ex, name}()
end

function _closure_conv(top::Any, ex::Any)
    function conv(ex::Expr)
        @when Expr(:scoped, scope, inner) = ex begin
            block = Any[]
            for var in scope.bounds
                if var.is_mutable && var.is_shared
                    name = var.name
                    if var.name in scope.bound_inits
                        push!(block, :($name = Core.Box($name)))
                    else
                        push!(block, :($name = Core.Box()))
                    end
                end
            end
            push!(block, conv(inner))
            Expr(:block, block...)
            @when Expr(:function, head, inner && Expr(:scoped, scope, _)) = ex

            freenames = Symbol[f.name for f in scope.freevars]
            # If the evaluation module is a symbol and not in arguments
            if top isa Symbol && all(scope.bounds) do e
                e.name !== top
            end
                push!(freenames, top)
            end

            head = conv(head)
            fh = gg_func_header(head)
            lambda_n = Symbol(:function)
            name = fh.name === GGunset ? lambda_n : fh.name
            fh = @GGwith fh.args = GGFuncArg[map(gg_func_arg, freenames)..., fh.args...]

            if fh.fresh !== GGunset || fh.ret !== GGunset
                error("GG doesn't support type parameters or return type annotations.")
            end

            args = gg_of_args(fh.args)
            kwargs = gg_of_args(fh.kwargs)
            inner = conv(inner)

            fn = _mkngg(Symbol(name), args, kwargs, inner)
            if !isempty(freenames)
                closure_vars = Expr(:tuple, freenames...)
                fn = quote
                    let freevars = $closure_vars
                        $Closure{$fn,Base.typeof(freevars)}(freevars)
                    end
                end
            end

            if name !== lambda_n
                fn = Expr(:block, :($(fh.name) = $fn))
            end
            fn
            @when Expr(hd, args...) = ex
            Expr(hd, map(conv, args)...)
        end
    end

    function conv(s::Var)
        name = s.name
        s.is_global && return :($top.$name)
        s.is_mutable && s.is_shared && return begin
            :($name.contents)
        end
        name
    end
    conv(s) = s

    return conv(ex.args[2])
end

# --- generate GGRuntimeFn ---------------------------------------------------------------------------------------------------------------
const GG_zero_arg = gg_compress(list(GGArgument))
Base.show(io::IO, rtfn::GGRuntimeFn{Args, Kwargs, Body, Name}) where {Args, Kwargs, Body, Name} =
    begin
        args = gg_from_type(Args)
        kwargs = gg_from_type(Kwargs)
        args = join(map(string, args), ", ")
        kwargs = join(map(string, kwargs), ", ")
        body = gg_from_type(Body) |> rmlines
        repr = "$Name = ($args; $kwargs) -> $body"
        print(io, repr)
    end

Base.show(io::IO, ::Type{GGRuntimeFn{Args, Kwargs, Body, Name}}) where {Args, Kwargs, Body, Name} = print(io, "ggfunc-$Name")

@generated function (::GGRuntimeFn{Args, GG_zero_arg, Body})(pargs...) where {Args, Body}
    args = gg_from_type(Args)
    ninput = length(pargs)
    assign_block = Expr[]
    body = gg_from_type(Body)
    gg_ass_positional_args!(assign_block, args, ninput, :pargs)
    quote
        let $(assign_block...)
            $body
        end
    end
end
@generated function (::GGRuntimeFn{Args, Kwargs, Body})(
    pargs...;
    pkwargs...,
    ) where {Args,Kwargs,Body}
    args = gg_from_type(Args)
    kwargs = gg_from_type(Kwargs)
    ninput = length(pargs)
    assign_block = Expr[]
    body = gg_from_type(Body)
    if isempty(kwargs)
        gg_ass_positional_args!(assign_block, args, ninput, :pargs)
    else
        kwds = gensym("kwds")
        feed_in_kwds = _get_kwds(pkwargs)
        push!(assign_block, :($kwds = pkwargs))
        gg_ass_positional_args!(assign_block, args, ninput, :pargs)
        for kwarg in kwargs
            ass = k = kwarg.name
            if kwarg.type !== nothing
                ass = :($ass::$(kwarg.type))
            end
            if k in feed_in_kwds
                ass = :($ass = $kwds[$(QuoteNode(k))])
            else
                default = kwarg.default
                default === Unset() && error("no default value for keyword argument $(k)")
                ass = :($ass = $default)
            end
            push!(assign_block, ass)
        end
    end
    quote
        let $(assign_block...)
            $body
        end
    end
end


# --- functions taken from "EquivalentCirquits.jl" -------------------------------------------------------------------------------
function My_circuitfunction(_circuitstring)
    for (f, t) in zip(["-",  "[",    ","         ,"]"        ],
                      ["+",  "((",   ")^-1+("    ,")^-1)^-1" ])
        _circuitstring = replace(_circuitstring, f => t)
    end
    for I in 2:-1:1
        Es = eachmatch(Regex("([CLRPW])([0-9]){$(I)}"), _circuitstring)
            for e in Es
                _match = e.match
                if _match[1] == 'C'
                    _circuitstring = replace(_circuitstring, _match => "(1/(2im*π*f*"*"T"*"))")
                elseif _match[1] == 'R'
                    _circuitstring = replace(_circuitstring, _match => "T")
                elseif _match[1] == 'L'
                    _circuitstring = replace(_circuitstring, _match => "(2im*π*f*"*"T"*")")
                elseif _match[1] == 'P'
                    _circuitstring = replace(_circuitstring, _match => "(1/("*"T"*"*(2im*π*f)^"*"N"*"))") # compatible to package "impedance.py"
                elseif _match[1] == 'W'
                    _circuitstring = replace(_circuitstring, _match => "T*(2*π*f)^(-0.5)"*"*(cos((π*0.5)*0.5)-sin((π*0.5)*0.5)im)")
            end
        end
    end
    new_circuit = ""
    counter = 1
    for i in _circuitstring
        if i == 'T'
            new_circuit = new_circuit*"T["*string(counter)*"]"
            counter += 1
        elseif i == 'N'
            new_circuit = new_circuit*"T["*string(counter)*"]"
            counter += 1
        else
            new_circuit = new_circuit*i
        end
    end
    circuit_expression = Meta.parse(new_circuit)
    return gg_mk_function([:T, :f], [], circuit_expression)
end
