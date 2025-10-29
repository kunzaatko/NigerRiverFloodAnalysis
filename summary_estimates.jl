using DataFrames, LaTeXStrings, Distributions, Roots, Optim, Distributed, Serialization

_, _, _, _, year_df = include("./data_preparation.jl")(; dir=".")

data = year_df[!, :R_max_day]

include("./LaTeX_table.jl")
include("./objective_values.jl")

gumbel_mix(P) = MixtureModel(
    Gumbel[
        Gumbel(P[1], P[2]),
        Gumbel(P[3], P[4]),
    ], [P[5], 1 - P[5]])

parametric_dist = gumbel_mix(Optim.minimizer(deserialize("./mle_opt_gumbel_mixture")))

probs = [0.1, 0.04, 0.02, 0.01, 0.004]

df = DataFrame(
    "Objective" => cat([raw"\ref{obj:I}", raw"\ref{obj:II}", raw"\ref{obj:III}"],
        map(probs) do p
            raw"\ref{obj:IV} - " * string(Integer(1 / p)) * "-year" #= * raw" \\ water \end{tabular}" =#
        end,
        [raw"\ref{obj:V}", raw"\ref{obj:VI}"], dims=1),
    # "Name" => cat(["", "", ""],
    #     map(probs) do p
    #         raw"\begin{tabular}{c}" * string(Integer(1 / p)) * raw"-year \\ water \end{tabular}"
    #     end,
    #     ["", ""]; dims=1),
    "Estimate" => cat([
            latexstring(raw"\hat{P}[R_{\max} > C] = ", round(ccdf(parametric_dist, C), sigdigits=2)),
            latexstring(raw"\hat{P}[R_{\max} > D] = ", round(ccdf(parametric_dist, D), sigdigits=2)),
            latexstring(raw"\hat{P}[R_{\max} < E] = ", round(cdf(parametric_dist, E), sigdigits=2)),],
        map(probs) do p

            latexstring(raw"\hat{h}_{" * string(p) * raw"} = " * raw"\qty{" * string(round(quantile(parametric_dist, 1 - p), digits=1)) * raw"}{\metre\cubed\per\second}")
        end,
        [
            latexstring(raw"\hat{P}[R_{\max} > F] = ", round(ccdf(parametric_dist, F), sigdigits=2)),
            latexstring(raw"\hat{P}[R_{\max} \ge Z + C \mid R_{\max} \ge C] = ",
                round(ccdf(parametric_dist, Z + C) / ccdf(parametric_dist, C), sigdigits=2))
        ]; dims=1)
)

open("./report/src/tables/summary_estimates.tex", truncate=true) do table
    write(table, latex_table(df; headcentering="l"))
end
