using Test

@testset "Dummy Tests" begin
    MakeTables(sqlite_conn, :sqlite, "main")
    test_drug_exposure_ids = [1.0, 2.0, 3.0, 4.0]
    test_drug_exposure_start_date = [-3.727296e8, 2.90304e7, -5.333472e8, -8.18208e7]
    test_df1 = DataFrame(drug_exposure_id = test_drug_exposure_ids, drug_exposure_start_date = test_drug_exposure_start_date)
    result =  Dummy(test_drug_exposure_ids, sqlite_conn)

    @test test_drug_exposure_start_date == result.drug_exposure_start_date[1:4]
    @test test_drug_exposure_ids == result.drug_exposure_id[1:4]

end



@testset "Era Duration Tests" begin
    MakeTables(sqlite_conn, :sqlite, "main")
    
    test_person_ids = [1, 1, 1, 1, 1]
    test_drug_start_date = [-3.727296e8, 2.90304e7, -5.333472e8, -8.18208e7, 1.3291776e9]
    test_drug_end_date = [-364953600, 31449600, -532483200, -80006400, 1330387200]
    
    test_df3 = DataFrame(person_id = test_person_ids, drug_exposure_start = test_drug_start_date, drug_exposure_end = test_drug_end_date)
    
    expected_person_id = [1, 1, 1, 1]
    expected_drug_exposure_start = [-3.727296e8, 2.90304e7, -8.18208e7, 1.3291776e9]
    expected_drug_exposure_end = [-364953600, 31449600, -80006400, 1330387200]

    result = EraDuration(test_df3, 920000)

    @test expected_person_id == result.person_id[1:4]
    @test expected_drug_exposure_start == result.drug_exposure_start[1:4]
    @test expected_drug_exposure_end == result.drug_exposure_end[1:4]
end