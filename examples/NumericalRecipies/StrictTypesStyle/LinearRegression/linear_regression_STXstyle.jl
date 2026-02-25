# include(raw"C:\temp\VS_Project_Diverses\julia\lumo_linear_regression\lumo_linear_regression.jl")
#: ------------------------------------------------------------------------------------------------
#: Purpose: Development of a Function Block for PLC-coding (IEC61131-3):
#: Objective: Avoid functions that do not exist in Structured Text (STX)
#: Restriction: Max bit-size of data types is restricted to 32-bit and below
#: Author: Stefan Pofahl, supported by AIchatBOT "Lumo" by Proton
#: ------------------------------------------------------------------------------------------------

using Statistics
using CairoMakie, ElectronDisplay
const ELECTRON_DISPLAY_ACTIVE = Ref{Bool}(false)
#: ------------------------------------------------------------------------------------------------
#: Persistenter Ring‑Puffer für die letzten n Messwerte
#: instances mutable composite type are modifiable
#: Restrict T to primitive types with bit-size ≤ 32
#: Acceptable types: Float32, Float16, Int32, Int16, Int8, UInt32, UInt16, UInt8
#: ------------------------------------------------------------------------------------------------

mutable struct LinearRegressor{T <: Union{Float32, Float16, Int32, Int16, Int8, UInt32, UInt16, UInt8}}
    n::UInt8               # Fenstergröße
    buf::Vector{T}         # Ring‑Puffer
    idx::UInt8             # Position des nächsten Einfügens (1‑basiert)
    sum_y::T               # Σy über das aktuelle Fenster
    sum_xy::T              # Σx·y über das aktuelle Fenster
    sum_x::Int32           # Σx  (konstant für 1…n)
    sum_x2::Int32          # Σx² (konstant für 1…n)
    denom::T               # n·Σx² – (Σx)²  (konstant, kann vorab berechnet werden)

    # collect(Int64, 1:nSize);
    # typeassert(x, type)

    function LinearRegressor{T}(n::UInt8)  where {T <: Union{Float32, Float16, Int32, Int16, Int8, UInt32, UInt16, UInt8}}
        buf = fill(zero(T), n)                 # leere Puffer‑Slots
        sum_x  = n * (n + 1) ÷ 2               # Σx  = 1+2+…+n
        sum_x2 = n * (n + 1) * (2n + 1) ÷ 6    # Σx² = 1²+2²+…+n²
        denom  = n * sum_x2 - sum_x^2
        new{T}(n, buf, 1, zero(T), zero(T), Int32(sum_x), Int32(sum_x2), T(denom))
    end
end
#: ------------------------------------------------------------
#: Einen neuen Messwert einfügen und aktuelle Regression zurückgeben
#: ------------------------------------------------------------
function update!(lr::LinearRegressor{T}, y_new::T)  where {T}
    n = lr.n

    # ----- alten Beitrag entfernen (falls Puffer bereits gefüllt) -----
    old_y = lr.buf[lr.idx]          # Wert, der gerade überschrieben wird
    lr.sum_y  -= old_y
    lr.sum_xy -= T(lr.idx) * old_y   # x‑Koordinate = aktuelle Indexposition

    # ----- neuen Wert eintragen --------------------------------------
    lr.buf[lr.idx] = y_new
    lr.sum_y  += y_new
    lr.sum_xy += T(lr.idx) * y_new

    # ----- Index für das nächste Schreiben vorbereiten (Ring‑Verhalten) -----
    lr.idx = lr.idx % n + 1

    # ----- Regression ---------------------------------------------------------
    # Schutz: erst wenn das Fenster komplett gefüllt ist (denom ≠ 0)
    if lr.denom == 0
        return (T(NaN), T(NaN), T(NaN)) # Initial output value of: β, n,  α
    end

    β = (n * lr.sum_xy - lr.sum_x * lr.sum_y) / lr.denom
    α = (lr.sum_y - β * lr.sum_x) / n

    # Vorhersage für das aktuelle x‑Wert (letztes Element im Fenster = n)
    y_pred = β * n + α
    return (y_pred, β, α)
end
# --- Beispiel‑Signal (Sinus)
# ---- 1️⃣  Instanz erzeugen (Fenstergröße = 10, wie im Originalcode) ----
n_window = UInt8(10)
lr = LinearRegressor{Float32}(n_window)

# ---- 2️⃣  Hilfsfunktion, die das Signal erzeugt und die Regression anwendet ----
function myrun(lr::LinearRegressor{Float32})
    inc   = Float32(2π / 65535)           # Schrittweite für den Sinus
    angle = Float32(0.0)
    # Optional: Arrays zum späteren Plotten / Analysieren
    y_vals      = Vector{Float32}(undef, 100_010)
    y_reg_vals  = Vector{Float32}(undef, 100_010)

    for i in 1:length(y_vals)
        angle += inc
        y = sin(angle)                       # Messwert
        y_vals[i] = y

        y_reg, slope, intercept = update!(lr, y)
        y_reg_vals[i] = y_reg                # geschaetzter Wert
        # (slope, intercept) können Sie bei Bedarf speichern
    end
    return y_vals, y_reg_vals
end

# ---- 3️⃣  Ausführen -------------------------------------------------------
rProcessValues, rLrRegressedValues = myrun(lr)
iNumberOfPts = size(rProcessValues)[1]
rXvalues = collect(1:iNumberOfPts)

# ---- 4️⃣  Schnell‑Check (Mittelwerte, Peak‑to‑Peak) --------------------
println("Mean of measured:    ", Statistics.mean(rProcessValues))
println("Mean of regressed:  ", Statistics.mean(rLrRegressedValues))
println("PtP measured:       ", Statistics.maximum(rProcessValues) - minimum(rProcessValues))
println("PtP regressed:     ", Statistics.maximum(rLrRegressedValues) - minimum(rLrRegressedValues))
# ---
function plotme()
    fig = Figure()
    ax1 = Axis(fig[1, 1], yticklabelcolor = :blue, xlabel = "n Iterations / -", ylabel = "Cycle Counter / -")  
    hln1 = lines!(ax1, rXvalues[10:iNumberOfPts], rProcessValues[10:iNumberOfPts],      label= "Measured_")
    hln2 = lines!(ax1, rXvalues[10:iNumberOfPts], rLrRegressedValues[10:iNumberOfPts],  color = :red, label= "Regressed")
    Legend(fig[1, 2], ax1)
    CairoMakie.display(fig)
    # ---
end
plotme()
