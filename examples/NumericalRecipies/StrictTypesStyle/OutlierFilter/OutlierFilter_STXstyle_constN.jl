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
#: --- Constants:
const rCstDeviationThrhld = Float32(0.2) # Value of 0.2 means a deviation of 20% between expected and measured.
const rCstSumX = Float32(55)             # Σx  (const for 1…n); n = 10 --> 55
const rCstSlopeNominator = Float32(825)  # n·Σx² – (Σx)²; n = 10 --> 825
const iCstBufferSize = Int16(10)
#: --- Params: 
iNumberOfPts = 1000
rAngleStartPt = 0.25*pi
rNoiseRate   = 0.8  # Increase frequency / rate of noise disturbance, should be between [0.5 .. 0.9]
rNoiseFact   = 0.8  # Increases hight of noise, rNoiseFact * randn(), should be inside [0.0 .. 2.0]

#: --- Initial checks and others:
if rNoiseRate < 0.5 || rNoiseRate > 0.9
    error("rNoiseRate: $rNoiseRate outside linits of [0.5 .. 0.9]")
end
if rNoiseFact < 0.0 || rNoiseRate > 2.0
    error("rNoiseFact: $rNoiseFact outside linits of [0.0 .. 2.0]")
end
rXvalues = collect(1:iNumberOfPts)
#: --- Function Definition: -----------------------------------------------------------------------
function make_OLfilter()
    rBuffer = collect(Float32, range(0, 0, 10))
    function OLfilter10(x)
        rSumY = Float32(0)
        rSumXY = Float32(0)
        rSumDiff = Float32(0)
        rLrRegrExpct = collect(Float32, range(0, 0, 10))
        rDiff = collect(Float32, range(0, 0, 10))
        xExeeds = false
        iIndxDiffMax = 0
        rDiffMax = Float32(0)
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
        rIntercept = (rSumY - rSlope * rCstSumX) / iCstBufferSize
        # --- calc expected value for each measured value:
        rDiffMax = 0.0;
        for i = 1 : iCstBufferSize
            rLrRegrExpct[i] = rSlope * i + rIntercept
            rDiff[i] = abs(rBuffer[i] - rLrRegrExpct[i])
            rSumDiff = rSumDiff + rDiff[i]
            if rDiff[i] > rDiffMax
                rDiffMax = rDiff[i]
                iIndxDiffMax = i
            end
        end
        # iIndxDiffMax = findfirst(==(maximum(rDiff)), rDiff)
        rDiffMean = rSumDiff / iCstBufferSize
        if rDiffMean > 0.0 && iIndxDiffMax > 0 # avoid division by zero.
            rDiffMax  = rDiff[iIndxDiffMax]
            if (rDiffMax - rDiffMean) / rDiffMean > rCstDeviationThrhld
                rBuffer[iIndxDiffMax] = rLrRegrExpct[iIndxDiffMax]
                xExeeds = true
            end
        end
        #: --- 2nd run (without the outlier):
        rSumY = Float32(0)
        rSumXY = Float32(0)
        for i = 1 : iCstBufferSize
            rSumY = rSumY + rBuffer[i]
            rSumXY = rSumXY + i * rBuffer[i]
        end
        # ---
        rSlope = (iCstBufferSize * rSumXY - rCstSumX * rSumY ) / rCstSlopeNominator
        rIntercept = (rSumY - rSlope * rCstSumX) / iCstBufferSize
        rLrRegr = rSlope * iCstBufferSize + rIntercept
        #: --- compromise: in the middle between measured and expected:
        rLrRegr = 0.5 * (rBuffer[iCstBufferSize] + rLrRegr)
        # ---
        return rLrRegr, xExeeds, rDiff
    end
    return OLfilter10
end
# --- Create the function (initialization happens now)
const OLfilter10 = make_OLfilter()

# ---- 2️⃣  Hilfsfunktion, die das Signal erzeugt und die Regression anwendet ----
function myrun()
    inc   = Float32(2π / 65535)           # Schrittweite für den Sinus
    angle = Float32(rAngleStartPt)
    #: --- Optional: Arrays zum späteren Plotten / Analysieren
    y_vals          = Vector{Float32}(undef, iNumberOfPts)
    y_reg_vals      = Vector{Float32}(undef, iNumberOfPts)
    xExeeds         = Vector{Bool}(undef,    iNumberOfPts)
    #: ---
    for i in 1:iNumberOfPts
        angle += inc
        noise = 0.0
        if rand() > rNoiseRate
            noise = rNoiseFact * randn()
        end
        y = sin(angle) + noise                 # Messwert
        y_vals[i] = y
        y_reg_vals[i], xExeeds[i], _ = OLfilter10(y) 
    end
    return y_vals, y_reg_vals, xExeeds
end

# ---- 3️⃣  Ausführen -------------------------------------------------------

rProcessValues      = Vector{Float32}(undef, iNumberOfPts)
rLrRegressedValues  = Vector{Float32}(undef, iNumberOfPts)
xExeedsValues       = Vector{Bool}(undef, iNumberOfPts)

#: ---
rProcessValues, rLrRegressedValues, xExeedsValues = myrun()

# ---- 4️⃣  Schnell‑Check (Mittelwerte, Peak‑to‑Peak) --------------------
println("Mean of measured:  ", Statistics.mean(rProcessValues))
println("Mean of filtered:  ", Statistics.mean(rLrRegressedValues))
println("PtP measured:      ", Statistics.maximum(rProcessValues) - minimum(rProcessValues))
println("PtP filtered:      ", Statistics.maximum(rLrRegressedValues) - minimum(rLrRegressedValues))
#: --- Plotfunctions:
function plot_regression()
    fig = Figure()
    ax1 = Axis(fig[1, 1], yticklabelcolor = :blue, xlabel = "n Iterations / -",   ylabel = "Cycle Counter / -")  
    hln1 = lines!(ax1, rXvalues[10:iNumberOfPts],  rProcessValues[10:iNumberOfPts],      label= "Measured")
    hln2 = lines!(ax1, rXvalues[10:iNumberOfPts],  rLrRegressedValues[10:iNumberOfPts],  color = :red, label= "Filtered")
    # CairoMakie.axislegend(ax1, merge = merge, unique = unique)
    CairoMakie.Legend(fig[1, 2], ax1)
    CairoMakie.display(fig)
    # ---
end
#: --- Call Plot Functions:
plot_regression()
