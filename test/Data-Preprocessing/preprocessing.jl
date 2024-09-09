using Test

@testset "Period Prior to Index Tests" begin
    MakeTables(sqlite_conn, :sqlite, "main")

    test_person_ids = [1, 1, 1, 1, 1]
    test_subject_ids = [1.0, 5.0, 9.0, 11.0, 12.0]
    test_cohort_start_date = [-3.7273e8, 2.90304e7, -5.33347e8, -8.18208e7, 1.32918e9]

    test_df2 = DataFrame(person_id = test_person_ids, cohort_start_date = test_cohort_start_date)
    
    result = period_prior_to_index(test_person_ids, sqlite_conn)

    @test test_person_ids == result.cohort_definition_id[1:5]
    @test test_subject_ids == result.subject_id[1:5]

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

    result = period_prior_to_index(test_person_ids, start_date_on_person, sqlite_conn)
    
    @test test_person_ids == result.cohort_definition_id[1:5]
    @test test_subject_ids == result.subject_id[1:5]

    # test for the invalid dataframe
    cohort_id = []
    @test_throws AssertionError period_prior_to_index(cohort_id, sqlite_conn) 
end
  
@testset "Calculate Era Duration Tests" begin
    MakeTables(sqlite_conn, :sqlite, "main")
    
    test_person_ids = [1, 1, 1, 1, 1]
    test_drug_start_date = [-3.727296e8, 2.90304e7, -5.333472e8, -8.18208e7, 1.3291776e9]
    test_drug_end_date = [-364953600, 31449600, -532483200, -80006400, 1330387200]
    
    test_df3 = DataFrame(person_id = test_person_ids, drug_exposure_start = test_drug_start_date, drug_exposure_end = test_drug_end_date)
    
    expected_person_id = [1, 1, 1, 1]
    expected_drug_exposure_start = [-3.727296e8, 2.90304e7, -8.18208e7, 1.3291776e9]
    expected_drug_exposure_end = [-364953600, 31449600, -80006400, 1330387200]

    result = calculate_era_duration(test_df3, 920000)

    @test expected_person_id == result.person_id[1:4]
    @test expected_drug_exposure_start == result.drug_exposure_start[1:4]
    @test expected_drug_exposure_end == result.drug_exposure_end[1:4]
end


@testset "Era Collapse Tests" begin

    MakeTables(sqlite_conn, :sqlite, "main")
    
    test_person_ids = [1, 1, 1, 1, 1]
    test_drug_start_date = [-3.727296e8, 2.90304e7, -5.333472e8, -8.18208e7, 1.3291776e9]
    test_drug_end_date = [-364953600, 31449600, -532483200, -80006400, 1330387200]
    test_df3 = DataFrame(person_id = test_person_ids, drug_exposure_start = test_drug_start_date, drug_exposure_end = test_drug_end_date)
    
    expected_person_id = [1, 1, 1, 1]
    expected_drug_exposure_start = [-5.333472e8, -3.727296e8, -8.18208e7, 2.90304e7]
    expected_drug_exposure_end = [-532483200, -364953600, -80006400, 31449600]

    result = EraCollapse(test_df3, 400000000)
    

    @test expected_person_id == result.person_id[1:4]
    @test expected_drug_exposure_start == result.drug_exposure_start[1:4]
    @test expected_drug_exposure_end == result.drug_exposure_end[1:4]
end


function create_mock_cohorts()
    return DataFrame(
        cohort_id = [1.0, 1.0, 1.0, 1.0],
        subject_id = [1.0, 5.0, 9.0, 11.0],
        cohort_start_date = [-3.727296e8, 2.90304e7, -5.333472e8, -8.18208e7],
        cohort_end_date = [-364953600, 31449600, -532483200, -80006400],
        cohort_start_date_1 = [Date(2020, 1, 15), Date(2018, 2, 15), Date(2016, 3, 15), Date(2014, 4, 15)],
        cohort_end_date_1 = [Date(2048, 2, 14), Date(2050, 3, 14), Date(2052, 4, 14), Date(2054, 5, 14)]
    )
end

@testset "create_treatment_history Tests" begin
    cohorts = create_mock_cohorts()
    filtered_cohorts = create_treatment_history(cohorts, 1, [2, 3], 9200000, "startDate")
    print(filtered_cohorts)
    @test size(filtered_cohorts, 1) == 0


    cohorts = create_mock_cohorts()
    filtered_cohorts = create_treatment_history(cohorts, 1, [2, 3], 9200000, "endDate")
    @test size(filtered_cohorts, 1) == 0
    print(filtered_cohorts)


    cohorts = create_mock_cohorts()
    filtered_cohorts = create_treatment_history(cohorts, 1, [2, 3], 9200000, "wrongValue")
    @test size(filtered_cohorts, 1) == 0
    print(filtered_cohorts)

end
