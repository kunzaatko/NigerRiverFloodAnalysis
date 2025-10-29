using Makie, StatsBase, LaTeXStrings, LinearAlgebra, Distributions, DataFrames

_, _, _, _, year_df = include("./data_preparation.jl")(; dir=".")

include("./LaTeX_table.jl")

data = year_df[!, :R_max_day]

abstract type HistogramChoice end
k(hc::HistogramChoice) = ceil(Int64, (maximum(hc.data) - minimum(hc.data)) / h(hc))
h(k, data) = (maximum(data) - minimum(data)) / k
h(hc::HistogramChoice) = h(k(hc), hc.data)
name(::HistogramChoice) = error("Must Implement!")
formula(::HistogramChoice) = error("Must Implement!")

struct SquareRoot <: HistogramChoice
    data
end
k(hc::SquareRoot) = ceil(Int64, sqrt(length(hc.data)))
name(hc::SquareRoot) = "Square-root"
formula(::SquareRoot) = L"k = \left\lceil \sqrt{n} \right\rceil"

struct Sturge <: HistogramChoice
    data
end
k(hc::Sturge) = ceil(Int64, log(2, length(hc.data))) + 1
name(::Sturge) = "Sturge"
formula(::Sturge) = L"k = \left\lceil \log_2(n) \right\rceil + 1"

struct Rice <: HistogramChoice
    data
end
k(hc::Rice) = ceil(Int64, 2 * (length(hc.data)^(1 // 3)))
name(::Rice) = "Rice"
formula(::Rice) = L"k = \left\lceil 2 \sqrt[3]{n} \right\rceil"

struct Doan <: HistogramChoice
    data
end
g1(data) = (1 / length(data) * sum((data .- mean(data)) .^ 3)) / ((1 / length(data) * sum((data .- mean(data)) .^ 2))^(3 / 2))
sigma_g1(data) = sqrt(6 * (length(data) - 2) / ((length(data) + 1) * (length(data) + 3)))
k(gc::Doan) = 1 + ceil(Int64, log(2, length(gc.data)) + log(2, 1 + abs(g1(gc.data)) / sigma_g1(gc.data)))
name(::Doan) = "Doan"
formula(::Doan) = L"k = 1 + \left\lceil \log_2(n) + \log_2 \left( 1 + \frac{\left| g_1 \right|}{\sigma_{g_1}}\right) \right\rceil"

struct Freedman <: HistogramChoice
    data
end
h(hc::Freedman) = 2 * (quantile(hc.data, 3 // 4) - quantile(hc.data, 1 // 4)) / (length(hc.data)^(1 // 3))
name(::Freedman) = "Freedman-Diaconi"
formula(::Freedman) = L"h = 2 \frac{\mathop{IQR}(x)}{\sqrt[3]{n}}"

histogram_choices_table = vcat([DataFrame("Method" => name(hc), "Formula" => formula(hc), L"k" => k(hc), L"h" => h(hc)) for
                                hc in [Hc(data) for Hc in (SquareRoot, Sturge, Rice, Doan, Freedman)]]...)

open("./report/src/tables/histogram_choices.tex"; truncate=true) do table
    format = Dict{Any,Any}(
        Float64 => x -> raw"\qty{" * string(round(x; sigdigits=5)) * raw"}{\metre\cubed\per\second}")
    write(table, latex_table(histogram_choices_table; format, headcentering="l", nhead=2))
end

histogram = normalize(fit(Histogram, data, range((extrema(data) .+ (0, eps(Float32)))..., length=12)))

function Distributions.ccdf(hist::Histogram, thresh)
    @assert hist.isdensity

    accum_prob = 0
    local ind = 1
    while thresh < hist.edges[1][end-ind]
        accum_prob += (hist.edges[1][end-ind+1] - hist.edges[1][end-ind]) * hist.weights[end-ind+1]
        ind += 1
    end
    accum_prob += (hist.edges[1][end-ind+1] - thresh) * hist.weights[end-ind+1]
    return accum_prob
end

include("./objective_values.jl")

C_estim = ccdf(histogram, C) # estimate of P[R > C]

T_0_1_estim = first(sort([(x, ccdf(histogram, x)) for x in 2181:0.0001:2182]; by=x -> abs(x[2] - 0.1)))[1] # estimate of P[R > T] == 0.1

Zover_estim = ccdf(histogram, C + Z) / ccdf(histogram, C)

hist_estim_df = DataFrame(
    "Objective" => [raw"\ref{obj:I}", raw"\ref{obj:IV}", raw"\ref{obj:VI}"],
    "Estimate" => [
        latexstring(raw"\hat{P}[R_{\max} > C] = ", round(C_estim, sigdigits=3)),
        latexstring(raw"\hat{h}_{0.1} = \qty{", round(T_0_1_estim, sigdigits=6), raw"}{\metre\cubed\per\second}"), #  % (R_{\max})_{[0.1]}
        latexstring(raw"\hat{P}[R_{\max} \ge Z + C \mid R_{\max} \ge C] = ", round(Zover_estim, sigdigits=3))
    ]
)

open("./report/src/tables/histogram_estimates_summary.tex", truncate=true) do table
    write(table, latex_table(hist_estim_df))
end
