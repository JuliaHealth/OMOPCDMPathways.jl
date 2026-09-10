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


"""
```julia
create_treatment_history(
    current_cohorts::DataFrame,
    targetCohortId::Int,
    cohort_ids::Vector{Int},
    periodPriorToIndex::Int,
    includeTreatments::String,
)
```

Restrict a set of event cohort eras to the members and observation window of a
target cohort, producing the starting point for a treatment-history / pathway
analysis.

# Arguments

- `current_cohorts::DataFrame` - one row per cohort era, with columns
  `cohort_id`, `subject_id`, `cohort_start_date`, `cohort_end_date`. It must
  contain **both** the target cohort (`cohort_id == targetCohortId`) and the
  event cohorts (`cohort_id in cohort_ids`).
- `targetCohortId::Int` - `cohort_id` of the target cohort.
- `cohort_ids::Vector{Int}` - `cohort_id`s of the events (treatments) of interest.
- `periodPriorToIndex::Int` - number of days before the target index date from
  which an event era is still allowed to start.
- `includeTreatments::String` - `"startDate"` (default behaviour) keeps an event
  era when its **start** falls in `[index_date - periodPriorToIndex, target_end)`;
  `"endDate"` tests the era's **end** instead and clips its start to
  `index_date - periodPriorToIndex`.

# Returns

- A `DataFrame` of the event eras that survive the window filter, joined to their
  subject's target era (target columns are suffixed `_1`), sorted by
  `cohort_start_date`, `cohort_end_date`, with an added `index_year` and
  `gap_same` (gap to the previous era) column.
"""
function create_treatment_history(current_cohorts::DataFrame, targetCohortId::Int, cohort_ids::Vector{Int}, periodPriorToIndex::Int, includeTreatments::String)

    # `periodPriorToIndex` is a number of days; express it as a `Day` period so the
    # subtraction is well defined when the cohort date columns are `Date`/`DateTime`.
    priorOffset = periodPriorToIndex isa Dates.Period ? periodPriorToIndex : Day(periodPriorToIndex)

    # Add index year column based on start date of target cohort
    targetCohort = current_cohorts[in.(current_cohorts.cohort_id, Ref([targetCohortId])), :]
    targetCohort.index_year = year.(targetCohort.cohort_start_date)

    # Select event cohorts for target cohort and merge with start/end date and index year
    eventCohorts = current_cohorts[in.(current_cohorts.cohort_id, Ref(cohort_ids)), :]

    current_cohorts = innerjoin(eventCohorts, targetCohort, on = :subject_id, makeunique = true)

    # Only keep event cohorts starting (startDate) or ending (endDate) after target cohort start date
    if includeTreatments == "startDate"
        current_cohorts = current_cohorts[
            (current_cohorts.cohort_start_date_1 .- priorOffset .<= current_cohorts.cohort_start_date) .&
            (current_cohorts.cohort_start_date .< current_cohorts.cohort_end_date_1), :]

    elseif includeTreatments == "endDate"
        current_cohorts = current_cohorts[
            (current_cohorts.cohort_start_date_1 .- priorOffset .<= current_cohorts.cohort_end_date) .&
            (current_cohorts.cohort_start_date .< current_cohorts.cohort_end_date_1), :]
        current_cohorts.cohort_start_date = max.(
            current_cohorts.cohort_start_date_1 .- priorOffset, current_cohorts.cohort_start_date)
    else
        current_cohorts = current_cohorts[
            (current_cohorts.cohort_start_date_1 .- priorOffset .<= current_cohorts.cohort_start_date) .&
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
    selectRowsCombinationWindow!(treatment_history::DataFrame)

Sorts the `treatment_history` DataFrame by `person_id` and calculates the gap between consecutive treatments for the same person. It then marks rows with overlapping treatments in a new column `SELECTED_ROWS`.

# Arguments
- `treatment_history::DataFrame`: A DataFrame containing treatment history data. It must have the columns `person_id`, `event_start_date`, and `event_end_date`.

# Modifies
- Adds or updates the `GAP_PREVIOUS` column to `treatment_history`, representing the gap (in days) between the current treatment's start date and the previous treatment's end date for the same person. A positive value indicates no overlap, while a negative value or `missing` indicates potential overlap or a new sequence of treatments for a person.
- Adds or updates the `SELECTED_ROWS` column to `treatment_history`, marking rows with overlapping treatments (`1`) and non-overlapping treatments (`0`).

# Returns
- The modified `treatment_history` DataFrame with added `GAP_PREVIOUS` and `SELECTED_ROWS` columns.

# Example
```julia
using DataFrames, Dates
treatment_history = DataFrame(person_id=[1, 1, 2], event_start_date=[Date(2020, 1, 1), Date(2020, 1, 10), Date(2020, 2, 1)], event_end_date=[Date(2020, 1, 5), Date(2020, 1, 15), Date(2020, 2, 5)])
selectRowsCombinationWindow!(treatment_history)
```
"""

function selectRowsCombinationWindow!(treatment_history::DataFrame)
    sort!(treatment_history, [:person_id, :event_start_date, :event_end_date])
    
    n = nrow(treatment_history)
    treatment_history.GAP_PREVIOUS = Vector{Union{Int64, Missing}}(missing, n)
    treatment_history.SELECTED_ROWS = Vector{Int}(undef, n)

    # Compute gaps between consecutive rows
    for i in 2:n
        if treatment_history.person_id[i] == treatment_history.person_id[i-1]
            treatment_history.GAP_PREVIOUS[i] = Dates.value(treatment_history.event_start_date[i] - treatment_history.event_end_date[i-1])
        else
            treatment_history.GAP_PREVIOUS[i] = missing
        end
    end

    # Mark overlapping rows
    for i in 1:n
        if ismissing(treatment_history.GAP_PREVIOUS[i]) || treatment_history.GAP_PREVIOUS[i] >= 0
            treatment_history.SELECTED_ROWS[i] = 0
        else
            treatment_history.SELECTED_ROWS[i] = 1
        end
    end
    return treatment_history
end



"""
    combination_Window(treatment_history::DataFrame, combinationWindow::Day)

Resolve overlapping treatment eras in `treatment_history` into *switches* or
*combinations*, following the Switch / FRFS / LRFS logic of the OHDSI
`TreatmentPatterns` package.

For each pair of overlapping eras (of the same person):

- if the overlap is shorter than `combinationWindow` (and not equal to the full
  length of either era) it is a **Switch**: the earlier era's end date is pulled
  back to the later era's start date;
- otherwise the two eras are treated as a **combination** and the later era's end
  date is aligned to the earlier era's end date (**FRFS** when the earlier era
  ends first, **LRFS** when it ends last).

