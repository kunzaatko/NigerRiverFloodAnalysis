using DataFrames, CSV, Dates, Memoize

DATA_FILE_DAY = "River_Niger_Q_Day.Cmd.txt"
DATA_FILE_MONTH = "River_Niger_Q_Month.txt"

DATA_DIR = "data"

MONTH_NAMES =
    Dict(1 => "January",
        2 => "February",
        3 => "March",
        4 => "April",
        5 => "May",
        6 => "June",
        7 => "July",
        8 => "August",
        9 => "September",
        10 => "October",
        11 => "November",
        12 => "December")

read_data(; dir=".") = read_data(abspath(joinpath(dir, DATA_DIR)))

@memoize function read_data(data_dir_path)
    day_data_file = joinpath(data_dir_path, DATA_FILE_DAY)
    day_header = filter(readlines(day_data_file)) do line
        line[1] == '#'
    end
    day_header = join(day_header, "\n")
    day_df = CSV.read(day_data_file, DataFrame, comment="#", drop=[2], normalizenames=true)
    rename!(day_df, "YYYY_MM_DD" => :date, "Value" => :value)
    day_df[!, :Q] = map(day_df[!, :value]) do val
        val <= 0.0 ? missing : val
    end
    day_df[!, :imonth] = month.(day_df[!, :date])
    day_df[!, :month] = map(i -> MONTH_NAMES[i], day_df[!, :imonth])

    day_df[!, :year] = year.(day_df[!, :date])
    day_df[!, :year_ind] = getfield.(day_df[!, :date] .- firstdayofyear.(day_df[!, :date]) .+ Day(1), :value) ./ float.(daysinyear.(day_df[!, :year]))

    day_df = day_df[day_df[!, :year].>=1944, :]

    month_data_file = joinpath(data_dir_path, DATA_FILE_MONTH)
    month_header = filter(readlines(month_data_file)) do line
        line[1] == '#'
    end
    month_header = join(month_header, "\n")
    month_df = CSV.read(month_data_file, DataFrame, comment="#", drop=[2], normalizenames=true)
    rename!(month_df, "YYYY_MM_DD" => :date, "Calculated" => :value)
    month_df[!, :Q] = map(eachrow(month_df[!, Cols(:value, "Flag")])) do (val, flag)
        flag != 100 && val < 0.0 ? missing : val
    end
    month_df[!, :year] = year.(month_df[!, :date])
    month_df = month_df[month_df[!, :year].>=1944, :]

    yearly_df = combine(groupby(month_df, :year), :Q => maximum ∘ skipmissing => :R_max, :Q => minimum ∘ skipmissing => :R_min)
    yearly_df = innerjoin(yearly_df,
        combine(groupby(day_df, :year),
            :Q => maximum ∘ skipmissing => :R_max_day,
            :Q => minimum ∘ skipmissing => :R_min_day),
        on=:year)

    return day_df, day_header, month_df, month_header, yearly_df
end
