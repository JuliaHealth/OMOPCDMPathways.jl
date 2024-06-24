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

function create_treatment_history(current_cohorts::DataFrame, targetCohortId::Int, cohort_ids::Vector{Int}, periodPriorToIndex::Int, includeTreatments::String)
    
    # Add index year column based on start date of target cohort
    targetCohort = current_cohorts[in.(current_cohorts.cohort_id, Ref([targetCohortId])), :]
    targetCohort.index_year = year.(targetCohort.cohort_start_date)
    #println("Target Cohort DataFrame:")
    #println(targetCohort)
    
    # Select event cohorts for target cohort and merge with start/end date and index year
    eventCohorts = current_cohorts[in.(current_cohorts.cohort_id, Ref(cohort_ids)), :]
    #println("\nEvent Cohorts DataFrame:")
    #println(eventCohorts)
    
    current_cohorts = innerjoin(eventCohorts, targetCohort, on = :subject_id, makeunique = true)
    #println("\nMerged DataFrame:")
    #println(current_cohorts)
    
    # Only keep event cohorts starting (startDate) or ending (endDate) after target cohort start date
    if includeTreatments == "startDate"
        #println("Applying startDate filtering")
        #println("periodPriorToIndex: ", periodPriorToIndex)
        #println("cohort_start_date_1: ", current_cohorts.cohort_start_date_1)
        #("cohort_start_date: ", current_cohorts.cohort_start_date)
        #println("cohort_end_date_1: ", current_cohorts.cohort_end_date_1)
        
        current_cohorts = current_cohorts[
            (current_cohorts.cohort_start_date_1 .- (periodPriorToIndex) .<= current_cohorts.cohort_start_date) .& 
            (current_cohorts.cohort_start_date .< current_cohorts.cohort_end_date_1), :]
    elseif includeTreatments == "endDate"
        #println("Applying endDate filtering")
        #println("periodPriorToIndex: ", periodPriorToIndex)
        #println("cohort_start_date_1: ", current_cohorts.cohort_start_date_1)
        #println("cohort_end_date: ", current_cohorts.cohort_end_date)
        #println("cohort_end_date_1: ", current_cohorts.cohort_end_date_1)
        
        current_cohorts = current_cohorts[
            (current_cohorts.cohort_start_date_1 .- (periodPriorToIndex) .<= current_cohorts.cohort_end_date) .& 
            (current_cohorts.cohort_start_date .< current_cohorts.cohort_end_date_1), :]
        current_cohorts.cohort_start_date = max.(
            current_cohorts.cohort_start_date_1 .- (periodPriorToIndex), current_cohorts.cohort_start_date)
    else
        #println("includeTreatments input incorrect, returning all event cohorts ('includeTreatments')")
        current_cohorts = current_cohorts[
            (current_cohorts.cohort_start_date_1 .- (periodPriorToIndex) .<= current_cohorts.cohort_start_date) .& 
            (current_cohorts.cohort_start_date .< current_cohorts.cohort_end_date_1), :]
    end
    
    #println("\nFiltered DataFrame after applying includeTreatments:")
    #println(current_cohorts)
    
    # Calculate duration and gap same
    sort!(current_cohorts, [:cohort_start_date, :cohort_end_date])
    current_cohorts.lag_variable = circshift(current_cohorts.cohort_end_date, 1)
    current_cohorts.gap_same = current_cohorts.cohort_start_date .- current_cohorts.lag_variable
    select!(current_cohorts, Not(:lag_variable))

    return current_cohorts
end

export Dummy, create_treatment_history
