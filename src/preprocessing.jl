using Dates

"""
# Example:

    period_prior_to_index(
        cohort_id = [1, 1, 1, 1, 1], 
        conn; 
        date_prior = Day(100), 
        tab=cohort
    )

# Implemetation: 
    (1) Constructs a SQL query to select cohort_definition_id, subject_id, and cohort_start_date from a specified table, filtering by cohort_id.
    (2) Executes the constructed SQL query using a database connection, fetching the results into a DataFrame.
    (3) If the DataFrame is not empty, converts cohort_start_date to DateTime and subtracts date_prior from each date, then returns the modified DataFrame.

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

#Example:
    function start_date_on_person(cohort_id::Vector, tables, conn)
        
        tab = tables[:cohort]
        date_prior = Day(100)
            
        sql = From(tab) |>
        Where(Fun.in(Get.cohort_definition_id, cohort_id...)) |>
        Select(Get.cohort_definition_id, Get.subject_id, Get.cohort_start_date) |>
        q -> render(q, dialect = :sqlite)
            
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

    period_prior_to_index(
        cohort_id = [1, 1, 1, 1, 1],
        index_date_func = start_date_on_person,
        conn;
    )

# Implementation:
    (1) Calls GenerateTables with the database connection conn to generate tables, specifying inplace = false and exported = true.
    (2) Invokes the index_date_func function, passing cohort_id, the generated tables, and the connection conn, to obtain a DataFrame df.
    (3) Returns the DataFrame df.

function period_prior_to_index(person_ids::Vector, index_date_func::Function, conn; date_prior=Day(100))

Given a vector of person IDs, this function returns a DataFrame with the cohort_start_date adjusted by the date_prior.

# Arguments:

- `cohort_id` - vector of cohort IDs
- `index_date_func` - function that returns the SQL query to get the start date of the person
- `conn` - database connection

# Returns

- DataFrame with the `cohort_start_date` adjusted by the `date_prior`.

"""

function period_prior_to_index(
        cohort_id::Vector, 
        index_date_func::Function, 
        conn; 
    )

    tables = GenerateTables(conn, inplace = false, exported=true)

    df = index_date_func(cohort_id, tables, conn)
    
    return df
end

export period_prior_to_index
