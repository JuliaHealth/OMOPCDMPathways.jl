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

    @assert nrow(df) > 0
        # Convert the cohort_start_date to DateTime and subtract the date_prior
        df.cohort_start_date = DateTime.(df.cohort_start_date) .- date_prior
    
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
            error("Invalid DataFrame")
        end

        return df
    end

- `treatment_history::DataFrame` - treatment history dataframe.

- `minEraDuration::Real` - minimum duration of an era.

# Returns:

- Updated `DataFrame`, rows where the difference between `drug_exposure_start` and `drug_exposure_end` is less than `minEraDuration` are filtered out.

    period_prior_to_index(
        cohort_id = [1, 1, 1, 1, 1],
        index_date_func = start_date_on_person,
        conn;
    )

# Implementation:
    (1) Calls GenerateTables with the database connection conn to generate tables, specifying inplace = false and exported = true.
    (2) Invokes the index_date_func function, passing cohort_id, the generated tables, and the connection conn, to obtain a DataFrame df.
    (3) Returns the DataFrame df.

It filters the treatment history `DataFrame` to retain only those rows where the duration between `drug_exposure_end` and `drug_exposure_start` is at least `minEraDuration`.

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




"""
```julia
EraCollapse(
    treatment_history::DataFrame, 
    eraCollapseSize::Int
)
```

Given a treatment history dataframe, this function collapses eras that are separated by a gap of size <= `eraCollapseSize`.

# Arguments:

- `treatment_history::DataFrame` - treatment history dataframe.containing drug_exposure_start and drug_exposure_end

- `eraCollapseSize::Int` - maximum gap size for collapsing eras.

# Returns:

- Updated dataframe, eras collapsed based on the specified gap size.


# Note: 

This is how the overall algorithm for this function is defined

1. Sorts the dataframe by event_start_date and event_end_date.
2. Calculates the gap between each era and the previous era.
3. Filters out rows with gap_same > eraCollapseSize.

It filters the treatment history `DataFrame` to retain only those rows where the duration between `drug_exposure_end` and `drug_exposure_start` is at least `minEraDuration`.

# Example:

```julia-repl
julia> test_person_ids = [1, 1, 1, 1, 1];

julia> test_drug_start_date = [-3.727296e8, 2.90304e7, -5.333472e8, -8.18208e7, 1.3291776e9];
    
julia> test_drug_end_date = [-364953600, 31449600, -532483200, -80006400, 1330387200]];
    
julia> test_df = DataFrame(person_id = test_person_ids, drug_exposure_start = test_drug_start_date, drug_exposure_end = test_drug_end_date)
    
julia> EraCollapse(treatment_history = test_df, eraCollapseSize = 400000000)
4×4 DataFrame
 Row │ person_id  drug_exposure_start  drug_exposure_end  gap_same   
     │ Int64      Float64              Int64              Float64    
─────┼───────────────────────────────────────────────────────────────
   1 │         1           -5.33347e8         -532483200  -1.86373e9
   2 │         1           -3.7273e8          -364953600   1.59754e8
   3 │         1           -8.18208e7          -80006400   2.83133e8
   4 │         1            2.90304e7           31449600   1.09037e8
```
"""
function EraCollapse(treatment_history::DataFrame, eraCollapseSize::Int)

    sort!(treatment_history, [:drug_exposure_start, :drug_exposure_end])
    treatment_history.lag_variable = circshift(treatment_history.drug_exposure_end, 1)
    treatment_history.gap_same = treatment_history.drug_exposure_start - treatment_history.lag_variable
    
    treatment_history = filter(row -> row[:gap_same] <= eraCollapseSize, treatment_history)
    select!(treatment_history, Not(:lag_variable))  
    
    return treatment_history
end



"""
```julia
calculate_era_duration(
    treatment_history::DataFrame, 
    minEraDuration::Real
)
```

Given a treatment history dataframe, this function filters out rows where the difference between `drug_exposure_start` and `drug_exposure_end` is less than `minEraDuration`.

# Arguments:

- `treatment_history::DataFrame` - treatment history dataframe.

- `minEraDuration::Real` - minimum duration of an era.

# Returns:

- Updated `DataFrame`, rows where the difference between `drug_exposure_start` and `drug_exposure_end` is less than `minEraDuration` are filtered out.

# Note: 

It filters the treatment history `DataFrame` to retain only those rows where the duration between `drug_exposure_end` and `drug_exposure_start` is at least `minEraDuration`.

# Example:

```julia-repl
julia> test_person_ids = [1, 1, 1, 1, 1];

julia> test_drug_start_date = [-3.727296e8, 2.90304e7, -5.333472e8, -8.18208e7, 1.3291776e9];

julia> test_drug_end_date = [-364953600, 31449600, -532483200, -80006400, 1330387200];

julia> test_df = DataFrame(person_id = test_person_ids, drug_exposure_start = test_drug_start_date, drug_exposure_end = test_drug_end_date);

julia> calculate_era_duration(test_df, 920000)
4×3 DataFrame
 Row │ person_id  drug_exposure_start  drug_exposure_end 
     │ Int64      Float64              Int64             
─────┼───────────────────────────────────────────────────
   1 │         1           -3.7273e8          -364953600
   2 │         1            2.90304e7           31449600
   3 │         1           -8.18208e7          -80006400
   4 │         1            1.32918e9         1330387200
```
"""
function calculate_era_duration(treatment_history::DataFrame, minEraDuration)
    
    treatment_history = filter(row -> (row[:drug_exposure_end] - row[:drug_exposure_start]) >= minEraDuration, treatment_history)    
    
    return treatment_history
