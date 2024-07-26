# Beginner Tutorial 🐣

This tutorial will guide you through the basics of using the OMOP CDM Pathways package. 
And will guide how one can build full Pathways followed by the patient.

The tutorial will cover the following topics:
1. [Installation & Environment Setup](#Installation-&-Environment-Setup)
2. [Packages](#Packages)
3. [Getting the Data Ready](#Getting-the-Data-Ready)
4. [Building Pathways](#Building-Pathways)
5. [Visualizing Pathways](#Visualizing-Pathways)
6. [Pathway Analysis](#Pathway-Analysis)



## Environment Set-Up 📝

For this tutorial, you will need to activate an environment; to get into package mode within your Julia REPL, write `]`:

```julia-repl
pkg> activate TUTORIAL
```

### Packages 

You will need the following packages for this tutorial which you can install in package mode:

```julia-repl
TUTORIAL> add OMOPCDMPathways
TUTORIAL> add OMOPCDMCohortCreator
TUTORIAL> add SQLite
TUTORIAL> add DataFrames
TURORIAL> add HealthSampleData
```
To learn more about these packages, see the [Appendix](#appendix).


### Getting the Data Ready 

For this tutorial, we will work with data from [Eunomia](https://github.com/OHDSI/Eunomia) that is stored in a SQLite format.
To install the data on your machine, execute the following code block and follow the prompts - you will need a stable internet connection for the download to complete: 

```julia
import HealthSampleData: Eunomia

eunomia = Eunomia()
```


## Connecting to the Eunomia Database 💾

After you have finished your set up in the Julia, we need to establish a connection to the Eunomia SQLite database that we will use for the rest of the tutorial: 

```julia
import SQLite: DB

conn = DB(eunomia)
```

With Eunomia, the database's schema is simply called "main".
We will use this to generate database connection details that will inform `OMOPCDMCohortCreator` about the type of queries we will write (i.e. SQLite) and the name of the database's schema.
For this step, we will use `OMOPCDMCohortCreator`:

```julia
import OMOPCDMCohortCreator as occ

occ.GenerateDatabaseDetails(
    :sqlite,
    "main"
)
```

Finally, we will generate internal representations of each table found within Eunomia for OMOPCDMCohortCreator to use:

```julia
occ.GenerateTables(conn)
```

As a check to make sure everything was correctly installed and works properly, the following block should work and return a list of all person ids in this data:

```julia
occ.GetDatabasePersonIDs(conn)
```


## Building Pathways 🚀

The very first step is to do perform the Data-Preprocessing and then we can start building the Pathways.

(1)  The first pre-processing is to get the Data filtered cum sorted based on the index start date by a thresold of `periodPriorToIndex` days.

So, let's say we have the patient `cohort_id`:

```julia
cohort_id = [1, 1, 1, 1, 1]
```

Then to apply the Data-Preprocessing, we can do something like this:

```julia
date_prior = Day(100)
period_prior_to_index(cohort_id,  conn,   date_prior)
```

Given cohort_id's , this would return a DataFrame with the cohort_start_date adjusted to prior each subjects' cohort entry date.



(2) The next thing to consider is that in a medical setting, If an individual receives the same treatment for a longer period of time (e.g. need of chronic treatment), one is likely to need reﬁlls. As patients are not 100% adherent, there might be a gap between two subsequent event eras. Usually, these eras are still considered as one treatment episode and the eraCollapseSize deﬁnes the maximum gap within which two eras of the same event cohort would be collapsed into one era (i.e. seen as continuous treatment instead of a stop and re-initiation of the same treatment).

And this can be handeled by Collapsing treatment eras if the gap between them is smaller than a specific threshold.

This can be done using the `EraCollapse` function by doing something like this:

```julia
eraCollapseSize = Day(30)
EraCollapse(treatment_history, eraCollapseSize)
```

(3) Further, the issue we might see is that the duration of extracted event eras may vary a lot so it is preferable to limit to only treatments exceeding a minimum duration. Hence minEraDuration speciﬁes the minimum time an event era should last to be included in the analysis.

This can be done using the `calculate_era_duration` function by doing like this:

```julia
minEraDuration = Day(30)
calculate_era_duration(treatment_history, minEraDuration)
```
