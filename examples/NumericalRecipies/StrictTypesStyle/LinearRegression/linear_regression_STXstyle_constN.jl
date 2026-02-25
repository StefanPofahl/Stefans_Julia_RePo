#: ------------------------------------------------------------------------------------------------
#: Purpose: Development of a Function Block for PLC-coding (IEC61131-3):
#: Objective: Avoid functions that do not exist in Structured Text (STX)
#: Restriction: Max bit-size of data types is restricted to 32-bit and below
#: Author: Stefan Pofahl, supported by AIchatBOT "Lumo" by Proton
#: Simplified case: Moving window is fixed to n = 10 
#: ------------------------------------------------------------------------------------------------

#: ------------------------------------------------------------------------------------------------
#: Purpose:         Development of a Function Block for PLC-coding (IEC61131-3):
#: Objective:       Avoid functions that do not exist in Structured Text (STX)
#: Restriction:     Max bit-size of data types is restricted to 32-bit and below
#: Simplification:  Moving window is fixed to n = 10 
#: Coding Style:    The code should be close to the one in the STX-project.
#: Author:          Stefan Pofahl, supported by AIchatBOT "Lumo" by Proton
#: ------------------------------------------------------------------------------------------------
using Statistics
using CairoMakie, ElectronDisplay
const rCstSumX = Float32(55)            # Σx  (const for 1…n); n = 10 --> 55
const rCstSlopeNominator = Float32(825) # n·Σx² – (Σx)²; n = 10 --> 825
const iCstBufferSize = Int16(10)
#: --- Params: 
iNumberOfPts = 50
rAngleStartPt = 0.25*pi
rNoiseRate = 0.2  # Increase frequency / rate of noise disturbance, should be between [0.0 .. 0.2]
rNoiseFact = 0.5  # Increases hight of noise, rNoiseFact * randn(), should be inside [0.0 .. 2.0]

#: --- Initial checks:
if rNoiseRate >= 0.0 || rNoiseRate > 0.2
    error("rNoiseRate: $rNoiseRate outside linits of [0.0 .. 0.2]")
end
if rNoiseFact < 0.0 || rNoiseFact > 2.0
    error("rNoiseFact: $rNoiseFact outside linits of [0.0 .. 2.0]")
end
#: --- Function Definition: -----------------------------------------------------------------------
function make_LR()
    rBuffer = collect(Float32, range(0, 0, 10))
    function LR10(x)
        rSumY = Float32(0)
        rSumXY = Float32(0)
        # --- rotate buffer:
        for i = 1 : iCstBufferSize - 1 
            rBuffer[i] = rBuffer[i + 1]
        end
        rBuffer[iCstBufferSize] = x
        # --- calc rSumY and rSumXY:
        for i = 1 : iCstBufferSize
            rSumY = rSumY + rBuffer[i]
            rSumXY = rSumXY + i * rBuffer[i]
        end
        # ---
        rSlope = (iCstBufferSize * rSumXY - rCstSumX * rSumY ) / rCstSlopeNominator
        rIntercpt_vals = (rSumY - rSlope * rCstSumX) / iCstBufferSize
        rLrRegr = rSlope * iCstBufferSize + rIntercpt_vals
        # ---
        return rLrRegr, rSlope, rIntercpt_vals
    end
    return LR10
end
# --- Create the function (initialization happens now)
const LR10 = make_LR()

# ---- 2️⃣  Hilfsfunktion, die das Signal erzeugt und die Regression anwendet ----
function myrun()
    inc   = Float32(2π / 65535)           # Schrittweite für den Sinus
    angle = Float32(rAngleStartPt)
    #: --- Optional: Arrays zum späteren Plotten / Analysieren
    y_vals          = Vector{Float32}(undef, iNumberOfPts)
    y_reg_vals      = Vector{Float32}(undef, iNumberOfPts)
    rSlope_vals     = Vector{Float32}(undef, iNumberOfPts)
    rIntercpt_vals  = Vector{Float32}(undef, iNumberOfPts)
    #: ---
    for i in 1:length(y_vals)
        angle += inc
        noise = 0.0
        if rand() < rNoiseRate
            noise = rNoiseFact * randn()
        end
        y = sin(angle) + noise                 # Messwert
        y_vals[i] = y
        y_reg, rSlope_vals[i], rIntercpt_vals[i] = LR10(y)
        y_reg_vals[i] = y_reg                # geschaetzter Wert
        # (slope, intercept) können Sie bei Bedarf speichern
    end
    return y_vals, y_reg_vals, rSlope_vals, rIntercpt_vals
end

# ---- 3️⃣  Ausführen -------------------------------------------------------
rProcessValues     = Vector{Float32}(undef, iNumberOfPts)
rLrRegressedValues = Vector{Float32}(undef, iNumberOfPts)
rSlope_vals        = Vector{Float32}(undef, iNumberOfPts)
rIntercpt_vals     = Vector{Float32}(undef, iNumberOfPts)
#: ---
rProcessValues, rLrRegressedValues, rSlope_vals, rIntercpt_vals = myrun()
rXvalues     = collect(1:iNumberOfPts)

# ---- 4️⃣  Schnell‑Check (Mittelwerte, Peak‑to‑Peak) --------------------
println("Mean of measured:   ", Statistics.mean(rProcessValues))
println("Mean of regressed:  ", Statistics.mean(rLrRegressedValues))
println("PtP measured:       ", Statistics.maximum(rProcessValues) - minimum(rProcessValues))
println("PtP regressed:      ", Statistics.maximum(rLrRegressedValues) - minimum(rLrRegressedValues))
#: --- Plotfunctions:
function plot_regression()
    fig = Figure()
    ax1 = Axis(fig[1, 1], yticklabelcolor = :blue, xlabel = "n Iterations / -",   ylabel = "Cycle Counter / -")  
    hln1 = lines!(ax1, rXvalues[10:iNumberOfPts],  rProcessValues[10:iNumberOfPts],      label= "Measured")
    hln2 = lines!(ax1, rXvalues[10:iNumberOfPts],  rLrRegressedValues[10:iNumberOfPts],  color = :red, label= "Regressed")
    Legend(fig[1, 2], ax1)
    CairoMakie.display(fig)
    # ---
end
#: ---
function plot_slope_intercept()
    fig = CairoMakie.Figure()
    ax1 = CairoMakie.Axis(fig[1, 1], yticklabelcolor = :blue, xlabel = "n Iterations / -", ylabel = "Slope / -")  
    ax2 = CairoMakie.Axis(fig[1, 1], yticklabelcolor = :blue, xlabel = "", ylabel = "Intercept / -",    yaxisposition = :right)  
    hln1 = CairoMakie.lines!(ax1, rXvalues[10:iNumberOfPts], rSlope_vals[10:iNumberOfPts],     label  = "Slope")
    hln2 = CairoMakie.lines!(ax2, rXvalues[10:iNumberOfPts], rIntercpt_vals[10:iNumberOfPts],  color  = :red, label= "Intercept")
    # Legend(fig[1, 2], ax1)
    CairoMakie.Legend(fig[1, 2],
       [hln1, hln2],
       ["Slope", "Intercept"],)
    CairoMakie.display(fig)
    # ---
end
println(size(rSlope_vals))
println(size(rIntercpt_vals))
#: --- Call Plot Functions:
plot_regression()
# plot_slope_intercept()
