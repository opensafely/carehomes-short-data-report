
# Import functions

from cohortextractor import (
    StudyDefinition,
    patients,
    codelist_from_csv,
    codelist,
    filter_codes_by_category,
    combine_codelists,
)


# Import codelists

from codelists import *


# Specifiy study defeinition

study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "exponential_increase",
    },
    # This line defines the study population
    population= population=patients.satisfying(
        """
        tpp_care_home_type != "U"
        OR
        nhse_care_home_des=1

        """
    ),

    # CAREHOME STATUS

    #tpp
    tpp_care_home_type=patients.care_home_status_as_of(
        "2020-12-07",
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

    #nhse specified codes

        nhse_care_home_des=patients.with_these_clinical_events(
        nhse_care_home_des_codes,
        returning="binary_flag",
        return_expectations={"incidence": 0.1},
    ),
#age groups
 age=patients.age_as_of(
        "2020-12-07",  # day before vaccine campaign start
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),

    ageband_broad=patients.categorised_as(
        {
            "0": "DEFAULT",
            "0-19": """ age >= 0 AND age < 20""",
            "20-29": """ age >= 20 AND age < 30""",
            "30-39": """ age >= 30 AND age < 40""",
            "40-49": """ age >= 40 AND age < 50""",
            "50-59": """ age >= 50 AND age < 60""",
            "60-69": """ age >= 60 AND age < 70""",
            "70-79": """ age >= 70 AND age < 80""",
            "80+": """ age >=  80 AND age < 120""",  
        },
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0-19": 0.125,
                    "20-29": 0.125,
                    "30-39": 0.125,
                    "40-49": 0.125,
                    "50-59": 0.125,
                    "60-69": 0.125,
                    "70-79": 0.125,
                    "80+": 0.125,
                }
            },
        },
    ),

ageband_narrow = patients.categorised_as(
        {   
            "0": "DEFAULT",
            "0-19": """ age >= 0 AND age < 20""",
            "20-65": """ age >=  20 AND age < 65""",
            "65+": """ age >=  65 AND age < 120""",
        },
        return_expectations={
            "rate":"universal",
            "category": {"ratios": {"0-19": 0.2, "20-65": 0.1, "65+":0.7}}
        },
    ),

    
    # https://github.com/opensafely/risk-factors-research/issues/46
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    
    # https://codelists.opensafely.org/codelist/opensafely/chronic-cardiac-disease/2020-04-08/
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={"incidence": 0.2},
    ),

    # https://codelists.opensafely.org/codelist/opensafely/chronic-liver-disease/2020-06-02/
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),

    # https://github.com/opensafely/risk-factors-research/issues/51
    bmi=patients.most_recent_bmi(
        on_or_after="2010-02-01",
        minimum_age_at_measurement=16,
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "incidence": 0.6,
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
        },
    ),

    # https://github.com/opensafely/risk-factors-research/issues/48
    bp_sys=patients.mean_recorded_value(
        systolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="2020-02-01",
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "incidence": 0.6,
            "float": {"distribution": "normal", "mean": 80, "stddev": 10},
        },
    ),
    
    # https://github.com/opensafely/risk-factors-research/issues/48
    bp_dias=patients.mean_recorded_value(
        diastolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="2020-02-01",
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "incidence": 0.6,
            "float": {"distribution": "normal", "mean": 120, "stddev": 10},
        },
    ),

    # https://github.com/opensafely/risk-factors-research/issues/44
    stp=patients.registered_practice_as_of(
        "2020-02-01",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"STP1": 0.5, "STP2": 0.5}},
        },
    ),
    
    # https://github.com/opensafely/risk-factors-research/issues/44
    msoa=patients.registered_practice_as_of(
        "2020-02-01",
        returning="msoa_code",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"MSOA1": 0.5, "MSOA2": 0.5}},
        },
    ),

    # https://github.com/opensafely/risk-factors-research/issues/45
    imd=patients.address_as_of(
        "2020-02-01",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ),

    # https://github.com/opensafely/risk-factors-research/issues/47
    rural_urban=patients.address_as_of(
        "2020-02-01",
        returning="rural_urban_classification",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"rural": 0.1, "urban": 0.9}},
        },
    ),
 
    # https://codelists.opensafely.org/codelist/opensafely/asthma-inhaler-salbutamol-medication/2020-04-15/
    recent_salbutamol_count=patients.with_these_medications(
        salbutamol_codes,
        between=["2018-02-01", "2020-02-01"],
        returning="number_of_matches_in_period",
        return_expectations={
            "incidence": 0.6,
            "int": {"distribution": "normal", "mean": 8, "stddev": 2},
        },
    ),
)
