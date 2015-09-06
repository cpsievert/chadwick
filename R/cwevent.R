#' Extract detailed information about individual events.
#'
#' @references \url{http://chadwick.sourceforge.net/doc/cwevent.html}
#'
#' @param year The year to obtain event information
#' @importFrom dplyr left_join
#' @examples
#'
#' # acquire event data from 1960
#' df <- cwevent(1960)
#'
#' # tack on batter's name
#' data(players, package = "chadwick")
#' library(dplyr)
#' p <- players %>%
#'   rename(BAT_ID = Player.ID, BAT_TEAM_ID = Team) %>%
#'   mutate(Batter.Name = paste(First.Name, Last.Name)) %>%
#'   select(Year, BAT_TEAM_ID, BAT_ID, Batter.Name)
#' df2 <- left_join(df, p)
#'
#' # who had the most strikeouts in 1960?
#' df2 %>%
#'   filter(EVENT_DES == "Strikeout") %>%
#'   count(Batter.Name) %>%
#'   arrange(desc(n))
#'

cwevent <- function(year) {
  if (identical(Sys.which("cwevent"), "")) {
    stop("Please download and install the chadwick utility:\n",
         "http://chadwick.sourceforge.net/doc/index.html")
  }
  # do everything in a temporary directory
  owd <- getwd()
  on.exit(setwd(owd))
  tmp <- tempdir()
  setwd(tmp)

  # obtain the scripts for a particular year
  zipfile <- paste0(year, "eve.zip")
  download.file(
    url = sprintf("http://www.retrosheet.org/events/%seve.zip", year),
    zipfile
  )
  unzip(zipfile)

  # run the scripts
  # TODO: provide the option to grab the extended fields??
  argz <- c("-y", year, "-f", "0-96", "-x", "0-62",
            paste0(year, "*.EV*"))
  te <- system2("cwevent", args = argz, stdout = TRUE)
  df <- read.csv(
    text = paste(te, collapse = "\n"),
    header = FALSE,
    stringsAsFactors = FALSE
  )
  # add proper field names and an event descriptor
  e <- environment()
  data(fields, package = "chadwick", envir = e)
  data(event_codes, package = "chadwick", envir = e)
  nms <- c(fields$standard$Header, fields$extended$Header)
  df <- setNames(df, nms)
  df <- cbind(df, Year = as.integer(year))
  dplyr::left_join(df, event_codes, by = "EVENT_CD")
}