end


function create_treatment_history(current_cohorts::DataFrame, targetCohortId::Int, cohort_ids::Vector{Int}, periodPriorToIndex::Int, includeTreatments::String)

    # Add index year column based on start date of target cohort
    targetCohort = current_cohorts[in.(current_cohorts.cohort_id, Ref([targetCohortId])), :]
    targetCohort.index_year = year.(targetCohort.cohort_start_date)

    # Select event cohorts for target cohort and merge with start/end date and index year
    eventCohorts = current_cohorts[in.(current_cohorts.cohort_id, Ref(cohort_ids)), :]

    current_cohorts = innerjoin(eventCohorts, targetCohort, on = :subject_id, makeunique = true)

    # Only keep event cohorts starting (startDate) or ending (endDate) after target cohort start date
    if includeTreatments == "startDate"
        current_cohorts = current_cohorts[
            (current_cohorts.cohort_start_date_1 .- (periodPriorToIndex) .<= current_cohorts.cohort_start_date) .& 
            (current_cohorts.cohort_start_date .< current_cohorts.cohort_end_date_1), :]
   
    elseif includeTreatments == "endDate"
        current_cohorts = current_cohorts[
            (current_cohorts.cohort_start_date_1 .- (periodPriorToIndex) .<= current_cohorts.cohort_end_date) .& 
            (current_cohorts.cohort_start_date .< current_cohorts.cohort_end_date_1), :]
        current_cohorts.cohort_start_date = max.(
            current_cohorts.cohort_start_date_1 .- (periodPriorToIndex), current_cohorts.cohort_start_date)
    else
        current_cohorts = current_cohorts[
            (current_cohorts.cohort_start_date_1 .- (periodPriorToIndex) .<= current_cohorts.cohort_start_date) .& 
            (current_cohorts.cohort_start_date .< current_cohorts.cohort_end_date_1), :]
    end

    # Calculate duration and gap same
    sort!(current_cohorts, [:cohort_start_date, :cohort_end_date])
    current_cohorts.lag_variable = circshift(current_cohorts.cohort_end_date, 1)
    current_cohorts.gap_same = current_cohorts.cohort_start_date .- current_cohorts.lag_variable
    select!(current_cohorts, Not(:lag_variable))

    return current_cohorts
end


"""

```julia
minPostCombinationDuration_filter(
    df::DataFrame, 
    minPostCombinationDuration :: Int
)
```

Given a treatment_history data-frame, this function will filter rows of the data-frame where GAP_PRVEVIOUS is missing or duration_era is greater than or equal to minPostCombinationDuration

# Argument:

- `treatment_history::DataFrame` - treatment history dataframe.

- `minPostCombinationDuration::Real` - minimum thresold.

# Returns:

- Updated 'DataFrame`, based on `minPostCombinationDuration` parameter


# Example:

```julia-repl
julia> df1 = DataFrame(GAP_PREVIOUS = [missing, 5, 10], duration_era = [15, 10, 8])

julia> result1 = minPostCombinationDuration_filter(df1, 10)

2x2 DataFrame
 Row │ GAP_PREVIOUS  duration_era 
     │ Int64?          Int64        
─────┼──────────────────────────────
   1 │        missing            15
   2 │              5            10
```
"""
function minPostCombinationDuration_filter(df::DataFrame, minPostCombinationDuration :: Int)
    # Filter rows where GAP_PREVIOUS is missing or duration_era is greater than or equal to minPostCombinationDuration
    filtered_df = filter(row -> isnothing(row.GAP_PREVIOUS) || row.duration_era >= minPostCombinationDuration, df)
    return filtered_df
end

export create_treatment_history, calculate_era_duration, EraCollapse, period_prior_to_index, minPostCombinationDuration_filter
