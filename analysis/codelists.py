from cohortextractor import (
    codelist,
    codelist_from_csv,
)


ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)

dementia_codes = codelist_from_csv(
    "codelists/opensafely-dementia.csv", 
    system="ctv3", 
    column="CTV3ID"
)

chronic_respiratory_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-respiratory-disease.csv", 
    system="ctv3",
    column="CTV3ID",
)

chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv",
    system="ctv3",
    column="CTV3ID",
)

diabetes_codes = codelist_from_csv(
    "codelists/opensafely-diabetes.csv", 
    system="ctv3", 
    column="CTV3ID",
)

lung_cancer_codes = codelist_from_csv(
    "codelists/opensafely-lung-cancer.csv", 
    system="ctv3", 
    column="CTV3ID",
)

haem_cancer_codes = codelist_from_csv(
    "codelists/opensafely-haematological-cancer.csv", 
    system="ctv3", 
    column="CTV3ID",
)

other_cancer_codes = codelist_from_csv(
    "codelists/opensafely-cancer-excluding-lung-and-haematological.csv",
    system="ctv3",
    column="CTV3ID",
)

chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", 
    system="ctv3", 
    column="CTV3ID"
)

nhse_care_home_des_codes = codelist_from_csv(
    "codelists/opensafely-nhs-england-care-homes-residential-status-ctv3.csv", 
    system="ctv3", 
    column="term"
)

stroke_codes = codelist_from_csv(
    "codelists/opensafely-stroke-updated.csv", 
    system="ctv3", 
    column="CTV3ID"
)