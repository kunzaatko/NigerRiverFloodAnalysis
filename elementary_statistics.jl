using StatsBase, DataFrames, LaTeXStrings

day_df, _, month_df, _, year_df = include("./data_preparation.jl")(; dir=".")

include("./LaTeX_table.jl")

struct Std <: Real
    value::Float64
end

nomiss(x) = x |> skipmissing |> collect
stats = (L"\bar{X}_n" => x -> mean(nomiss(x)),
    L"\std" => x -> Std(std(nomiss(x))),
    L"\min" => x -> minimum(nomiss(x)),
    L"Q_1" => x -> quantile(nomiss(x), 0.25),
    L"Q_2" => x -> quantile(nomiss(x), 0.5),
    L"Q_3" => x -> quantile(nomiss(x), 0.75),
    L"\max" => x -> maximum(nomiss(x)))

month_groups = groupby(day_df, :month)
month_stats = DataFrame()
month_stats[!, "Month"] = [g[1, :month] for g in month_groups]
for (k, v) in stats
    month_stats[!, k] = [v(g[!, :Q]) for g in month_groups]
end

month_stats = month_stats[!, ["Month", L"\bar{X}_n", L"\std", L"\min", L"Q_1", L"Q_2", L"Q_3", L"\max"]]

open("./report/src/tables/month_stats.tex"; truncate=true) do table
    format = Dict{Any,Any}(
        Float64 => x -> raw"\qty{" * string(round(x; digits=1)) * raw"}{\metre\cubed\per\second}",
        Std => x -> raw"\qty{" * string(round(x.value; digits=1)) * raw"}{\metre^6\per\second\squared}",
    )
    write(table, latex_table(month_stats; format))
end

max_stats = DataFrame()
variable_names = (:R_max => L"\tilde{R}_{\max}", :R_max_day => L"R_{\max}", :R_min_day => L"R_{\min}", :R_min => L"\tilde{R}_{\min}")
max_stats[!, "Variable"] = collect(v for (_, v) in variable_names)
for (k, stat) in stats
    max_stats[!, k] = [stat(year_df[!, s]) for (s, _) in variable_names]
end

max_stats = max_stats[!, ["Variable", L"\bar{X}_n", L"\std", L"\min", L"Q_1", L"Q_2", L"Q_3", L"\max"]]

open("./report/src/tables/max_stats.tex"; truncate=true) do table
    format = Dict{Any,Any}(
        Float64 => x -> raw"\qty{" * string(round(x; digits=1)) * raw"}{\metre\cubed\per\second}",
        Std => x -> raw"\qty{" * string(round(x.value; digits=1)) * raw"}{\metre^6\per\second\squared}",
    )
    write(table, latex_table(max_stats; format))
end
