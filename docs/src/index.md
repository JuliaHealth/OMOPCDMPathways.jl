# Welcome to the `OMOPCDMPathways.jl` Docs! 👋

> Find the pathways patients take while receiving care!

This package allows one to extract the various pathways a patient could take while receiving treatments and care. 
It expects patient data to be formatted within a database that adheres to the [OMOP Common Data Model](https://www.ohdsi.org/data-standardization/the-common-data-model/). 

**Here's how to get started with the package**: 

- Visit the [Tutorials](https://github.com/JuliaHealth/OMOPCDMPathways.jl/blob/main/docs/src/tutorials.md) section to see how this package can be used.

- Check out the [API](https://github.com/JuliaHealth/OMOPCDMPathways.jl/blob/main/docs/src/api.md) section to see all the functions available. 

If you want to contribute, please check out our [Contributing](https://github.com/JuliaHealth/OMOPCDMPathways.jl/blob/main/docs/src/contributing.md) guide!

## Why Research Patient Pathways? 🤔

[Patient pathways outline](https://bmcpsychiatry.biomedcentral.com/articles/10.1186/s12888-019-2418-7) a patient’s care process, from initial contact to subsequent future patient and health provider interactions.
Understanding patient pathways is an active area of research within observational health studies as they give insight into combinations of drugs patients may be prescribed, duration of treatments, where care is received and overlaps with other treatment regimens patients may be receiving simultaneously.
This package provides a generalized methodology to interrogate patient care evolution in OMOP CDM database settings to further motivate the investigation of questions in health economics (such as costs of care), pharmacovigilance, access to care, and observational health research.
By analyzing these pathways, researchers can identify patterns, assess adherence to treatment, identify gaps in care, optimize resource allocation, and potentially improve patient outcomes and the quality of healthcare delivery.
