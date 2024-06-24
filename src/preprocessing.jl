using Dates

"""
function period_prior_to_index(cohort_id::Vector, conn; date_prior=Day(100), tab=cohort)

Given `cohort_id's` , return a `DataFrame` with the `cohort_start_date` adjusted to prior each subjects' cohort entry date (i.e. their `cohort_start_date`)
# Arguments:

- `cohort_id` - vector of cohort IDs
- `conn` - database connection

# Keyword Arguments:

- `date_prior::Dates.AbstractTime` - how much time prior the index date should be adjusted by; accepts a `Dates.AbstractTim`e object such as `Day`, `Month`, etc. (Default: `Day(100)`)
- `tab` - the `SQLTable` representing the cohort table. (Default: `cohort`)

# Returns

- DataFrame with the `cohort_start_date` adjusted by the `date_prior`.
"""
function period_prior_to_index(cohort_id::Vector, conn; date_prior=Day(100), tab=cohort)

    # Construct the SQL query
    sql = From(tab) |>
            Where(Fun.in(Get.cohort_definition_id, cohort_id...)) |>
            Select(Get.cohort_definition_id, Get.subject_id, Get.cohort_start_date) |>
            q -> render(q, dialect=dialect)

    # Execute the SQL query and fetch the result into a DataFrame
    df = DBInterface.execute(conn, String(sql)) |> DataFrame

    if nrow(df) > 0
        # Convert the cohort_start_date to DateTime and subtract the date_prior
        df.cohort_start_date = DateTime.(df.cohort_start_date) .- date_prior
    else
        error("Invalid DataFrame: $df")
    end

    return df
end


"""
function period_prior_to_index(person_ids::Vector, index_date_func::Function, conn; date_prior=Day(100))

Given a vector of person IDs, this function returns a DataFrame with the cohort_start_date adjusted by the date_prior.

# Arguments:

- `cohort_id` - vector of cohort IDs
- `index_date_func` - function that returns the SQL query to get the start date of the person
- `conn` - database connection

# Keyword Arguments:

- `date_prior::Dates.AbstractTime` - how much time prior the index date should be adjusted by; accepts a `Dates.AbstractTim`e object such as `Day`, `Month`, etc. (Default: `Day(100)`)

# Returns

- DataFrame with the `cohort_start_date` adjusted by the `date_prior`.
"""
function period_prior_to_index(
        cohort_id::Vector, 
        index_date_func::Function, 
        conn; 
        date_prior=Day(100)
    )

    tables = GenerateTables(conn, inplace = false, exported=true)

    sql = index_date_func(cohort_id, tables)

    df = DBInterface.execute(conn, String(sql)) |> DataFrame

    # Check if the DataFrame is not empty
    if nrow(df) > 0
        # Convert the cohort_start_date to DateTime and subtract the date_prior
        df.cohort_start_date = DateTime.(df.cohort_start_date) .- date_prior
    else
        error("Invalid DataFrame: $df")
    end
    
    return df
end


export period_prior_to_index
