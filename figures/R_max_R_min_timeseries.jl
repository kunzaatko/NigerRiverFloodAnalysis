using Makie, Dates, LaTeXStrings, StatsBase, DataFrames

_, _, _, _, year_df = include("../data_preparation.jl")(; dir=".")

fig_R_max_R_min = Figure()
ax_R_max_R_min = Axis(fig_R_max_R_min[1, 1], xgridvisible=false, ygridvisible=false, ylabel=L"Q\,[m^3/s]")

barplot!(ax_R_max_R_min, year_df[!, :year], year_df[!, :R_max_day], label=L"R_{\max}")
barplot!(ax_R_max_R_min, year_df[!, :year], year_df[!, :R_max], label=L"\tilde{R}_{\max}")
barplot!(ax_R_max_R_min, year_df[!, :year], year_df[!, :R_min], label=L"\tilde{R}_{\min}")
barplot!(ax_R_max_R_min, year_df[!, :year], year_df[!, :R_min_day], label=L"R_{\min}")

Legend(fig_R_max_R_min[1, 2], ax_R_max_R_min)
ax_R_max_R_min.xticks = (year_df[1:5:end, :year], string.(year_df[1:5:end, :year]))
ax_R_max_R_min.xticklabelrotation = π / 3
xlims!(ax_R_max_R_min, extrema(year_df[!, :year]) .+ (-1, +1))
ylims!(ax_R_max_R_min, (1, maximum(year_df[!, :R_max_day]) * 1.02))

include("../save_fig.jl")(fig_R_max_R_min, "R_max_R_min_timeseries", ".")
