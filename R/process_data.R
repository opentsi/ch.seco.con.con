#' Process SECO Consumer Confidence Data
#'
#' Fetches all time series from the SECO swissdata quarterly consumer sentiment
#' endpoint and writes each (type, structure, seas_adj) combination to its
#' series CSV in \code{data-raw/csv/}.
#'
#' Keys follow \code{ch.seco.con.con.<type>.<structure>.<seas_adj>}.
#'
#' @return Invisibly returns a character vector of output file paths.
#' @export
process_data <- function() {
  data_url <- "https://scheduler.swissdatas.ch/scheduled/ks-q.csv"
  csv_data <- read.csv(url(data_url))
  csv_data$date <- as.Date(csv_data$date)

  combos <- unique(csv_data[, c("type", "structure", "seas_adj")])

  out_paths <- lapply(seq_len(nrow(combos)), function(i) {
    type_val  <- combos$type[i]
    struct_val <- combos$structure[i]
    seas_val  <- combos$seas_adj[i]

    subset <- csv_data[
      csv_data$type == type_val &
      csv_data$structure == struct_val &
      csv_data$seas_adj == seas_val, ]
    subset <- subset[order(subset$date), ]

    ts_df <- data.frame(time = subset$date, value = subset$value)
    key_suffix <- paste(type_val, struct_val, seas_val, sep = ".")
    output_path <- file.path("data-raw", "csv", paste0(key_suffix, ".csv"))

    write.csv(ts_df, file = output_path, row.names = FALSE, quote = FALSE)
    message(sprintf("Written: %s", output_path))
    output_path
  })

  invisible(unlist(out_paths))
}
