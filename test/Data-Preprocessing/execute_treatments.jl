using Test

# ---------------------------------------------------------------------------
# Integration tests for `execute_treatments` (the "sewing" function that runs a
# full pathway synthesis end-to-end) against the Eunomia SQLite sample database.
#
# We do not rely on real vocabulary concepts: instead we insert a handful of
# synthetic rows straight into the `cohort` table so the expected output can be
# reasoned about by hand, mirroring the events A/B/C example of Fig. 1 in
# Markus et al. (2022), "TreatmentPatterns".
#
#   cohort 90  -> target cohort, subjects 1..6, observation window 2015..2020
#   cohort 91  -> event "A"
#   cohort 92  -> event "B"
# ---------------------------------------------------------------------------

const TARGET = 90
const EVENT_A = 91
const EVENT_B = 92

function _load_synthetic_cohorts!(conn)
    DBI.execute(conn, "DELETE FROM cohort WHERE cohort_definition_id IN ($TARGET, $EVENT_A, $EVENT_B, 93)")
    rows = [
        # target cohort: one row per subject
        (TARGET, 1, "2015-01-01", "2020-01-01"),
        (TARGET, 2, "2015-01-01", "2020-01-01"),
        (TARGET, 3, "2015-01-01", "2020-01-01"),
        (TARGET, 4, "2015-01-01", "2020-01-01"),
        (TARGET, 5, "2015-01-01", "2020-01-01"),
        (TARGET, 6, "2015-01-01", "2020-01-01"),
        # subject 1 - no overlap: pure pass-through
        (EVENT_A, 1, "2015-02-01", "2015-05-01"),
        (EVENT_B, 1, "2015-08-01", "2015-12-01"),
        # subject 2 - 12 day overlap (< combinationWindow) -> Switch
        (EVENT_A, 2, "2016-01-01", "2016-04-01"),
        (EVENT_B, 2, "2016-03-20", "2016-07-01"),
        # subject 3 - 92 day overlap, A ends before B -> FRFS combination
        (EVENT_A, 3, "2017-01-01", "2017-06-01"),
        (EVENT_B, 3, "2017-03-01", "2017-09-01"),
        # subject 4 - B fully inside A -> LRFS combination
        (EVENT_A, 4, "2018-01-01", "2018-12-01"),
        (EVENT_B, 4, "2018-03-01", "2018-06-01"),
        # subject 5 - small overlap -> Switch, leaving a short B fragment that
        # minPostCombinationDuration then drops
        (EVENT_A, 5, "2019-01-01", "2019-02-10"),
        (EVENT_B, 5, "2019-02-05", "2019-02-25"),
        # subject 6 - two eras of the *same* treatment 10 days apart
        (EVENT_A, 6, "2015-03-01", "2015-04-01"),
        (EVENT_A, 6, "2015-04-11", "2015-05-11"),
    ]
    for (cid, sid, s, e) in rows
        DBI.execute(conn,
            "INSERT INTO cohort (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date) " *
            "VALUES ($cid, $sid, '$s', '$e')")
    end
    return conn
end

prows(df, id) = sort(df[df.person_id .== id, :], :event_start_date)

