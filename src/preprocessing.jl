using DataFrames, Dates

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



"""
# Example:
    [test_person_ids = [1, 1, 1, 1, 1]
    test_drug_start_date = [-3.727296e8, 2.90304e7, -5.333472e8, -8.18208e7, 1.3291776e9]
    test_drug_end_date = [-364953600, 31449600, -532483200, -80006400, 1330387200]]
    test_df = DataFrame(person_id = test_person_ids, drug_exposure_start = test_drug_start_date, drug_exposure_end = test_drug_end_date)
    
    EraCollapse(
        treatment_history = test_df,
        eraCollapseSize = 400000000
    )

# Implemetation: 
    (1) Sorts the dataframe by event_start_date and event_end_date.
    (2) Calculates the gap between each era and the previous era.
    (3) Filters out rows with gap_same > eraCollapseSize.

Given a treatment history dataframe, this function collapses eras that are separated by a gap of size <= eraCollapseSize.

# Arguments:

- treatment_history: DataFrame, treatment history dataframe.containing drug_exposure_start and drug_exposure_end
- eraCollapseSize: Int, maximum gap size for collapsing eras.

# Returns:

- Updated dataframe, eras collapsed based on the specified gap size.
"""


function EraCollapse(treatment_history::DataFrame, eraCollapseSize::Int)

    sort!(treatment_history, [:drug_exposure_start, :drug_exposure_end])
    treatment_history.lag_variable = circshift(treatment_history.drug_exposure_end, 1)
    treatment_history.gap_same = treatment_history.drug_exposure_start - treatment_history.lag_variable
    
    treatment_history = filter(row -> row[:gap_same] <= eraCollapseSize, treatment_history)
    select!(treatment_history, Not(:lag_variable))  
    
    return treatment_history
end


export Dummy, EraCollapse
