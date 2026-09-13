# API

This is a list of documentation associated with every single **exported** function from `OMOPCDMPathways`.
There are a few different sections with a brief explanation of what these sections are followed by relevant functions.


## Pre-Processing

This family of functions are dedicated to pre-process the Data.

```@docs
period_prior_to_index
calculate_era_duration
EraCollapse
create_treatment_history
combination_Window
minPostCombinationDuration_filter
```

## Pathway Synthesis

`execute_treatments` sews the pre-processing primitives above into a single
end-to-end pathway synthesis, following the OHDSI `TreatmentPatterns`
`constructPathways` pipeline.

```@docs
execute_treatments
query_cohorts_with_dates
```
