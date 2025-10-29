using DataFrames, InteractiveUtils

function latex_table(df::DataFrame;
    nhead=1,
    format=Dict{Any,Any}(Any => x -> string(x)),
    toprow=raw"\toprule",
    headrow=raw"\midrule",
    endrow=raw"\addlinespace",
    bottomrow=raw"\bottomrule",
    headcentering=raw"r",
    centering=raw">{\centering\arraybackslash}X")
    if !(Type{Any} in keys(format))
        format[Any] = x -> string(x)
    end
    out = raw"\begin{tabularx}{\linewidth}" * "{" * repeat(headcentering, nhead) * repeat(centering, size(df, 2) - nhead) * "}\n" * toprow
    out *= "  "
    df_names = names(df)
    for (i, n) in enumerate(df_names)
        out *= string(n)
        if i != length(df_names)
            out *= " & "
        end
    end
    out *= "\\\\" * headrow * "\n"
    for (i, row) in enumerate(eachrow(df))
        out *= "  "
        for (i, c) in enumerate(row)
            local formated = nothing
            for stype in supertypes(typeof(c))
                if stype in keys(format)
                    formated = format[stype](c)
                    break
                end
            end
            out *= formated
            if i != length(row)
                out *= " & "
            end
        end
        if i != size(df, 1)
            out *= "\\\\" * endrow * "\n"
        end
    end
    out *= "\\\\" * bottomrow * "\n"
    out *= raw"\end{tabularx}"
end
