# Claude Code Instructions for okschooldata

## Commit and PR Guidelines

- Do NOT include “Generated with Claude Code” in commit messages
- Do NOT include “Co-Authored-By: Claude” in commit messages
- Do NOT mention Claude or AI assistance in PR descriptions
- Keep commit messages clean and professional

## Project Context

This is an R package for fetching and processing Oklahoma school data
from the Oklahoma State Department of Education (OSDE).

### Key Data Characteristics

- **Data Source**: Oklahoma State Department of Education (OSDE) at
  <https://sde.ok.gov>
- **ID System**:
  - District IDs: 6 characters (County code + Type + Number, e.g.,
    55I001)
  - Site IDs: 9 characters (District ID + Site number, e.g., 55I001001)
- **Primary Data System**: OSDE Public Records, Excel files
- **Number of Districts**: ~540
- **Number of Sites/Schools**: ~1,800+

### Oklahoma County Codes (Selected)

- 55: Oklahoma County (includes Oklahoma City)
- 72: Tulsa County
- 14: Cleveland County (includes Norman)
- 09: Canadian County (includes Mustang)
- 20: Comanche County (includes Lawton)

### District Type Codes

- I: Independent school district
- D: Dependent school district
- C: City school district
- E: Elementary school district

## Package Structure

The package follows the same patterns as txschooldata: -
`fetch_enrollment.R` - Main user-facing function -
`get_raw_enrollment.R` - Download raw data from OSDE -
`process_enrollment.R` - Process raw data into standard schema -
`tidy_enrollment.R` - Transform to long format - `cache.R` - Local
caching functions

## Data Source URLs

Primary data source (oklahoma.gov): - Base URL:
`https://oklahoma.gov/content/dam/ok/en/osde/documents/services/student-information/state-public-enrollment-totals/` -
State Enrollment Totals Page:
<https://oklahoma.gov/education/services/student-information/state-public-enrollment-totals.html>

### Data Eras

**Legacy Era (2016-2021)**: Files use FY naming pattern - District:
`GG_ByDIST_2F_GradeTots-FY{YY-YY}_...xls` - Site:
`GG_BySITE_2F_GradeTots-FY{YY-YY}-...xls`

**Modern Era (2022-2025)**: Files use SY naming or dated format -
District: `District%20Enrollment%20SY{YEAR}.xlsx` or
`03_DistrictEnrollment_{date}_final.xlsx` - Site:
`School%20Totals%20SY{YEAR}...xlsx` or
`01_SchoolSiteTotals_{date}_final.xlsx`

Supplementary data: - OklaSchools.com Data Matrix:
<https://oklaschools.com/state/matrix/> - OEQA Profiles:
<https://www.schoolreportcard.org/>

## Known Issues

1.  OSDE website (sde.ok.gov) can be slow or unresponsive - prefer
    oklahoma.gov URLs
2.  SSL certificate issues may occur with sde.ok.gov - oklahoma.gov is
    more reliable
3.  Column names vary between years - use flexible column mapping
4.  File naming patterns changed between eras - URL builder handles this
    automatically
5.  Some years (2018, 2020) use comparison files instead of standard
    grade totals files
