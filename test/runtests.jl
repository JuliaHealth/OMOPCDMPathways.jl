using OMOPCDMPathways
using DataFrames
using Dates
using FunSQL:
	From,
	Fun,
	Get,
	Where,
	Group,
	Limit,
	Select,
	render, 
	Agg,
	LeftJoin
using HealthSampleData
using OMOPCDMCohortCreator
using SQLite
using Test
using TimeZones

using JSON3
using OHDSICohortExpressions: translate, Model

import DBInterface as DBI

# For allowing HealthSampleData to always download sample data
ENV["DATADEPS_ALWAYS_ACCEPT"] = true

# SQLite Data Source
sqlite_conn = SQLite.DB(Eunomia())
GenerateDatabaseDetails(:sqlite, "main")
GenerateTables(sqlite_conn)

@testset "OMOPCDMPathways" begin
	@testset "Data-Preprocessing" begin
		include("Data-Preprocessing/preprocessing.jl")
	end
end

