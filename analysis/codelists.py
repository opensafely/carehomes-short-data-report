from cohortextractor import (
    codelist,
    codelist_from_csv,
)

nhse_care_home_des_codes = codelist_from_csv(
    "codelists/opensafely-nhs-england-care-homes-residential-status-ctv3.csv",
    system="ctv3",
    column="code",
)


ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)
ethnicity_codes_16 = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_16",
)
