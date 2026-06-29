#' Handle Data Update
#'
#' Orchestrates the update process: checks if new SECO data is available,
#' fetches and writes it, and stores the new checksum.
#'
#' @importFrom opentimeseries is_update_needed update_checksum
#' @importFrom digest digest
#' @export
handle_update <- function() {

  checksum_input <- generate_checksum_input()

  if (!is_update_needed(checksum_input)) {
    message("No update needed, series up-to-date.")
    return(invisible(NULL))
  }

  new_hash <- digest(checksum_input, algo = "sha256")
  upd <- update_checksum(new_hash)
  if (upd) {
    process_data()
  } else {
    message("Checksum initialized. Data untouched.")
  }
  message("Update complete, checksum stored.")
}


#' Generate Checksum Input from SECO Endpoint
#'
#' Fetches the headline consumer sentiment series from the SECO swissdata
#' endpoint. The returned data frame changes whenever SECO publishes new
#' quarterly data, making it a reliable staleness indicator.
generate_checksum_input <- function() {
  data_url <- "https://scheduler.swissdatas.ch/scheduled/ks-q.csv"
  csv_data <- read.csv(url(data_url))
  # select one subseries to test
  csv_data[
    csv_data$structure == "ks_i63_index_q" &
    csv_data$type == "index" &
    csv_data$seas_adj == "na",
    c("date", "value")
  ]
}
