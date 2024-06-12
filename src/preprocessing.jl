using Dates

function Dummy(
    drug_exposure_ids,
    conn;
    tab = drug_exposure 
)

    df = DBInterface.execute(conn, Dummy(drug_exposure_ids; tab=tab)) |> DataFrame

    return df
end

function Dummy(
    drug_exposure_ids;
    tab = drug_exposure
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.drug_exposure_id, drug_exposure_ids...)) |>
        Select(Get.drug_exposure_id, Get.drug_exposure_start_date) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end

function Dummy2(
    cohort_ids::Vector,
    conn;
    tab = cohort 
)

    df = DBInterface.execute(conn, Dummy2(cohort_ids; tab=tab)) |> DataFrame

    return df
end

function Dummy2(
    cohort_ids::Vector;
    tab = cohort
)

    sql =
        From(tab) |>
        Where(Fun.in(Get.cohort_definition_id, cohort_ids...)) |>
        Select(Get.cohort_definition_id, Get.subject_id) |>
        q -> render(q, dialect=dialect)

    return String(sql)

end









"""
function Period_prior_to_index(cohort_id::Vector, conn; date_prior=Day(100), tab=cohort)

Given a vector of cohort IDs, this function returna a DataFrame with the cohort_start_date adjusted by the date_prior.

# Arguments:

- `cohort_id` - vector of cohort IDs
- `conn` - database connection

# Keyword Arguments:

- `date_prior` - period prior to the index date; default is 100 days
- `tab` - the `SQLTable` representing the cohort table; default `cohort`

# Returns

- DataFrame with the cohort_start_date adjusted by the date_prior.
"""
function Period_prior_to_index(cohort_id::Vector, conn; date_prior=Day(100), tab=cohort)

    # Construct the SQL query
    sql = From(tab) |>
            Where(Fun.in(Get.cohort_definition_id, cohort_id...)) |>
            Select(Get.cohort_definition_id, Get.subject_id, Get.cohort_start_date) |>
            q -> render(q, dialect=dialect)

    # Execute the SQL query and fetch the result into a DataFrame
    df = DBInterface.execute(conn, String(sql)) |> DataFrame

    # Check if the DataFrame is not empty
    # TODO: Is it really necessary to add this check ??
    if nrow(df) > 0
        # Convert the cohort_start_date to DateTime and subtract the date_prior
        df.cohort_start_date = DateTime.(df.cohort_start_date) .- date_prior
    end

    return df
end


"""
function Period_prior_to_index(person_ids::Vector, start_date_on_person::Function, conn; date_prior=Day(100))

Given a vector of person IDs, this function returns a DataFrame with the cohort_start_date adjusted by the date_prior.

# Arguments:

- `person_ids` - vector of person IDs
- `start_date_on_person` - function that returns the SQL query to get the start date of the person
- `conn` - database connection

# Keyword Arguments:

- `date_prior` - period prior to the index date; default is 100 days

# Returns

- DataFrame with the cohort_start_date adjusted by the date_prior.
"""
function Period_prior_to_index(
        person_ids::Vector, 
        start_date_on_person::Function, 
        conn; 
        date_prior=Day(100)
    )

    tables = GenerateTables(conn, inplace = false, exported=true)

    sql = start_date_on_person(person_ids, tables)

    df = DBInterface.execute(conn, String(sql)) |> DataFrame

    # Check if the DataFrame is not empty
    # TODO: Is it really necessary to add this check ??
    if nrow(df) > 0
        # Convert the cohort_start_date to DateTime and subtract the date_prior
        df.cohort_start_date = DateTime.(df.cohort_start_date) .- date_prior
    end

    return df
end


export Dummy, Period_prior_to_index, Dummy2
