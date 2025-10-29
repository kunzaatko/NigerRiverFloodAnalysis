using Makie, StatsBase, LaTeXStrings, LinearAlgebra, ProgressMeter

include("../kde_estimates.jl")

silvermans_choice = KernelDensity.default_bandwidth(T.(data))

considered_bdw = range((silvermans_choice .* (0.5, 1.5))..., length=500)
data_range = range((extrema(data) .* (0.7, 1.3))...; length=5000)

kde_choice_data = zeros(length(data_range), length(considered_bdw))

T_data = T.(data)

progress = Progress(length(considered_bdw))
Threads.@threads for i in 1:length(considered_bdw)
    bdw = considered_bdw[i]
    kde_slice = view(kde_choice_data, :, i)
    kde_epanechnikov_bdw = kde(T_data; kernel=Epanechnikov, bandwidth=bdw)
    pdf_kde_bandwidth = x -> pdf(kde_epanechnikov_bdw, T(x)) * 2 / (pi * (x^2 + 1))
    kde_slice[:] .= pdf_kde_bandwidth.(data_range)
    next!(progress)
end
finish!(progress)

lines_kdes = kde_choice_data[:, begin:100:end]
lines_bdws = considered_bdw[begin:100:end]
lines_fig = Figure()
lines_ax = Axis(lines_fig[1, 1]; yticklabelsvisible=false)
Colorbar(lines_fig[1, 2]; colormap=(:reds, 0.8), limits=extrema(lines_bdws), label=L"\sigma", labelrotation=0, ticklabelrotation=pi / 4)

for (bw, bw_data) in zip(lines_bdws, eachslice(lines_kdes, dims=2))
    lines!(lines_ax, data_range, bw_data; colormap=(:reds, 0.8), color=bw, colorrange=extrema(lines_bdws))
end
stephist!(lines_ax, data, normalization=:pdf, bins=11, color=(:blue, 0.8))


include("../save_fig.jl")(lines_fig, "KDE_comparison_lines", ".")

surface_fig = Figure()
surface_ax = Axis3(surface_fig[1, 1])
# surface_ax.yticklabelsvisible = false
surface_ax.zticklabelsvisible = false
surface_ax.zlabelvisible = false
surface_ax.ylabelvisible = false
surface_ax.xlabelvisible = false

# Colorbar(surface_fig[1, 2]; colormap=(:reds, 0.8), limits=extrema(lines_bdws), labelrotation=0)

# histogram surface overlay
hist_edges = Makie.pick_hist_edges(data, 11)
_, weights = Makie._hist_center_weights(Observable(data), hist_edges, :pdf, nothing, Makie.automatic)
hist_edges = collect(hist_edges)
pushfirst!(weights, 0)
push!(weights, 0)
pushfirst!(hist_edges, 0)
find_edge(x) = findlast(i -> x > hist_edges[i], axes(hist_edges, 1))

hist_surface = repeat(collect(map(collect(data_range)) do x
        return weights[find_edge(x)]
    end), 1, length(considered_bdw))

# slg = SliderGrid(surface_fig[2, :], (label=L"\sigma", range=axes(considered_bdw, 1), startvalue=303, format=i -> string(round(considered_bdw[i]; sigdigits=3))))
# selected_index = slg.sliders[1].value

selected_index = Observable(303)

selected_bdw = lift(i -> considered_bdw[i], selected_index)
selected_kde = lift(i -> dropdims(kde_choice_data[:, i, :], dims=2), selected_index)
bdw_rep = lift(selected_bdw) do bdw
    fill(bdw, length(data_range))
end

lines!(surface_ax, data_range, bdw_rep, selected_kde; color=:red)
lines!(surface_ax, data_range, bdw_rep, dropdims(hist_surface[:, 1, :]; dims=2); color=:blue)

surface!(surface_ax, data_range, considered_bdw, kde_choice_data; colormap=(:reds, 0.8), color=repeat(considered_bdw, 1, length(data_range))')
surface!(surface_ax, data_range, considered_bdw, hist_surface; colormap=(:blues, 0.3), color=ones(size(hist_surface)))

# plane_ax = Axis(surface_fig[2, :])
plane_fig, plane_ax, _ = lines(data_range, selected_kde; color=:red, label=L"\hat{p}^{\text{K}}_{n}")
plane_ax.yticklabelsvisible = false

lines!(plane_ax, data_range, dropdims(hist_surface[:, 1, :], dims=2); color=:blue, label=L"\hat{p}^{\text{H}}_{n}")

Legend(plane_fig[1, 2], plane_ax)

include("../save_fig.jl")(plane_fig, "KDE_final_plane", ".")

# include("../save_fig.jl")(surface_fig, "KDE_comparison_surface", "."; resolution=(1920, 1080) .* 2)
