module OMOPCDMPathways
  using DataFrames
  using Dates
  using DBInterface
  using FunSQL:
      SQLTable,
      Agg,
      As,
      Define,
      From,
      Fun,
      Get,
      Group,
      Join,
      Order,
      Select,
      WithExternal,
      Where,
      render,
      Limit,
      ID,
      LeftJoin,
      reflect
  using TimeZones


  using OMOPCDMCohortCreator

  function MakeTables(conn, dialect, schema)

      @eval global dialect = $(QuoteNode(dialect))
      GenerateDatabaseDetails(dialect, schema)
      db_info = GenerateTables(conn, inplace = false, exported = true)
      for key in keys(db_info)
          @eval global $(Symbol(lowercase(string(key)))) = $(db_info[key])
          @info "$(lowercase(string(key))) table generated internally"
      end

  end

  export MakeTables

end
