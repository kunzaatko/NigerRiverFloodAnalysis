using HypothesisTests, DataFrames, LaTeXStrings

_, _, _, _, year_df = include("./data_preparation.jl")(; dir=".")

include("./LaTeX_table.jl")

test_indep_ljung = HypothesisTests.LjungBoxTest(year_df[!, :R_max_day], 3)
test_indep_box = HypothesisTests.BoxPierceTest(year_df[!, :R_max_day], 3)

function test_frame(test_res; fields=Dict())::DataFrame
    testoutput = DataFrame("Test Name" => testname(test_res), raw"$p$-value" => round(pvalue(test_res), sigdigits=2))
    for (n, f) in fields
        testoutput[!, n] = [getfield(test_res, f)]
    end
    testoutput
end
indep_test_fields = Dict(L"Q" => :Q, L"h" => :lag)
test_indep_table = vcat(test_frame(test_indep_ljung; fields=indep_test_fields),
    test_frame(test_indep_box; fields=indep_test_fields))

open("./report/src/tables/test_indep.tex"; truncate=true) do table
    format = Dict{Any,Any}(
        Float64 => x -> string(round(x; sigdigits=3)))
    write(table, latex_table(test_indep_table; format, centering = "c"))
end

indep_test_fields_wide = Dict(L"Q" => :Q, L"h" => :lag, L"n" => :n)
test_indep_ljung_wide_2 = HypothesisTests.LjungBoxTest(year_df[1:2:end, :R_max_day], 3)
test_frame_ljung_wide_2 = test_frame(test_indep_ljung_wide_2; fields=indep_test_fields_wide)
test_frame_ljung_wide_2[!, L"\Delta t"] .= "2 years"
test_indep_ljung_wide_3 = HypothesisTests.LjungBoxTest(year_df[1:3:end, :R_max_day], 3)
test_frame_ljung_wide_3 = test_frame(test_indep_ljung_wide_3; fields=indep_test_fields_wide)
test_frame_ljung_wide_3[!, L"\Delta t"] .= "3 years"
test_indep_ljung_wide_4 = HypothesisTests.LjungBoxTest(year_df[1:4:end, :R_max_day], 3)
test_frame_ljung_wide_4 = test_frame(test_indep_ljung_wide_4; fields=indep_test_fields_wide)
test_frame_ljung_wide_4[!, L"\Delta t"] .= ["4 years"]
# test_indep_ljung_wide_5 = HypothesisTests.LjungBoxTest(year_df[1:5:end, :R_max_day], 3)
# test_frame_ljung_wide_5 = test_frame(test_indep_ljung_wide_5; fields=indep_test_fields_wide)
# test_frame_ljung_wide_5[!, L"\Delta t"] .= ["5 years"]

test_indep_table_wide = vcat(test_frame_ljung_wide_2, test_frame_ljung_wide_3, test_frame_ljung_wide_4) #, test_frame_ljung_wide_5)
select!(test_indep_table_wide, Not("Test Name"))

open("./report/src/tables/test_indep_wide.tex"; truncate=true) do table
    format = Dict{Any,Any}(
        Float64 => x -> string(round(x; sigdigits=3)))
    write(table, latex_table(test_indep_table_wide; nhead = 0, format))
end

mean_test = HypothesisTests.OneWayANOVATest(year_df[1:2:end-1, :R_max_day], year_df[2:2:end, :R_max_day])

mean_test_frame = test_frame(mean_test)
mean_test_frame[1, "Test Name"] = "One-way ANOVA"
mean_test_frame[!, L"F"] = [HypothesisTests.teststatistic(mean_test)]

open("./report/src/tables/mean_test.tex"; truncate=true) do table
    format = Dict{Any,Any}(
        Float64 => x -> string(round(x; sigdigits=3)))
    write(table, latex_table(mean_test_frame; format))
end

var_test = HypothesisTests.LeveneTest(year_df[1:2:end-1, :R_max_day], year_df[2:2:end, :R_max_day])

var_test_frame = test_frame(var_test)
var_test_frame[!, L"W"] = [HypothesisTests.teststatistic(var_test)]

open("./report/src/tables/var_test.tex"; truncate=true) do table
    format = Dict{Any,Any}(
        Float64 => x -> string(round(x; sigdigits=3)))
    write(table, latex_table(var_test_frame; format))
end
