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
Given a treatment history dataframe, this function filters out rows where the difference between drug_exposure_start and drug_exposure_end is less than minEraDuration.

    # Arguments:

    - treatment_history: DataFrame, treatment history dataframe.
    - minEraDuration: Int, minimum duration of an era.

    # Returns:
    - Updated dataframe, rows where the difference between drug_exposure_start and drug_exposure_end is less than minEraDuration are filtered out.

"""
function EraDuration(treatment_history::DataFrame, minEraDuration)
    treatment_history = filter(row -> (row[:drug_exposure_end] - row[:drug_exposure_start]) >= minEraDuration, treatment_history)
    @info "After minEraDuration: $(nrow(treatment_history))"  # For debugging purposes
    
    return treatment_history
end

export Dummy, EraDuration
