using Makie, Dates, LaTeXStrings, StatsBase, DataFrames

day_df, _, _, _, _ = include("../data_preparation.jl")(; dir=".")

fig_boxplot = Figure()
ax_boxplot = Axis(fig_boxplot[1, 1], xgridvisible=false, ygridvisible=false, ylabel=L"Q\,[m^3/s]")

months = day_df[ismissing.(day_df[!, :Q]).==false, :imonth]
Qs = day_df[ismissing.(day_df[!, :Q]).==false, :Q]

boxplot!(ax_boxplot, months, Qs; marker=:x, markersize=5, outliercolor=(:red, 0.5))

month_names = [MONTH_NAMES[i] for i in 1:12]
ax_boxplot.xticks[] = (1:12, month_names)
ax_boxplot.xticklabelrotation = π / 3

include("../save_fig.jl")(fig_boxplot, "month_boxplot", ".")
