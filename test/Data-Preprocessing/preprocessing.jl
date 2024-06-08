using Test

@testset "Dummy Tests" begin
    MakeTables(sqlite_conn, :sqlite, "main")
    test_drug_exposure_ids = [1.0, 2.0, 3.0, 4.0]
    test_drug_exposure_start_date = [-3.727296e8, 2.90304e7, -5.333472e8, -8.18208e7]
    test_df1 = DataFrame(drug_exposure_id = test_drug_exposure_ids, drug_exposure_start_date = test_drug_exposure_start_date)
    result =  Dummy(test_drug_exposure_ids, sqlite_conn)

    @test test_drug_exposure_start_date == result.drug_exposure_start_date[1:4]
    @test test_drug_exposure_ids == result.drug_exposure_id[1:4]
    
    MakeTables(sqlite_conn, :sqlite, "main")
    test_cohort_ids = [1.0, 1.0, 1.0, 1.0]
    # test_df2 = DataFrame(cohort_definition_id = test_cohort_definition_id, cohort_id = test_cohort_ids)
    df = Dummy2(test_cohort_ids, sqlite_conn)
    println(first(df, 5))
end



@testset "Period Prior to Index Tests" begin
    MakeTables(sqlite_conn, :sqlite, "main")

    test_person_ids = [1, 1, 1, 1, 1]
    test_subject_ids = [1.0, 5.0, 9.0, 11.0, 12.0]
    test_cohort_start_date = [-3.7273e8, 2.90304e7, -5.33347e8, -8.18208e7, 1.32918e9]

    test_df2 = DataFrame(person_id = test_person_ids, cohort_start_date = test_cohort_start_date)
    
    result = period_prior_to_index(test_person_ids, sqlite_conn)

    println(result)

    @test test_person_ids == result.cohort_definition_id[1:5]
    @test test_subject_ids == result.subject_id[1:5]

    function start_date_on_person(cohort_id::Vector, tables)
        
        tab = tables[:cohort]
        
        sql = From(tab) |>
        Where(Fun.in(Get.cohort_definition_id, cohort_id...)) |>
        Select(Get.cohort_definition_id, Get.subject_id, Get.cohort_start_date) |>
        q -> render(q, dialect = :sqlite)

        return sql
    end

    result = period_prior_to_index(test_person_ids, start_date_on_person, sqlite_conn)
    
    @test test_person_ids == result.cohort_definition_id[1:5]
    @test test_subject_ids == result.subject_id[1:5]

end
