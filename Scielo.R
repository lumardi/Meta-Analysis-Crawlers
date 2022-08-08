#### SciELO Crawler ####


## Manual Input ##
term <- c("YOUR", "TERMS")
path <- "YOUR/PATH"


## Docker Setup ##
source(paste0(path, "0 - Docker Setup.R"))


## Scielo Crawler ##


# Navigating Page
remDr$navigate(paste0("https://search.scielo.org/?q=",
                      term,
                      "&lang=pt&count=50&from=0&output=site&sort=&format=summary&fb=&page=1&filter%5Bin%5D%5B%5D=scl"
                      ))


# Finding number of results
results <- read_html(remDr$getPageSource()[[1]]) %>%
  html_nodes(xpath = '//*[@id="ResultArea"]/div[1]/div[2]/text()[2]') %>%
  html_text() %>%
  gsub("[^0-9]","",.) %>%
  as.numeric(.) 

# Scraping Scielo

raw <- 1:results %>%
  map_dfr(~{
    link = read_html(remDr$getPageSource()[[1]]) 
    
    abstract = tibble(
      id = link %>%
        html_nodes(xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "abstract", " " ))]') %>%
        xml_attr("id") ,
      abstract = link %>%
        html_nodes(xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "abstract", " " ))]') %>%
        html_text2()) %>%
      na.omit() %>%
      separate(id, c("id","lang"), sep = "-scl_") %>%
      pivot_wider(names_from = lang, values_from = abstract, names_prefix = "abstract_")
      
    
    dat =  tibble(
      title = link %>%
        html_nodes(xpath = '//*[(@id = "ResultArea")]//*[contains(concat( " ", @class, " " ), concat( " ", "title", " " ))]') %>%
        html_text2(),
      author = link %>%
        html_nodes(xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "authors", " " ))]') %>%
        html_text2(),
      source = link %>%
        html_nodes(xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "source", " " ))]') %>%
        html_text2(),
      metadata = link %>%
        html_nodes(xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "metadata", " " ))]') %>%
        html_text2()) %>%
      bind_cols(abstract)
    try({
      next_button <- remDr$findElement(using = 'class name','pageNext')
      next_button$clickElement()}, silent = T)
    
    return(dat)
  })



# Data Tidying
aux <- dat %>%
  mutate(across(everything(), ~gsub(" {2,}|\t","",.)),
         across(-c(source), ~gsub("\n","",.)),
         source = gsub("\n{1,}","\n", source)) 



## Saving File ##
write_csv(paste0(path, term, "_raw.csv"))



# End of File