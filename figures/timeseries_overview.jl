using Makie, Dates, LaTeXStrings, ColorSchemes, ColorTypes, StatsBase, ImageFiltering, DataFrames

day_df, _, month_df, _, _ = include("../data_preparation.jl")(; dir=".")

fig_month = Figure()
ax_month = Axis(fig_month[1, 1], xgridvisible=false, ygridvisible=false, ylabel=L"Q\,[m^3/s]", xlabel="year")

lines!(ax_month, 1:nrow(month_df), month_df[!, :Q], color=month_df[!, :value], label=L"Monthly Means of $Q$")

axislegend(ax_month)
ax_month.xticklabelrotation = π / 3
ax_month.xticks = (1:(5*12):nrow(month_df), string.(year.(month_df[!, :date]))[1:(5*12):end])
ax_month.xminorticks = 1:12:nrow(month_df)
ax_month.xminorticksvisible = true
limits!(ax_month, (1, nrow(month_df)), (0, maximum(month_df[!, :value]) * 1.1))

include("../save_fig.jl")(fig_month, "timeseries_full_overview", ".")

# TODO: Add colorbar for the years <10-05-23> 
fig_day = Figure()
ax_day = Axis(fig_day[1, 1], xgridvisible=false, ygridvisible=false, yscale=log10, ylabel=L"Q\,[m^3/s]", xlabel="week")


# TODO: Use series plots instead of lines <11-05-23> 
for g in DataFrames.groupby(day_df, :year)
    year = g[1, :year]
    lines!(ax_day, g[!, :year_ind], g[!, :Q], label=string(year),
        color=RGBA(get(ColorSchemes.colorschemes[:viridis], year, extrema(day_df[!, :year])), 0.2), linewidth=1)
end
ax_day.xticks = (range(extrema(day_df[!, :year_ind])..., step=7 / 365)[1:5:end], string.(0:5:52))


means = [i(g) for g in DataFrames.groupby(day_df, :year_ind), i in (x -> x[1, :year_ind], x -> mean(skipmissing(x[!, :Q])))]
means = sortslices(means, dims=1, by=x -> x[1])
means_smooth(l) = imfilter(means[:, 2], centered(ones(2l + 1) ./ (2l + 1)), "replicate")
smooth_mean_len = 30
lines!(ax_day, means[:, 1], means_smooth(smooth_mean_len); color=Makie.wong_colors()[1], linewidth=3)

xlims!(extrema(day_df[!, :year_ind])...)
ylims!(1, maximum(day_df[!, :value]))
Legend(fig_day[1, 1], [LineElement(color=(:black, 0.2), linewidth=1),
        LineElement(color=Makie.wong_colors()[1], linewidth=3)], ["Seasonal discharges (1944-2022)", "Mean"],
    tellwidth=false,
    valign=:bottom,
    margin=(10, 10, 10, 10),
    halign=:right
)

include("../save_fig.jl")(fig_day, "timeseries_groups_by_year", ".")
