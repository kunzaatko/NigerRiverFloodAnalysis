using Makie, StatsBase, LaTeXStrings, ProgressMeter, QuadGK, Optim, Serialization, Combinatorics, Match

include("../parametric_estimate.jl")

markersize = 8
data = year_df[!, :R_max_day]

## MLE fits of distributions

# fig_mle_preliminary = Figure()
# ax_mle_preliminary = Axis(fig_mle_preliminary[2, 1]; xticklabelsvisible=false, yticklabelsvisible=false)
# ax_mle_qqplots = Axis(fig_mle_preliminary[2, 2]; xticklabelsvisible=false, yticklabelsvisible=false)
#
# data_filtered = filter(x -> x > 1500, data)
# data_range = range((extrema(data_filtered) .+ [-200, 200])..., length=1000)
#
# lines!(ax_mle_qqplots, data_range, identity; color=:black, label="Q-Q line")
# for (dist, name) in [(Normal, ""), (LogNormal, "Log-Normal"), (Gamma, ""), (Weibull, "Weibull")] #=(InverseGaussian, "Inverse-Gaussian"),=#
#     mle_fit = fit(dist, data_filtered)
#     lines!(ax_mle_preliminary, data_range, x -> pdf(mle_fit, x); label=length(name) != 0 ? name : string(dist))
#     qqplot!(ax_mle_qqplots, dist, data_filtered; markersize)
# end
# lines!(ax_mle_preliminary, data_range, pdf_kde, label=L"\hat{p}_{n}^{\text{K}}")
# scatter!(ax_mle_preliminary, data_filtered, zeros(length(data_filtered)); markersize, color=:green) #; color=year_df[!, :year], colormap=:greens)
#
# fig_mle_preliminary[1, :] = Legend(fig_mle_preliminary, ax_mle_preliminary; orientation=:horizontal)
#
# include("../save_fig.jl")(fig_mle_preliminary, "parametric_mle_preliminary", ".")

## p_0 selection

function select_p0(dist, part)
    fig = Figure()
    ax = Axis(fig[1, 1])
    data_filt = part == 1 ? filter(x -> x <= 1500, data) : filter(x -> x > 1500, data)
    coef = part == 1 ? 0.2 : 0.8
    data_range = range((extrema(data_filt) .+ [-200, 200])..., length=1000)
    lines!(ax, data_range, pdf_kde)

    slg = SliderGrid(fig[2, 1], (label=L"p_1", range=0.001:0.001:40.0), (label=L"p_2", range=0.01:0.01:2000.0))

    dist_obs = @lift(dist($(slg.sliders[1].value), $(slg.sliders[2].value)))
    hyp = lift(d -> coef * pdf.(d, range(0, maximum(data_range); length=1000)), dist_obs)

    lines!(ax, data_range, hyp)

    # log_likelihood(P) = prod(map(d -> logpdf(dist(P...), d), data_filt))   
    # return optimize(P -> -log_likelihood(P), [1000., 30.])
    return fig
end

## Q-Q plots of fitted mixtures

fig_QQ_selection = Figure()
fig_PD_selection = Figure()
ax_QQ_selection = Axis(fig_QQ_selection[1, 1]; xticklabelsvisible=false, yticklabelsvisible=false)
ax_PD_selection = Axis(fig_PD_selection[1, 1]; yticklabelsvisible=false)

# TODO: QQ-plots <01-09-23> 

lines!(ax_PD_selection, 1000 .. 3300, pdf_kde; label=L"\hat{p}_{n}^{\text{K}}")
stephist!(ax_PD_selection, data, normalization=:pdf, bins=11, color=(:blue, 0.8), label=L"\hat{p}_{n}^{\text{H}}")

lines!(ax_QQ_selection, data, identity; color=:black, label="Q-Q line")

