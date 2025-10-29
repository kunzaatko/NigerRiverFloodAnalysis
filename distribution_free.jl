using DataFrames, LaTeXStrings, StatsBase

_, _, _, _, year_df = include("./data_preparation.jl")(; dir=".")

data = year_df[!, :R_max_day]

include("./LaTeX_table.jl")

include("./objective_values.jl")

markov_upper(thresh; data=data) = mean(data) / thresh
chebyšev_upper(thresh; data=data) = begin
    eps = thresh - mean(data)
    var(data) / (var(data) + eps^2)
end
paley_lower(thresh, p; data=data) = begin
    θ = thresh / mean(data)
    @assert 1 >= θ >= 0
    ((1 - θ)^(p / (p - 1)) * mean(data)^(p / (p - 1))) / (mean(data .^ p)^(1 / (p - 1)))
end


C_bounds_table = DataFrame("Threshold" => L"C", L"MUB" => markov_upper(C), L"CCUB" => chebyšev_upper(C))

F_bounds_table = DataFrame("Threshold" => L"F", L"MUB" => markov_upper(F), L"CCUB" => chebyšev_upper(F))

D_bounds_table = DataFrame("Threshold" => L"D", L"MUB" => markov_upper(D), L"CCUB" => chebyšev_upper(D))

open("./report/src/tables/distfree_estimates.tex"; truncate=true) do table
    format = Dict{Any,Any}(
        Float64 => x -> string(round(x; sigdigits=3)))
    write(table, latex_table(vcat(C_bounds_table, D_bounds_table, F_bounds_table); format))
end

E_estim = (1 - maximum(paley_lower(E, p) for p in 2:0.1:100))
print("upper bound to III is $(E_estim)")



distribution_free_df = DataFrame(
    "Objective" => [raw"\ref{obj:I}", raw"\ref{obj:II}", raw"\ref{obj:V}", raw"\ref{obj:III}"],
    "Estimate" => [
        latexstring(raw"P[R_{\max} > C] \le ", round(chebyšev_upper(C), sigdigits=2)),
        latexstring(raw"P[R_{\max} > D] \le ", round(chebyšev_upper(D), sigdigits=2)),
        latexstring(raw"P[R_{\max} > F] \le ", round(chebyšev_upper(F), sigdigits=2)),
        latexstring(raw"P[R_{\max} \le E] \le ", round(E_estim, sigdigits=2))]
)

open("./report/src/tables/distfree_estimates_summary.tex", truncate=true) do table
    write(table, latex_table(distribution_free_df))
end

