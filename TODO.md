# TODO

## pkgdown Build Issues

### Vignette Build Failure (2026-01-01)

The pkgdown site build fails when rendering
`vignettes/enrollment_hooks.Rmd` due to connection timeouts when
downloading enrollment data from oklahoma.gov.

**Error:**

    Failed to download District data for year 2016
    Error: Timeout was reached [oklahoma.gov]:
    Connection timed out after 10002 milliseconds
    URL attempted: https://oklahoma.gov/content/dam/ok/en/osde/documents/services/student-information/state-public-enrollment-totals/GG_ByDIST_2F_GradeTots-FY15-16_2015-12-18.xls

**Root Cause:** - The vignette calls `fetch_enr_multi(2016:2025)` which
attempts to download enrollment data for all years - The oklahoma.gov
server is timing out when downloading older years (2016-2019) - Cache
only contains data for 2020-2025

**Possible Solutions:**

1.  **Pre-populate cache**: Run `fetch_enr_multi(2016:2019)` locally
    when the server is responsive and commit cached data
2.  **Reduce year range**: Modify vignette to use only cached years
    (2020-2025)
3.  **Use eval=FALSE**: Make vignette code non-executable and include
    pre-rendered output
4.  **Increase timeout**: Modify download functions to use longer
    timeout values
5.  **Add retry logic**: Implement retry mechanism with exponential
    backoff

**Workaround:** The vignette could be modified to use years 2020-2025
instead of 2016-2025, which would use cached data and avoid the timeout
issues. This would require updating chart titles and year references
throughout the vignette.
