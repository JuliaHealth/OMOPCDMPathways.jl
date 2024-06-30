using DataFrames, Dates

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
EraCollapse(
    treatment_history::DataFrame, 
    eraCollapseSize::Int
)
```

Given a treatment history dataframe, this function collapses eras that are separated by a gap of size <= eraCollapseSize.

# Arguments:

- treatment_history: DataFrame, treatment history dataframe.containing drug_exposure_start and drug_exposure_end
- eraCollapseSize: Int, maximum gap size for collapsing eras.

# Returns:

- Updated dataframe, eras collapsed based on the specified gap size.


# Note: 

    (1) Sorts the dataframe by event_start_date and event_end_date.
    (2) Calculates the gap between each era and the previous era.
    (3) Filters out rows with gap_same > eraCollapseSize.

    It filters the treatment history `DataFrame` to retain only those rows where the duration between `drug_exposure_end` and `drug_exposure_start` is at least `minEraDuration`.


# Example:

```julia-repl
julia> [test_person_ids = [1, 1, 1, 1, 1]

julia> test_drug_start_date = [-3.727296e8, 2.90304e7, -5.333472e8, -8.18208e7, 1.3291776e9]
    
julia> test_drug_end_date = [-364953600, 31449600, -532483200, -80006400, 1330387200]]
    
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


export calculate_era_duration, EraCollapse

