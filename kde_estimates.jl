using KernelDensity, DataFrames, LaTeXStrings, QuadGK, Distributions, Roots, Distributed

_, _, _, _, year_df = include("./data_preparation.jl")(; dir=".")

data = year_df[!, :R_max_day]

include("./LaTeX_table.jl")
include("./objective_values.jl")

T(x) = 2 / pi * atan(x)
T_inv(y) = tan(y * pi / 2)


# Estimates

SELECTED_σ = 1.7 * 10^(-5)
kde_transformed = kde(T.(data); kernel=Epanechnikov, bandwidth=SELECTED_σ)
pdf_kde(x) = pdf(kde_transformed, T(x)) * 2 / (pi * (x^2 + 1))

# Objectives [I], [II] and [V] 
P_over(A) = quadgk(pdf_kde, A, Inf)[1]

A_df = DataFrame(
    "Objective" => [raw"\ref{obj:I}", raw"\ref{obj:II}", raw"\ref{obj:V}"],
    "Estimate" => [
        latexstring(raw"\hat{P}[R_{\max} > C] = ", round(P_over(C), sigdigits=2)),
        latexstring(raw"\hat{P}[R_{\max} > D] = ", round(P_over(D), sigdigits=2)),
        latexstring(raw"\hat{P}[R_{\max} > F] = ", round(P_over(F), sigdigits=2)),
    ]
)

open("./report/src/tables/kde_estimates_A.tex", truncate=true) do table
    write(table, latex_table(A_df))
end

# Objective [III]
P_under(A) = quadgk(pdf_kde, 0, A)[1]

B_df = DataFrame(
    "Objective" => [raw"\ref{obj:III}", raw"\ref{obj:VI}"],
    "Estimate" => [
        latexstring(raw"\hat{P}[R_{\max} < E] = ", round(P_under(E), sigdigits=2)),
        latexstring(raw"\hat{P}[R_{\max} \ge Z + C \mid R_{\max} \ge C] = ", round(P_over(Z + C) / P_over(C), sigdigits=2))
    ]
)

open("./report/src/tables/kde_estimates_B.tex", truncate=true) do table
    write(table, latex_table(B_df))
end

# Objective [IV]
T_p(p) = find_zero(x -> P_over(x) - p, (2200.0, 3000.0), Roots.A42())

probs = [0.1, 0.04, 0.02, 0.01, 0.004]
#
C_df = DataFrame(
    raw"\(p\)" => map(string, probs),
    "Name" => map(probs) do p
        string(Integer(1 / p)) * "-year water"
    end,
    "Estimate" =>
        @showprogress pmap(probs) do p

            latexstring(raw"\hat{h}_{" * string(p) * raw"} = " * raw"\qty{" * string(round(T_p(p), digits=1)) * raw"}{\metre\cubed\per\second}")
        end
)

open("./report/src/tables/kde_estimates_C.tex", truncate=true) do table
    write(table, latex_table(C_df))
end
