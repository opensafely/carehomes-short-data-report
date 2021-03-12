# Identifying Care Home Residents in Electronic Health Records - An OpenSAFELY Short Data Report

This is the code and configuration for our shot data report on the identification of care home residents within OpenSAFELY-TPP.
Our work has recently been submitted, and we will link to the pre-print as soon as this is available. 

* Raw model outputs, including crosstabs, etc, are in `released_outputs/analysis/outfiles`
* If you are interested in how we defined our variables, take a look at the [study definition](analysis/study_definition.py); this is written in `python`, but non-programmers should be able to understand what is going on there
* If you are interested in how we defined our code lists, look in the [codelists folder](./codelists/).
* Developers and epidemiologists interested in the framework should review [the OpenSAFELY documentation](https://docs.opensafely.org)

# About the OpenSAFELY framework

The OpenSAFELY framework is a secure analytics platform for
electronic health records research in the NHS.

Instead of requesting access for slices of patient data and
transporting them elsewhere for analysis, the framework supports
developing analytics against dummy data, and then running against the
real data *within the same infrastructure that the data is stored*.
Read more at [OpenSAFELY.org](https://opensafely.org).