# Arguments
- `treatment_history::DataFrame`: must have the columns `person_id`,
  `event_start_date`, `event_end_date` and `event_cohort_id`
  (`event_start_date` / `event_end_date` must be `Date`).
- `combinationWindow::Day`: minimum overlap for two eras to count as a
  combination rather than a switch.

# Returns
- The modified `treatment_history` with adjusted `event_end_date` values and the
  `GAP_PREVIOUS` / `SELECTED_ROWS` bookkeeping columns added by
  `selectRowsCombinationWindow!`.

# Example
```julia
using DataFrames, Dates
treatment_history = DataFrame(person_id=[1, 1, 2], event_start_date=[Date(2020, 1, 1), Date(2020, 1, 10), Date(2020, 2, 1)], event_end_date=[Date(2020, 1, 5), Date(2020, 1, 15), Date(2020, 2, 5)], event_cohort_id=[101, 102, 201])
combination_Window(treatment_history, Day(5))
```
"""
function combination_Window(treatment_history::DataFrame, combinationWindow::Day)
    treatment_history = selectRowsCombinationWindow!(treatment_history)
    selected_row_count = count(x -> x == 1, treatment_history.SELECTED_ROWS)  # Count rows with SELECTED_ROWS == 1
    changes_made = true  # Initialize a flag to track changes
    iteration_count = 0  # Track number of iterations

    while iteration_count < selected_row_count && changes_made
        changes_made = false  
        selected_rows = findall(treatment_history.SELECTED_ROWS .== 1)

        for i in selected_rows
            gap_previous = treatment_history[i, :GAP_PREVIOUS]
            duration_era = Dates.value(treatment_history[i, :event_end_date] - treatment_history[i, :event_start_date])
            prev_duration_era = Dates.value(treatment_history[i-1, :event_end_date] - treatment_history[i-1, :event_start_date])

            if -gap_previous < Dates.value(combinationWindow) && !(-gap_previous in [duration_era, prev_duration_era])
                treatment_history[i-1, :event_end_date] = treatment_history[i, :event_start_date]
                changes_made = true
            elseif -gap_previous >= Dates.value(combinationWindow) || -gap_previous in [duration_era, prev_duration_era]
                if treatment_history[i-1, :event_end_date] <= treatment_history[i, :event_end_date]
                    treatment_history[i, :event_end_date] = treatment_history[i-1, :event_end_date]
                    changes_made = true
                else
                    treatment_history[i, :event_end_date] = treatment_history[i-1, :event_end_date]
                    changes_made = true
                end
            end
            # Mark the row as processed
            treatment_history[i, :SELECTED_ROWS] = 0
        end

        treatment_history = selectRowsCombinationWindow!(treatment_history)
        iteration_count += 1  # Increment the iteration counter
    end
    return treatment_history
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


# Coerce whatever a cohort table returns for a date column into a `Date`.
_as_date(x::Date) = x
_as_date(x::DateTime) = Date(x)
_as_date(x::AbstractString) = Date(first(strip(x), 10))
_as_date(x::Missing) = missing

"""
    query_cohorts_with_dates(conn, cohort_ids::Vector{Int}; tab = cohort)