_ind = 0
for mix in multiset_permutations([Gumbel, Gamma, Gumbel, Gamma], 2)
    # for mix in multiset_permutations([Gumbel, Gamma, Weibull, Gumbel, Gamma, Weibull], 2)

    if mix in [[Weibull, Gamma], [Weibull, Weibull], [Gamma, Weibull], [Gumbel, Weibull], [Gumbel, Gamma], [Gamma, Gamma]]
        continue
    end
    global _ind += 1

    D1, D2 = mix
    p_0_1 = if D1 == Gumbel
        [1270.0, 131.0]
    elseif D1 == Gamma
        [23.8, 31.9]
    elseif D1 == Weibull
        [5.25, 781.0]
    end

    p_0_2 = if D2 == Gumbel
        [1870.0, 176.0]
    elseif D2 == Gamma
        [15.0, 68.4]
    elseif D2 == Weibull
        [5.5, 1040.0]
    end

    p_0 = [p_0_1..., p_0_2..., 0.2]

    mixture_dist(P) = MixtureModel(
        [
            first(mix)(P[1], P[2]),
            last(mix)(P[3], P[4]),
        ], [P[5], 1 - P[5]])

    log_likelihood(P) = prod(map(d -> logpdf(mixture_dist(P), d), data))
    mle_fit = optimize(P -> -log_likelihood(P), [0.0, 0.0, 0.0, 0.0, 0.1], [Inf, Inf, Inf, Inf, 0.4], p_0)
    @show D1, D2
    @show minimizer = Optim.minimizer(mle_fit)

    label = string(D1) * " and " * string(D2)
    lines!(ax_PD_selection, 1000 .. 3300, x -> pdf(mixture_dist(minimizer), x); label)
    qqplot!(ax_QQ_selection, mixture_dist(minimizer), data; markersize, label, color=(Makie.wong_colors()[_ind], 0.5))
end
axislegend(ax_QQ_selection; position=:lt)
axislegend(ax_PD_selection)

include("../save_fig.jl")(fig_QQ_selection, "parametric_QQ_selection", ".")
include("../save_fig.jl")(fig_PD_selection, "parametric_PD_selection", ".")

## Gumbel mixture

fig_Gumbel = Figure()
ax_Gumbel = Axis(fig_Gumbel[2, 1]; yticklabelsvisible=false)
ax_Gumbel_qq = Axis(fig_Gumbel[2, 2]; yticklabelsvisible=false)

fig_Gumbel_vert = Figure()
ax_Gumbel_vert = Axis(fig_Gumbel_vert[1, 1]; yticklabelsvisible=false)
ax_Gumbel_qq_vert = Axis(fig_Gumbel_vert[3, 1]; yticklabelsvisible=false)

p_0 = [1320.0, 144.0, 1860.0, 163.0, 0.23]
# slg = SliderGrid(
#     fig_Gumbel[2, 1],
#     (label=L"\mu_1", range=1250:0.1:1400, startvalue=p_0[1]),
#     (label=L"\theta_1", range=50:0.1:300, startvalue=p_0[2]),
#     (label=L"\mu_2", range=1650:0.1:2200, startvalue=p_0[3]),
#     (label=L"\theta_2", range=100:0.1:350, startvalue=p_0[4]),
#     (label=L"\pi_1", range=0:0.01:1, startvalue=p_0[5]),
# )
#
# p_sls = slg.sliders
#
# Gumbel_mix = @lift(MixtureModel(
#     Gumbel[
#         Gumbel($(p_sls[1].value), $(p_sls[2].value)),
#         Gumbel($(p_sls[3].value), $(p_sls[4].value)),
#     ], [$(p_sls[end].value), 1 - $(p_sls[end].value)]))
#
# lines!(ax_Gumbel, 1000 .. 3300, lift(m -> (x -> pdf(m, x)), Gumbel_mix); label=L"p_{\text{mix}}")

gumbel_mix(P) = MixtureModel(
    Gumbel[
        Gumbel(P[1], P[2]),
        Gumbel(P[3], P[4]),
    ], [P[5], 1 - P[5]])

