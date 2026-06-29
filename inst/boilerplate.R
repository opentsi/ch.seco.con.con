## One-time archive initialisation script for ch.seco.con.con
##
## Unlike other OpenTSI archives, this dataset has no pre-existing vintage
## history from a time series database API. We fetch the current SECO
## swissdata CSV, treat the SECO publication date as the single initial
## vintage, and import it as the archive's first commit.
##
## Run this script section by section from the repo root.

library(deloRean)
library(opentimeseries)
library(tsbox)
library(data.table)
library(digest)

## ── Step 1: Fetch the SECO quarterly CSV ─────────────────────────────────────

data_url <- "https://scheduler.swissdatas.ch/scheduled/ks-q.csv"
csv_data <- read.csv(url(data_url))
csv_data$date <- as.Date(csv_data$date)

## ── Step 2: Build tsl with one vintage (SECO last publish date) ──────────────
##
## Naming convention expected by create_vintage_dt:
##   <type>.<structure>.<seas_adj>.<YYYY-MM>
## The function strips the trailing .<YYYY-MM> to recover the series id.

release_date   <- as.Date("2026-05-05")   # SECO source publish date (dataseries.org)
vintage_suffix <- format(release_date, "%Y-%m")

# how can you be sure the entire combinations exist, where is the list of keys?
combos <- unique(csv_data[, c("type", "structure", "seas_adj")])

tsl <- vector("list", nrow(combos))

for (i in seq_len(nrow(combos))) {
  type_val   <- combos$type[i]
  struct_val <- combos$structure[i]
  seas_val   <- combos$seas_adj[i]

  subset <- csv_data[
    csv_data$type      == type_val  &
    csv_data$structure == struct_val &
    csv_data$seas_adj  == seas_val, ]
  subset <- subset[order(subset$date), ]

  # Build quarterly ts object
  start_month   <- as.integer(format(subset$date[1], "%m"))
  start_year    <- as.integer(format(subset$date[1], "%Y"))
  start_quarter <- ceiling(start_month / 3)

  ts_obj <- ts(subset$value,
               start     = c(start_year, start_quarter),
               frequency = 4)

  key_suffix        <- paste(type_val, struct_val, seas_val, sep = ".")
  tsl[[i]]          <- ts_obj
  names(tsl)[i]     <- paste0(key_suffix, ".", vintage_suffix)
}

class(tsl) <- c(class(tsl), "tslist")

# One release date per series (all the same — single vintage)
vintage_dates <- rep(release_date, nrow(combos))

## ── Step 3: Create vintage data.table ────────────────────────────────────────

vintages_dt <- create_vintage_dt(vintage_dates, tsl)
head(vintages_dt)

## ── Step 4: Import history (writes CSVs + git commits) ───────────────────────

archive_import_history(vintages_dt, repository_path = ".")

## ── Step 5: Render and validate metadata ─────────────────────────────────────

render_metadata()
meta <- read_metadata(".")
validate_metadata(meta)   # should return TRUE

## ── Step 6: Seal the archive ─────────────────────────────────────────────────

devtools::load_all()
checksum_input <- generate_checksum_input()
archive_seal(checksum_input)

## ── Step 7: Final checks & automation ────────────────────────────────────────

devtools::load_all()
handle_update()   # should report "No update needed"

library(devtools)
check()
document()

## ── Step 8: Build README ─────────────────────────────────────────────────────
# Add an example tsplot to the last code chunk in README.Rmd, then:
build_readme()