Fetch every row of the `cohort` table whose `cohort_definition_id` is in
`cohort_ids` and return a `DataFrame` with the columns
`cohort_id`, `subject_id`, `cohort_start_date`, `cohort_end_date`.

Unlike [`period_prior_to_index`](@ref) this helper keeps the `cohort_end_date`
column and does **not** shift any dates — the `periodPriorToIndex` offset is
applied later (against the *target* cohort's index date) by
[`create_treatment_history`](@ref). The returned frame contains both the target
cohort and the event cohorts and is the `current_cohorts` input expected by
`create_treatment_history`.

The two date columns are coerced to `Date`, and `cohort_id`/`subject_id` to
`Int`, so the result has a stable schema regardless of how the backing database
stores cohort dates (ISO strings, `DATE`, or epoch values).
"""
function query_cohorts_with_dates(conn, cohort_ids::Vector{Int}; tab = cohort)
    sql = From(tab) |>
        Where(Fun.in(Get.cohort_definition_id, cohort_ids...)) |>
        Select(Get.cohort_definition_id, Get.subject_id, Get.cohort_start_date, Get.cohort_end_date) |>
        q -> render(q, dialect = dialect)

    df = DBInterface.execute(conn, String(sql)) |> DataFrame

    @assert nrow(df) > 0 "No cohort rows found for cohort ids $(cohort_ids)"

    rename!(df, :cohort_definition_id => :cohort_id)
    df.cohort_id = convert.(Int, df.cohort_id)
    df.subject_id = convert.(Int, df.subject_id)
    df.cohort_start_date = _as_date.(df.cohort_start_date)
    df.cohort_end_date = _as_date.(df.cohort_end_date)

    return df
end

"""
    execute_treatments(
        conn,
        target_cohort_id::Int,
        event_cohort_ids::Vector{Int};
        min_era_duration::Int = 30,
        era_collapse_size::Int = 30,
        period_prior::Day = Day(365),
        combination_window::Day = Day(30),
        min_post_combination_duration::Int = 30,
        include_treatments::String = "startDate",
    ) -> DataFrame

Run a full treatment-pathway synthesis for a `target_cohort_id` and a set of
`event_cohort_ids`, following the OHDSI `TreatmentPatterns` `constructPathways`
pipeline. This is a *sewing* function: it stitches together the pre-processing
primitives of this package in the right order and with a consistent column
contract.

# Pipeline

1. [`query_cohorts_with_dates`](@ref) pulls the target + event cohort eras from
   the `cohort` table in one `DataFrame`.
2. [`create_treatment_history`](@ref) restricts the event eras to the target
   cohort's members and to the observation window
   `[index_date - period_prior, target_cohort_end)` (`include_treatments`
   selects whether the event's start or end date is used for that test), and
   renames the columns to the `person_id` / `event_start_date` / `event_end_date`
   / `event_cohort_id` contract.
3. [`calculate_era_duration`](@ref) drops eras shorter than `min_era_duration`
   days (`minEraDuration`).
4. [`EraCollapse`](@ref) collapses eras of the same treatment separated by a gap
   `> era_collapse_size` days (`eraCollapseSize`) to the first era. It is applied
   per `(person, event_cohort_id)` so eras of different treatments are never
   dropped against each other.
5. [`combination_Window`](@ref) resolves overlapping eras into switches or
   combinations using `combination_window` (`combinationWindow`, Switch / FRFS /
   LRFS logic).
6. [`minPostCombinationDuration_filter`](@ref) drops the short single-treatment
   fragments left around a generated combination
   (`min_post_combination_duration` days).

# Arguments
- `conn`: database connection (e.g. an `SQLite.DB`) that has a `cohort` table.
- `target_cohort_id::Int`: `cohort_definition_id` of the target cohort.
- `event_cohort_ids::Vector{Int}`: `cohort_definition_id`s of the treatments of
  interest.

# Keyword arguments
- `min_era_duration::Int = 30`: minimum era length, in days.
- `era_collapse_size::Int = 30`: maximum gap, in days, for collapsing two eras of
  the same treatment.
- `period_prior::Day = Day(365)`: how far before the index date a treatment may
  start and still be included.
- `combination_window::Day = Day(30)`: minimum overlap for two eras to be treated
  as a combination rather than a switch.
- `min_post_combination_duration::Int = 30`: minimum length, in days, of a
  single-treatment fragment kept next to a combination.
- `include_treatments::String = "startDate"`: `"startDate"` or `"endDate"` —
  which date of an event era is tested against the observation window.

# Returns
A `DataFrame` sorted by `person_id`, `event_start_date` with columns:

| column | meaning |
|:--|:--|
| `person_id` | subject identifier |
| `event_start_date` | era start (`Date`) |
| `event_end_date` | era end (`Date`) after switch/combination adjustment |
| `event_cohort_id` | `cohort_definition_id` of the treatment |
| `GAP_PREVIOUS` | days between this era's start and the previous era's end for the same person (`missing` for the first era) |
| `SELECTED_ROWS` | `1` if the era still overlaps the previous one, else `0` |

# Example

```julia
using OMOPCDMPathways, SQLite, DataFrames, Dates
import DBInterface

conn = SQLite.DB("eunomia.sqlite")
MakeTables(conn, :sqlite, "main")   # sets up the internal `cohort` / `dialect` bindings

pathways = execute_treatments(
    conn,
    1,                       # target cohort
    [2, 3];                  # event cohorts
    min_era_duration = 5,
    combination_window = Day(30),
    min_post_combination_duration = 30,
)

first(pathways, 5)
```
"""
function execute_treatments(
    conn,
    target_cohort_id::Int,
    event_cohort_ids::Vector{Int};
    min_era_duration::Int = 30,
    era_collapse_size::Int = 30,
    period_prior::Day = Day(365),
    combination_window::Day = Day(30),
    min_post_combination_duration::Int = 30,
    include_treatments::String = "startDate",
)::DataFrame

    @assert !isempty(event_cohort_ids) "Event cohort IDs cannot be empty"
    @assert include_treatments in ["startDate", "endDate"] "include_treatments must be either 'startDate' or 'endDate'"

    empty_result() = DataFrame(
        person_id = Int[],
        event_start_date = Date[],
        event_end_date = Date[],
        event_cohort_id = Int[],
        GAP_PREVIOUS = Union{Int64, Missing}[],
        SELECTED_ROWS = Int[],
    )

    # 1. Target + event cohort eras, one frame, dates kept, nothing shifted.
    raw_cohorts = query_cohorts_with_dates(conn, Int[target_cohort_id; event_cohort_ids...])

    # 2. periodPriorToIndex + observation-window filtering against the target cohort.
    df = create_treatment_history(
        raw_cohorts,
        target_cohort_id,
        event_cohort_ids,
        Dates.value(period_prior),
        include_treatments,
    )
    isempty(df) && return empty_result()

    # Normalise to the treatment-history column contract. Keep the `Date` columns
    # (needed by `combination_Window`) and add an epoch-day view of the same eras
    # (needed by `calculate_era_duration` / `EraCollapse`, which compare against
    # plain `Int` day counts).
    rename!(df,
        :subject_id => :person_id,
        :cohort_id => :event_cohort_id,
        :cohort_start_date => :event_start_date,
        :cohort_end_date => :event_end_date,
    )
    df.drug_exposure_start = Dates.value.(df.event_start_date)
    df.drug_exposure_end = Dates.value.(df.event_end_date)

    # 3. minEraDuration, then 4. eraCollapseSize.
    df = calculate_era_duration(df, min_era_duration)
    isempty(df) && return empty_result()
    # `EraCollapse` compares each era against the previous *row*, so run it per
    # (person, treatment) group: `eraCollapseSize` is about gaps between eras of
    # the *same* treatment, and this keeps one person's / treatment's eras from
    # being collapsed against another's.
    df = combine(groupby(df, [:person_id, :event_cohort_id])) do sdf
        EraCollapse(select(DataFrame(sdf), Not([:person_id, :event_cohort_id])), era_collapse_size)
    end
    isempty(df) && return empty_result()

    # 5. combinationWindow (Switch / FRFS / LRFS) on the `Date` columns.
    df = combination_Window(df, combination_window)

    # 6. minPostCombinationDuration.
    df.duration_era = Dates.value.(df.event_end_date .- df.event_start_date)
    df = minPostCombinationDuration_filter(df, min_post_combination_duration)

    isempty(df) && return empty_result()

    # 7. Final projection.
    select!(df, [
        :person_id,
        :event_start_date,
        :event_end_date,
        :event_cohort_id,
        :GAP_PREVIOUS,
        :SELECTED_ROWS,
    ])
    sort!(df, [:person_id, :event_start_date])

    return df
end


export create_treatment_history, calculate_era_duration, EraCollapse, period_prior_to_index, minPostCombinationDuration_filter, combination_Window, execute_treatments, query_cohorts_with_dates
