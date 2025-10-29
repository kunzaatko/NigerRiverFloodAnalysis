using Makie, Dates, LaTeXStrings, StatsBase, DataFrames, Distributions

_, _, _, _, year_df = include("../data_preparation.jl")(; dir=".")

fig_qqplot = Figure()
ax_max_boxplot = Axis(fig_qqplot[1, 1], xgridvisible=false, ygridvisible=false)

qqplot!(ax_max_boxplot, Normal, year_df[!, :R_max_day], qqline=:identity)
