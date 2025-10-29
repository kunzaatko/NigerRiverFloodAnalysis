using Makie, Dates, LaTeXStrings, StatsBase, DataFrames

_, _, _, _, year_df = include("../data_preparation.jl")(; dir=".")

fig_max_boxplot = Figure()
ax_max_boxplot = Axis(fig_max_boxplot[1, 1], xgridvisible=false, ygridvisible=false, ylabel=L"Q\,[m^3/s]")

# months = day_df[ismissing.(day_df[!, :Q]).==false, :imonth]
max_t_R, max_R, min_t_R, min_R = (year_df[ismissing.(year_df[!, sym]).==false, sym] for sym in (:R_max_day, :R_max, :R_min_day, :R_min))
categories_max = vcat((fill(i, length(s)) for (i, s) in enumerate((max_R, max_t_R)))...)

boxplot!(ax_max_boxplot, categories_max, vcat((max_R, max_t_R)...); marker=:x, outliercolor=:red)
ax_max_boxplot.xticks = (1:2, [L"\tilde{R}_{\max}", L"R_{\max}"])

include("../save_fig.jl")(fig_max_boxplot, "max_boxplot", ".")

fig_min_boxplot = Figure()
ax_min_boxplot = Axis(fig_min_boxplot[1, 1], xgridvisible=false, ygridvisible=false, ylabel=L"Q\,[m^3/s]")

categories_min = vcat((fill(i, length(s)) for (i, s) in enumerate((min_R, min_t_R)))...)
boxplot!(ax_min_boxplot, categories_min, vcat((min_R, min_t_R)...); marker=:x, outliercolor=:red)

ax_min_boxplot.xticks = (1:2, [L"\tilde{R}_{\min}", L"R_{\min}"])

include("../save_fig.jl")(fig_min_boxplot, "min_boxplot", ".")
