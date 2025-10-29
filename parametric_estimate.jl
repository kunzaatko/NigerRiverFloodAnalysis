using KernelDensity, DataFrames, LaTeXStrings, Distributions, Roots, Optim, Distributed

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

gumbel_mix(P) = MixtureModel(
    Gumbel[
        Gumbel(P[1], P[2]),
        Gumbel(P[3], P[4]),
    ], [P[5], 1 - P[5]])

parametric_dist = gumbel_mix(Optim.minimizer(deserialize("./mle_opt_gumbel_mixture")))

A_df = DataFrame(
    "Objective" => [raw"\ref{obj:I}", raw"\ref{obj:II}", raw"\ref{obj:V}"],
    "Estimate" => [
        latexstring(raw"\hat{P}[R_{\max} > C] = ", round(ccdf(parametric_dist, C), sigdigits=2)),
        latexstring(raw"\hat{P}[R_{\max} > D] = ", round(ccdf(parametric_dist, D), sigdigits=2)),
        latexstring(raw"\hat{P}[R_{\max} > F] = ", round(ccdf(parametric_dist, F), sigdigits=2)),
    ]
)

open("./report/src/tables/parametric_estimates_A.tex", truncate=true) do table
    write(table, latex_table(A_df))
end

# Objective [III]
B_df = DataFrame(
    "Objective" => [raw"\ref{obj:III}", raw"\ref{obj:VI}"],
    "Estimate" => [
        latexstring(raw"\hat{P}[R_{\max} < E] = ", round(cdf(parametric_dist, E), sigdigits=2)),
        latexstring(raw"\hat{P}[R_{\max} \ge Z + C \mid R_{\max} \ge C] = ", round(ccdf(parametric_dist, Z + C) / ccdf(parametric_dist, C), sigdigits=2))
    ]
)

open("./report/src/tables/parametric_estimates_B.tex", truncate=true) do table
    write(table, latex_table(B_df))
end


probs = [0.1, 0.04, 0.02, 0.01, 0.004]

C_df = DataFrame(
    raw"\(p\)" => map(string, probs),
    "Name" => map(probs) do p
        string(Integer(1 / p)) * "-year water"
    end,
    "Estimate" =>
        @showprogress pmap(probs) do p

            latexstring(raw"\hat{h}_{" * string(p) * raw"} = " * raw"\qty{" * string(round(quantile(parametric_dist, 1 - p), digits=1)) * raw"}{\metre\cubed\per\second}")
        end
)

open("./report/src/tables/parametric_estimates_C.tex", truncate=true) do table
    write(table, latex_table(C_df))
end