loss_l2(P) = quadgk(x -> (pdf_kde(x) - pdf(gumbel_mix(P), x))^2, 1000, 3300)[1]

l2_opt = deserialize("./l2_opt_gumbel_mixture") # optimize(loss_l2, p_0, LBFGS(), Optim.Options(show_trace=true))
lines!(ax_Gumbel, 1000 .. 3300, x -> pdf(gumbel_mix(Optim.minimizer(l2_opt)), x); label=L"\hat{p}_{\ell_2}")
lines!(ax_Gumbel_vert, 1000 .. 3300, x -> pdf(gumbel_mix(Optim.minimizer(l2_opt)), x); label=L"\hat{p}_{\ell_2}")

# MLE fits

log_likelihood(P) = prod(map(d -> logpdf(gumbel_mix(P), d), data))
box_lower = [1000, 1, 1500, 1, 0.05]
box_upper = [2000, 1000, 2500, 1000, 0.95]

ranges = map(x -> range(x[1], x[2], length=200)[begin+1:end-1], zip(box_lower, box_upper))

mle_opt = deserialize("./mle_opt_gumbel_mixture") # optimize(P -> -log_likelihood(P), box_lower, box_upper, p_0)

lines!(ax_Gumbel, 1000 .. 3300, x -> pdf(gumbel_mix(Optim.minimizer(mle_opt)), x); label=L"\hat{p}_{\text{MLE}}")
lines!(ax_Gumbel_vert, 1000 .. 3300, x -> pdf(gumbel_mix(Optim.minimizer(mle_opt)), x); label=L"\hat{p}_{\text{MLE}}")

lines!(ax_Gumbel, 1000 .. 3300, pdf_kde; label=L"\hat{p}_{n}^{\text{K}}")
lines!(ax_Gumbel_vert, 1000 .. 3300, pdf_kde; label=L"\hat{p}_{n}^{\text{K}}")

scatter!(ax_Gumbel, data, zeros(length(data)); color=year_df[!, :year], colormap=:greens, markersize)
scatter!(ax_Gumbel_vert, data, zeros(length(data)); color=year_df[!, :year], colormap=:greens, markersize)

lines!(ax_Gumbel_qq, data, identity; color=:black, label="Q-Q line")
lines!(ax_Gumbel_qq_vert, data, identity; color=:black, label="Q-Q line")

qqplot!(ax_Gumbel_qq, gumbel_mix(Optim.minimizer(l2_opt)), data; markersize, color=(Makie.wong_colors()[1], 0.5))
qqplot!(ax_Gumbel_qq_vert, gumbel_mix(Optim.minimizer(l2_opt)), data; markersize, color=(Makie.wong_colors()[1], 0.5))
qqplot!(ax_Gumbel_qq, gumbel_mix(Optim.minimizer(mle_opt)), data; markersize, color=(Makie.wong_colors()[2], 0.5))
qqplot!(ax_Gumbel_qq_vert, gumbel_mix(Optim.minimizer(mle_opt)), data; markersize, color=(Makie.wong_colors()[2], 0.5))

stephist!(ax_Gumbel, data, normalization=:pdf, bins=11, color=(:blue, 0.8), label=L"\hat{p}_{n}^{\text{H}}")
stephist!(ax_Gumbel_vert, data, normalization=:pdf, bins=11, color=(:blue, 0.8), label=L"\hat{p}_{n}^{\text{H}}")

fig_Gumbel[1, :] = Legend(fig_Gumbel, ax_Gumbel; orientation=:horizontal)
fig_Gumbel_vert[2, 1] = Legend(fig_Gumbel_vert, ax_Gumbel_vert; orientation=:horizontal)

include("../save_fig.jl")(fig_Gumbel, "parametric_gumbel_mixture", "."; resolution=(1920, 1080) ./ 2)
include("../save_fig.jl")(fig_Gumbel_vert, "parametric_gumbel_mixture_vert", "."; resolution=(1080, 1920) ./ 2)
