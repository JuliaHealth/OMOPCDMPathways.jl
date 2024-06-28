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


"""
# Example:

    test_person_ids = [1, 1, 1, 1, 1]
    test_drug_start_date = [-3.727296e8, 2.90304e7, -5.333472e8, -8.18208e7, 1.3291776e9]
    test_drug_end_date = [-364953600, 31449600, -532483200, -80006400, 1330387200]
    
    test_df = DataFrame(person_id = test_person_ids, drug_exposure_start = test_drug_start_date, drug_exposure_end = test_drug_end_date)
    
    calculate_era_duration(
        treatment_history = test_df, 
        minEraDuration = 920000
    )

# Implemetation: 
    (1) It filters the treatment_history DataFrame to retain only those rows where the duration between drug_exposure_end and drug_exposure_start is at least minEraDuration.

Given a treatment history dataframe, this function filters out rows where the difference between drug_exposure_start and drug_exposure_end is less than minEraDuration.

    # Arguments:

    - treatment_history: DataFrame, treatment history dataframe.
    - minEraDuration: Int, minimum duration of an era.

    # Returns:
    - Updated dataframe, rows where the difference between drug_exposure_start and drug_exposure_end is less than minEraDuration are filtered out.

"""

function calculate_era_duration(treatment_history::DataFrame, minEraDuration)
    
    treatment_history = filter(row -> (row[:drug_exposure_end] - row[:drug_exposure_start]) >= minEraDuration, treatment_history)    
    
    return treatment_history
end

export Dummy, calculate_era_duration
