using PyPlot

x = collect(1:10)
y1 = 2 .* x
y2 = 10 .- 0.5 .* x

fig, ax1 = PyPlot.subplots()

ax2 = ax1.twinx()

ax1.plot(x, y1, "b-", label="y1")
ax1.set_ylabel("y1 (left)", color="b")
ax1.tick_params(axis="y", colors="b")

ax2.plot(x, y2, "r--", label="y2")
ax2.set_ylabel("y2 (right)", color="r")
ax2.tick_params(axis="y", colors="r")

ax1.set_xlabel("x")
ax1.set_title("Example with twinx()")
fig.tight_layout()
