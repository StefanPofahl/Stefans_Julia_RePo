using Plots

# Minimal data (different scales to demonstrate two y-axes)
x  = 0:0.1:10
y1 = sin.(x)          # left y-axis
y2 = 30 .* cos.(x)    # right y-axis (much larger values)

# Plot
Plots.plot(x, y1,
     label     = "sin(x)",
     color     = :blue,
     ylabel    = "Left y-axis (sin)",
     xlabel    = "x",
     legend    = :topleft)

# Add second y-axis (right side)
Plots.plot!(Plots.twinx(), x, y2,
      label   = "30·cos(x)",
      color   = :red,
      ylabel  = "Right y-axis (cos)",
      legend  = :topright)

Plots.title!("Minimal two y-axes example — Plots.jl")