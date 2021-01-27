
from cohortextractor import (
    StudyDefinition,
    patients,
    codelist_from_csv,
    codelist,
    filter_codes_by_category,
    combine_codelists,
)


# Import all relevant code lists 

from codelists import *

# Specifiy study defeinition

study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1970-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.2,
    },

    # set an index date (as starting point)
    index_date="2020-02-01",

    # This line defines the study population that the below varaibles will be defined for 
    # currently registered patients restricts to those alive 
    # the age restriction is applied as current TPP linkage only includes linkages to old age care 
    population=patients.satisfying(
        """
        (age >= 65 AND age < 120) AND 
        is_registered_with_tpp  
        """,
        is_registered_with_tpp=patients.registered_as_of(
          "index_date"
        ),
    ),

    # TPP ADDRESS LINKAGE 
    # tpp defined care home as of date 
    tpp_care_home_type=patients.care_home_status_as_of(
        "index_date",
        categorised_as={
            "PC": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='Y'
              AND LocationRequiresNursing='N'
            """,
            "PN": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='N'
              AND LocationRequiresNursing='Y'
            """,
            "PS": "IsPotentialCareHome",
            "U": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"PC": 0.05, "PN": 0.05, "PS": 0.05, "U": 0.85,},},
        },
    ),

    # SNOMED AND CTV3 CODES (extracted over different time periods to sense check)
    # snomed ever
    snomed_carehome_ever=patients.with_these_clinical_events(
        nhse_care_home_des_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
    # snomed within past year 
    snomed_carehome_pastyear=patients.with_these_clinical_events(
        nhse_care_home_des_codes,
        between=["index_date - 1 year", "index_date"], 
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),

    # HOUSEHOLD RELATED VARIABLES 
    ## household ID  
    household_id=patients.household_as_of(
        "index_date",
        returning="pseudo_id",
        return_expectations={
            "int": {"distribution": "normal", "mean": 1000, "stddev": 200},
            "incidence": 1,
        },
    ),
    ## household size   
    household_size=patients.household_as_of(
        "index_date",
        returning="household_size",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        },
    ),
    # mixed household flag 
    tpp_household=patients.household_as_of(
        "index_date",
        returning="has_members_in_other_ehr_systems",
        return_expectations={ "incidence": 0.75
        },
    ),
    # mixed household percentage 
    tpp_coverage=patients.household_as_of(
        "index_date", 
        returning="percentage_of_members_with_data_in_this_backend", 
        return_expectations={
            "int": {"distribution": "normal", "mean": 75, "stddev": 10},
            "incidence": 1,
        },
    ),

    # AGE and AGE CATEGORIES (latter needed for comparison w. census only)
    # age 
    age=patients.age_as_of(
        "index_date",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    # age band 
    ageband_narrow = patients.categorised_as(
        {   
            "0": "DEFAULT",
            "65-74": """ age >=  65 AND age < 75""",
            "75-79": """ age >=  75 AND age < 80""",
            "80-84": """ age >=  80 AND age < 85""",
            "85-89": """ age >=  85 AND age < 120""",
        },
        return_expectations={
            "rate":"universal",
            "category": {"ratios": {"65-74": 0.4, "75-79": 0.2, "80-84":0.2, "85-89":0.2 }}
        },
    ),

    # SELECTED DEMOGRAPHIC CHARACTERISTICS TO DESCRIBE 
    # sex 
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    # self-reported ethnicity 
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=False,
        return_expectations={
            "category": {"ratios": {"1": 0.8, "5": 0.1, "3": 0.1}},
            "incidence": 0.75,
        },
    ),
    # grouped region of the practice
    region=patients.registered_practice_as_of(
        "index_date",
        returning="nuts1_region_name",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and the Humber": 0.1,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East of England": 0.1,
                    "London": 0.2,
                    "South East": 0.2,
                },
            },
        },
    ),
    # imd 
    imd=patients.address_as_of(
        "index_date",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ), 

    # SELECTED CLINICAL CHARACTERISTICS TO DESCRIBE 
    # diabetes
    diabetes=patients.with_these_clinical_events(
        diabetes_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.10},
    ),
    # chronic respiratory disease (excl asthma)
    chronic_respiratory_disease=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.20},
    ),
    # stroke
    stroke=patients.with_these_clinical_events(
        stroke_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.05},
    ),
    # chronic heart disease
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.35},
    ),
    # dementia
    dementia=patients.with_these_clinical_events(
        dementia_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.45},
    ),
    # cancer
    cancer=patients.satisfying(
        "lung_cancer OR haem_cancer OR other_cancer",
        lung_cancer=patients.with_these_clinical_events(
        lung_cancer_codes,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.10},
        ),
        haem_cancer=patients.with_these_clinical_events(
        haem_cancer_codes,
        on_or_before="index_date",
        return_expectations={"incidence": 0.05},
        ),
        other_cancer=patients.with_these_clinical_events(
        other_cancer_codes,
        on_or_before="index_date",
        return_expectations={"incidence": 0.10},
        ),

    ),


)