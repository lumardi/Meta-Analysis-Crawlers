#### Google Scholar Crawler ####


## Manual Input ##
term <- c("YOUR", "TERMS")
path <- "YOUR/PATH"


## Docker Setup ##
source(paste0(path, "0 - Docker Setup.R"))


## Google Scholar Crawler ##

# Function to retrieve hyperlinks
link <- function(list, element){
  aux = html_attr(html_nodes(xml_child(list[[element]], 1),"a"),"href")
  if(length(aux) == 0){
    NA_character_
  } else{
    return(aux)
  }
}


# Navigating Page
remDr$navigate(paste0("https://scholar.google.com/scholar?hl=en&q=", term))

# Finding number of results
results <- read_html(remDr$getPageSource()[[1]]) %>%
  html_nodes(xpath = '//*[(@id = "gs_ab_md")]//*[contains(concat( " ", @class, " " ), concat( " ", "gs_ab_mdw", " " ))]') %>%
  html_text() %>%
  gsub("\\(.*","",.) %>%
  gsub("[^0-9]","",.) %>%
  as.numeric(.)/10 %>%
  round(digits = 0) + 1

# Scraping Scholar
raw <- list()

for (j in 1:results) {
  Sys.sleep(rpois(1, 3))
  # Getting articles basic information
  aux  = read_html(remDr$getPageSource()[[1]]) %>%
    html_nodes(xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "gs_ri", " " ))]') 
  # Cleaning Data
  raw_partial <- list()
  for(i in 1:10){
    raw_partial[[i]] = tibble(
      title =  html_text(html_node(aux[[i]],"h3.gs_rt")),
      author =  html_text(html_node(aux[[i]],"div.gs_a")),
      abstract = html_text(html_node(aux[[i]],"div.gs_rs")),
      cited_versions =  html_text(html_node(aux[[i]],"div.gs_fl")),
      link = link(aux, i),
      page = j)
    }
  # Turning into dataset
  raw_partial <- raw_partial %>%
    reduce(bind_rows)
  raw <- bind_rows(raw, raw_partial)
  # Changing Pages
  next_button <- try({remDr$findElement(using = 'class name','gs_ico_nav_next')}, silent = T)
  try({next_button$clickElement()}, silent = T)
}


## Saving File ##
write_csv(raw, paste0(path, term, "_raw.csv"))


#End of File