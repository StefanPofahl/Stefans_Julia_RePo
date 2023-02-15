# --- ------------------------------------------------------------------------------------------------------------------------- #
# --- changing attributes in existing screen objects:                                                                           #
# --- ------------------------------------------------------------------------------------------------------------------------- #
# --- it might be that not all changes of attributes take effect, e.g. in GLMakie version v0.8.2 changing the color of a line   #
# --- might fail. If such a thing occurs it might help to switch visibility "on" and "off".                                     #
# --- https://discourse.julialang.org/t/glmakie-change-attributes-in-existing-screen-objects/94636/3                            # 
# ... ......................................................................................................................... #
# --- change color inside text: rich():                                                                                         #
# --- https://docs.makie.org/stable/examples/plotting_functions/text/index.html#rich_text                                       #
# --- second y-axis / twin axis: ---------------------------------------------------------------------------------------------- #
# --- https://docs.makie.org/stable/examples/blocks/axis/index.html#creating_a_twin_axis                                        #
# --- control axis size, see info at the bottom of: --------------------------------------------------------------------------- #
# --- https://docs.makie.org/stable/tutorials/aspect-tutorial/index.html                                                        #
# ... ......................................................................................................................... #
using GLMakie
# fig = Figure(resolution = (400, 600))
fig = Figure()

bt = Button(fig[1, 1]; label = rich(rich("on", color = :red), "/", rich("off", color = :black)), 
        strokewidth = 4, strokecolor = (:green), tellheight = true, )    
ax1 = Axis(fig[2, 1]; title = "test", titlegap = 30.0, aspect = DataAspect(), width = 150, height = 150, 
        yticklabelcolor = :blue, tellheight = true, tellwidth = true)
# --- 2nd y-axis / twin axis:        
ax2 = Axis(fig[2, 1]; yticklabelcolor = :green, xaxisposition = :top, yaxisposition = :right)
# ---
l1 = lines!(ax1, [1,2,3])
l1_clr = l1.color
l2 = lines!(ax2, [6,4,2])
# ---
on(bt.clicks) do nclicks 
    l2.visible = false # trick if change of object attribute does not change, switch on/off visibility might help
    if iseven(nclicks)
        l1.visible = true
        ax.title = rich("l1: on, ", rich("l2: blue", color = :blue))
        bt.label = rich("switch: ", rich("off", color = :blue))
        l2.color = :blue
    else
        l1.visible = false
        ax.title = rich("l1: off, ", rich("l2: blue", color = :red))
        bt.label = rich("switch: ", rich("on", color = :red))
        l2.color = :red
    end
    l2.visible = true
end
# ---
resize_to_layout!(fig)
scene_obj = display(fig)
# wait(scene_obj)