# ----------------------------------------------------------------------------------------------------------------------------- #
# --- Two slider are coupled, if you move one, the other moves as well:                                                         #
# --- source:
# --- https://discourse.julialang.org/t/coupling-sliders-in-glmakie/88130/3                                                     #
# ----------------------------------------------------------------------------------------------------------------------------- #


using GLMakie

figure = Figure()

# create two sliders
slider1, slider2 =
    SliderGrid(
        figure[2, 1],
        (; label = "Slider 1", range = -1:0.01:1),
        (; label = "Slider 2", range = -1:0.01:1),
    ).sliders

# create a slimple scatter point based on the slider (just a dummy for the purpose of this example)
data = @lift [Point2f($(slider1.value), $(slider2.value))]
scatter(figure[1, 1], data)

obs_func = on(slider1.value) do val # val is a scalar of type Float64
    # slider2.value[] of type: Observable{Any}
    # pair of scared brackets "[]" extract scalar value of >slider2.value<
    abs(val + slider2.value[])>0.01 && set_close_to!(slider2, -val)
end

obs_func2 = on(slider2.value) do val
    abs(slider1.value[]+val)>0.01 && set_close_to!(slider1, -val)
end

display(figure)

