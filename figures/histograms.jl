using Makie, StatsBase, LaTeXStrings, LinearAlgebra

include("../histogram_estimate.jl")

data = year_df[!, :R_max_day]

ns = [8, 9, 11]
hist_figs = []
for n in ns
    local fig = Figure()
    axis = Axis(fig[1, 1], title=latexstring("k = ", string(n)))
    hist!(axis, data, normalization=:probability, bins=n, bar_labels=:values,
        label_formatter=x -> round(x, sigdigits=2), label_size=12,
        strokewidth=0.5, strokecolor=(:black, 0.5), color=:values, colormap=:blues
    )
    push!(hist_figs, fig)
end

for (fig, n) in zip(hist_figs, ns)
    include("../save_fig.jl")(fig, "histogram_with_" * string(n) * "_bins", ".")
end
