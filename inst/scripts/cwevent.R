library(rvest)
tabs <- html("http://chadwick.sourceforge.net/doc/cwevent.html") %>%
  html_nodes("table") %>% lapply(html_table)
fields <- setNames(tabs[1:2], c("standard", "extended"))
devtools::use_data(fields, overwrite = TRUE)
event_codes <- setNames(
  tabs[[3]],
  c("EVENT_CD", "EVENT_DES")
)
devtools::use_data(event_codes, overwrite = TRUE)


# Obtain all the players!
tmp <- tempdir()
for (i in 1920:2014) {
  # obtain the scripts for a particular year
  zipfile <- file.path(tmp, paste0(i, "eve.zip"))
  try({
    download.file(
      url = sprintf("http://www.retrosheet.org/events/%seve.zip", i),
      zipfile
    )
    unzip(zipfile, exdir = tmp)
  })
}

ros <- dir(path = tmp, pattern = "*.ROS", full.names = TRUE)
read_csv <- function(x){
  df <- read.csv(x, header = FALSE, stringsAsFactors = FALSE)
  yr <- as.integer(gsub("[A-Z]", "", basename(x)))
  cbind(df, yr)
}
df <- plyr::ldply(ros, read_csv)
nms <- c("Player.ID", "Last.Name", "First.Name",
         "Bats", "Pitches", "Team", "Position", "Year")
players <- setNames(df, nms)

players <- players[!duplicated(players),]

devtools::use_data(players, overwrite = TRUE)

