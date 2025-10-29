using GLMakie, IterTools, Dates

data = include("../data_preparation.jl")()[1][!, "value"]

means = [mean(v) for v in partition(data, 365 * 2, 10)]

fig, _, _ = lines()
