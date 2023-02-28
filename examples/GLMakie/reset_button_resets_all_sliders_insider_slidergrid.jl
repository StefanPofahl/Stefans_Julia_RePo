# ----------------------------------------------------------------------------------------------------------------------------- #
# --- Rest button that resets all sliders inside a SliderGrid:                                                                  #
# ----------------------------------------------------------------------------------------------------------------------------- #
using GLMakie

fig = Figure()
# --- figure set-up: two panes side by side, right one with two sub-panes: 
# --- left pane:
ax = Axis(fig[1, 1]) 

# --- right pane contains two sub-panes: [1,1]: top, [2,1]: bottom
# --- SliderGrid: right pane, top sub-pane:
sg = SliderGrid(  fig[1, 2][1, 1], 
    (; label = "Voltage",     range = 0:0.1:10, format = "{:.1f}V", startvalue = 5.3),
    (; label = "Current",     range = 0:0.1:20, format = "{:.1f}A", startvalue = 10.2),
    (; label = "Resistance",  range = 0:0.1:30, format = "{:.1f}Ω", startvalue = 15.9),
    width = 350,
    tellheight = false,
    )

# --- Button: right pane, bottom sub-pane:
bt = Button(fig[1, 2][2, 1]; label = "reset", tellheight = false, strokecolor = RGBf(0.94, 0.14, 0.24), strokewidth = 4)

# access elements inside slidergrid, each element is of type "Observable{Any}(Float64)"
# variable sliderobservables is a vector of "Observable{Any}(Float64)"
sliderobservables = [s.value for s in sg.sliders]

# build a vector of type "Observable" containing the value of each slider inside slider grid:
bars = lift(sliderobservables...) do slvalues...
    [slvalues...]
end

# reset all sliders inside SliderGrid "sg"
on(bt.clicks) do n # n = number of clicks
    for i_slider in sg.sliders
        set_close_to!(i_slider, i_slider.startvalue[])
    end
end

barplot!(ax, bars, color = [:yellow, :orange, :red])
ylims!(ax, 0, 30)

display(fig)