@testset "execute_treatments" begin
    MakeTables(sqlite_conn, :sqlite, "main")
    _load_synthetic_cohorts!(sqlite_conn)

    @testset "_as_date coercion" begin
        @test OMOPCDMPathways._as_date(Date(2015, 1, 2)) == Date(2015, 1, 2)
        @test OMOPCDMPathways._as_date(DateTime(2015, 1, 2, 3, 4, 5)) == Date(2015, 1, 2)
        @test OMOPCDMPathways._as_date("2015-01-02 00:00:00") == Date(2015, 1, 2)
        @test ismissing(OMOPCDMPathways._as_date(missing))
    end

    @testset "query_cohorts_with_dates helper" begin
        raw = OMOPCDMPathways.query_cohorts_with_dates(sqlite_conn, [TARGET, EVENT_A, EVENT_B])
        @test sort(names(raw)) == ["cohort_end_date", "cohort_id", "cohort_start_date", "subject_id"]
        @test eltype(raw.cohort_start_date) == Date
        @test eltype(raw.cohort_end_date) == Date
        @test eltype(raw.cohort_id) == Int
        @test eltype(raw.subject_id) == Int
        @test Set(raw.cohort_id) == Set([TARGET, EVENT_A, EVENT_B])
    end

    @testset "argument validation" begin
        @test_throws AssertionError execute_treatments(sqlite_conn, TARGET, Int[])
        @test_throws AssertionError execute_treatments(sqlite_conn, TARGET, [EVENT_A]; include_treatments = "bogus")
    end

    # Generous era_collapse_size so that only the combinationWindow / minEraDuration
    # / minPostCombinationDuration steps shape the result.
    result = execute_treatments(sqlite_conn, TARGET, [EVENT_A, EVENT_B];
        min_era_duration = 5,
        era_collapse_size = 100_000,
        period_prior = Day(365),
        combination_window = Day(30),
        min_post_combination_duration = 30,
        include_treatments = "startDate")

    @testset "output contract" begin
        @test names(result) == ["person_id", "event_start_date", "event_end_date",
                                "event_cohort_id", "GAP_PREVIOUS", "SELECTED_ROWS"]
        @test eltype(result.person_id) == Int
        @test eltype(result.event_start_date) == Date
        @test eltype(result.event_end_date) == Date
        @test eltype(result.event_cohort_id) == Int
        @test isequal(result, sort(result, [:person_id, :event_start_date]))
        @test Set(result.event_cohort_id) ⊆ Set([EVENT_A, EVENT_B])
    end

    @testset "subject 1 - no overlap, pass-through" begin
        p = prows(result, 1)
        @test nrow(p) == 2
        @test p.event_cohort_id == [EVENT_A, EVENT_B]
        @test p.event_start_date == [Date(2015, 2, 1), Date(2015, 8, 1)]
        @test p.event_end_date == [Date(2015, 5, 1), Date(2015, 12, 1)]   # unchanged
        @test p.SELECTED_ROWS == [0, 0]
        @test ismissing(p.GAP_PREVIOUS[1])
        @test p.GAP_PREVIOUS[2] == Dates.value(Date(2015, 8, 1) - Date(2015, 5, 1))
    end

    @testset "subject 2 - Switch" begin
        p = prows(result, 2)
        @test nrow(p) == 2
        # earlier era's end is pulled back to the later era's start
        @test p.event_end_date[1] == Date(2016, 3, 20)
        @test p.event_start_date[2] == Date(2016, 3, 20)
        @test p.event_end_date[2] == Date(2016, 7, 1)     # later era end untouched
    end

    @testset "subject 3 - FRFS combination" begin
        p = prows(result, 3)
        @test nrow(p) == 2
        @test p.event_start_date == [Date(2017, 1, 1), Date(2017, 3, 1)]
        @test p.event_end_date[1] == Date(2017, 6, 1)          # A unchanged
        @test p.event_end_date[2] == Date(2017, 6, 1)          # B pulled back to A's end
        @test p.SELECTED_ROWS[2] == 1
    end

    @testset "subject 4 - LRFS combination" begin
        p = prows(result, 4)
        @test nrow(p) == 2
        @test p.event_end_date[1] == Date(2018, 12, 1)         # A unchanged
        @test p.event_end_date[2] == Date(2018, 12, 1)         # B extended to A's end
        @test p.SELECTED_ROWS[2] == 1
    end

    @testset "subject 5 - minPostCombinationDuration drops the short fragment" begin
        p = prows(result, 5)
        @test nrow(p) == 1
        @test p.event_cohort_id == [EVENT_A]
        @test p.event_start_date == [Date(2019, 1, 1)]
        @test p.event_end_date == [Date(2019, 2, 5)]           # switched, 35 days -> kept
    end

    @testset "subject 6 - eraCollapseSize keeps / drops same-treatment eras" begin
        # 10 day gap, generous collapse size -> both eras kept
        @test nrow(prows(result, 6)) == 2

        tight = execute_treatments(sqlite_conn, TARGET, [EVENT_A, EVENT_B];
            min_era_duration = 5, era_collapse_size = 5,
            combination_window = Day(30), min_post_combination_duration = 1)
        @test nrow(prows(tight, 6)) == 1                       # 10 day gap > 5 -> dropped

        # per-treatment grouping: a gap between *different* treatments must not
        # drop the later treatment
        moderate = execute_treatments(sqlite_conn, TARGET, [EVENT_A, EVENT_B];
            min_era_duration = 5, era_collapse_size = 30,
            combination_window = Day(30), min_post_combination_duration = 30)
        @test nrow(prows(moderate, 1)) == 2
    end

    @testset "include_treatments = endDate" begin
        by_end = execute_treatments(sqlite_conn, TARGET, [EVENT_A, EVENT_B];
            min_era_duration = 5, era_collapse_size = 100_000,
            period_prior = Day(365), combination_window = Day(30),
            min_post_combination_duration = 30, include_treatments = "endDate")
        @test names(by_end) == names(result)
        # every event era ends inside the observation window here, so the same
        # subjects appear as in the startDate run
        @test Set(by_end.person_id) == Set(result.person_id)
    end

    @testset "everything filtered -> well-formed empty frame" begin
        expected_names = ["person_id", "event_start_date", "event_end_date",
                          "event_cohort_id", "GAP_PREVIOUS", "SELECTED_ROWS"]

        # emptied by minEraDuration
        e1 = execute_treatments(sqlite_conn, TARGET, [EVENT_A, EVENT_B]; min_era_duration = 10_000_000)
        @test nrow(e1) == 0
        @test names(e1) == expected_names

        # emptied by minPostCombinationDuration
        e2 = execute_treatments(sqlite_conn, TARGET, [EVENT_A, EVENT_B];
            min_era_duration = 5, era_collapse_size = 100_000,
            min_post_combination_duration = 10_000_000)
        @test nrow(e2) == 0
        @test names(e2) == expected_names
    end

    @testset "no target/event subjects in common -> empty" begin
        # cohort 93 exists nowhere as a target member
        DBI.execute(sqlite_conn, "INSERT INTO cohort (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date) VALUES (93, 999, '2016-01-01', '2016-06-01')")
        out = execute_treatments(sqlite_conn, TARGET, [93])
        @test nrow(out) == 0
    end

    # tidy up so local re-runs against the persistent Eunomia file stay clean
    DBI.execute(sqlite_conn, "DELETE FROM cohort WHERE cohort_definition_id IN ($TARGET, $EVENT_A, $EVENT_B, 93)")
end
