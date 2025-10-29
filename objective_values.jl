using DataFrames, LaTeXStrings, StatsBase

_, _, _, _, year_df = include("./data_preparation.jl")(; dir=".")

data = year_df[!, :R_max_day]

include("./LaTeX_table.jl")

Q3 = quantile(data, 3 // 4)
R_n3d4p1 = first(sort(filter(x -> x > Q3, data)))

C = (Q3 + R_n3d4p1) / 2

F = last(sort(data))

D = F + 100

E = sum(sort(data)[[4, 5]]) / 2

Z = (last(sort(data)) - quantile(data, 3 // 4)) / 2

objective_values_df = DataFrame("Variable" => [L"C", L"D", L"E", L"F", L"Z"], "value" => [C, D, E, F, Z], "Formula" => [L"\frac{Q_3 +  (R_{\max})_{[3n/4] + 1}}{2}", L"(R_{\max})_n + \qty{100}{\metre\cubed\per\second}", L"\frac{(R_{\max})_{4} +  (R_{\max})_{5}}{2}", L"(R_{\max})_n", L"\frac{(R_{\max})_n - Q_3}{2}"])

open("./report/src/tables/objective_values.tex"; truncate=true) do table
    format = Dict{Any,Any}(
        Float64 => x -> latexstring(raw"\qty{", round(x; sigdigits=7
            ), raw"}{\metre\cubed\per\second}"))
    write(table, latex_table(objective_values_df; format))
end
