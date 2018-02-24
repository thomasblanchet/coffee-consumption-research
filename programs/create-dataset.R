library(rvest)
library(stringr)
library(tidyverse)
library(magrittr)
library(readxl)
library(stringdist)

# ---------------------------------------------------------------------------- #
# Retrieve the directory of economists registered on RePEc
# ---------------------------------------------------------------------------- #

repec_authors <- data.frame(id = character(0), name = character(0))

pb <- txtProgressBar(max = 26, style = 3)
i <- 1

for (l in letters) {
    repec_list <- read_html(paste0("https://ideas.repec.org/i/e", l, ".html"))
    repec_name <- repec_list %>%
        html_node(xpath = '//*[@id="content-block"]/table') %>%
        html_children() %>%
        html_children() %>%
        html_children() %>%
        html_text()
    repec_id <- repec_list %>%
        html_node(xpath = '//*[@id="content-block"]/table') %>%
        html_children() %>%
        html_children() %>%
        html_children() %>%
        html_attr("href")

    repec_authors <- rbind(repec_authors, tibble(
        id = str_match(repec_id, "/.*/(.*)\\.html")[, 2],
        name = repec_name
    ))

    i <- i + 1
    setTxtProgressBar(pb, i)
}

close(pb)

# ---------------------------------------------------------------------------- #
# Import the dataset on coffee consumption at PSE
# ---------------------------------------------------------------------------- #

pse_authors <- read_excel(file.path("data", "coffee-pse.xlsx"))

# ---------------------------------------------------------------------------- #
# Match the two datasets using a greedy fuzzy matching algorithm
# ---------------------------------------------------------------------------- #

d <- expand.grid(pse_name = pse_authors$name, repec_name = repec_authors$name)
d %<>% mutate(
    repec_first_name = str_split_fixed(as.character(repec_name), ",", 2)[, 1],
    repec_last_name = str_split_fixed(as.character(repec_name), ",", 2)[, 2],
    pse_first_name = str_split_fixed(as.character(pse_name), " ", 2)[, 1],
    pse_last_name = str_split_fixed(as.character(pse_name), " ", 2)[, 2]
)
d %<>% mutate(dist = pmin(
    stringdist(
        paste(repec_first_name, repec_last_name),
        paste(pse_first_name, pse_last_name),
        method = "jw"
    ),
    stringdist(
        paste(repec_first_name, repec_last_name),
        paste(pse_last_name, pse_first_name),
        method = "jw"
    )
))

greedy_assign <- function(a, b, d){
    src <- tibble(a = a, b = b, d = d)
    src %<>% arrange(d)

    n <- length(unique(a))
    dict <- tibble(
        a = rep(NA_character_, n),
        b = rep(NA_character_, n),
        d = rep(NA_real_, n)
    )

    pb <- txtProgressBar(max = n, style = 3)
    for (i in 1:n) {
        dict$a[i] <- src$a[1]
        dict$b[i] <- src$b[1]
        dict$d[i] <- src$d[1]

        src %<>% filter(a != a[1] & b != b[1])
        setTxtProgressBar(pb, i)
    }
    close(pb)
    return(dict)
}

author_dict <- greedy_assign(as.character(d$pse_name), as.character(d$repec_name), d$dist)

# Matches with a distance higher than 0.12 are not correctly matched
author_dict %<>% filter(d < 0.12) %>% rename(pse_name = a, repec_name = b, dist = d)

pse_authors %<>% rename(pse_name = name)
repec_authors %<>% rename(repec_name = name)

data <- author_dict %>% left_join(pse_authors) %>% left_join(repec_authors)

# When the same person appears twice in the PSE spreadsheet, we take the
# average coffee consumption.
data %<>% select(-pse_name) %>% group_by(repec_name, id) %>% summarise(
    coffee_cons = mean(consumption, na.rm = TRUE)
) %>% ungroup() %>% na.omit()

# ---------------------------------------------------------------------------- #
# Retrieve bibliometric data from CitEc
# ---------------------------------------------------------------------------- #

data %<>% mutate(
    h_index = NA_integer_,
    i10_index = NA_integer_,
    time_activity = NA_integer_
)

for (i in 1:nrow(data)) {
    l <- substr(data$id[i], 2, 2)
    url <- paste0("http://citec.repec.org/p/", l, "/", data$id[i], ".html")
    cat(paste0("--> ", url, "\n"))
    citec_profile <- read_html(paste0("http://citec.repec.org/p/", l, "/", data$id[i], ".html"))

    node <- citec_profile %>%
        html_nodes(xpath = '/html/body/div[2]/div[1]/div[2]/table[1]/tr/td[2]/*')
    to_parse <- ""
    for (child in node) {
        content <- child %>% html_text()
        if (str_detect(content, '([0-9]+)H index([0-9]+)i10 index([0-9]+)Citations')) {
            indices <- str_match(content, '([0-9]+)H index([0-9]+)i10 index([0-9]+)Citations')
            data$h_index[i] <- as.integer(indices[1, 2])
            data$i10_index[i] <- as.integer(indices[1, 3])
        }
        if (to_parse == "RESEARCH ACTIVITY:") {
            data$time_activity[i] <- as.integer(str_match(content, "([0-9]*?) years")[1, 2])
            to_parse <- ""
        }
        if (content == "RESEARCH ACTIVITY:") {
            to_parse <- "RESEARCH ACTIVITY:"
        }
    }
}

# ---------------------------------------------------------------------------- #
# Anonymize and export data
# ---------------------------------------------------------------------------- #

data %>%
    select(coffee_cons, h_index, i10_index, time_activity) %>%
    write_csv(file.path("data", "data-final.csv"))

