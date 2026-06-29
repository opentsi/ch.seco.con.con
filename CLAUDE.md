# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```r
# Install dependencies
pak::pkg_install("opentsi/opentimeseries")

# Document (regenerate NAMESPACE and Rd files)
devtools::document()

# Install the package locally
devtools::install()

# Validate metadata
deloRean::validate_metadata()
```

## Architecture

This package follows the OpenTSI archive pattern:

- **`R/handle_update.R`** — Entry point called by CI. Calls `generate_checksum_input()` to detect whether new data is available, then calls `process_data()` and stores the new checksum via `opentimeseries::update_checksum()`.
- **`R/process_data.R`** — Stub: downloads data from the original provider, writes it to `series.csv` format using `opentimeseries::key_to_path`, and updates the catalog.
- **`data-raw/metadata.yaml`** — Dataset metadata in the OpenTSI schema. Key pattern: `country.provider.dataset.dimension.variable.unit`. The `update_checksum` field at the bottom is managed programmatically.
- **`inst/boilerplate.R`** — Reference script for one-time archive initialization and bulk history import using `deloRean::archive_init()`, `deloRean::create_vintage_dt()`, and `deloRean::archive_import_history()`.

### Update Flow

```
handle_update()
  └── generate_checksum_input()   # user-defined: returns publication date or single series
  └── is_update_needed()          # opentimeseries: compares against stored checksum
  └── update_checksum()           # opentimeseries: writes new checksum to metadata.yaml
  └── process_data()              # user-defined: fetch → csv → catalog update
```

### CI

`.github/workflows/update_data.yaml` runs `handle_update()` on a schedule (`0 10 1,5,15 * *`) and on manual dispatch, then commits any changed data files back to the repo.

## Implementation Status

Both `generate_checksum_input()` and `process_data()` are empty stubs that must be implemented before the package is functional. The `boilerplate.R` script shows the patterns used for the one-time history import (already completed for this archive).


## To Dos
i want you to create this data repository, based on the intial boilerplate given,

and based on other existing data packages of this form given. For this, look at the following remote packages:

- https://github.com/opentsi/ch.kof.barometer
- https://github.com/opentsi/ch.fso.besta.vacancies
- https://github.com/opentsi/ch.kof.globalbaro


the only thing that's different here is that unlike the other repositories (see `boilerplate.R` in those packages) here we don't have the vintages already, but we need to create them ourselves. meaning, we need to create the first vintage today, and in `handle_update.R` and `process_data.R` make sure that you are able to detect whether a new version is created. 

As a template for the `boilerplate.R` and `process_date.R` use this:

https://dataseries.org/d/ch_seco_concon?dims=type%3Dindex%3Bstructure%3Dks_i63_index_q%3Bseas_adj%3Dcsa

https://github.com/cynkra/dataseries-data/blob/main/datasets/ch_seco_concon.md

and https://github.com/cynkra/dataseries-data to fetch the data.