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