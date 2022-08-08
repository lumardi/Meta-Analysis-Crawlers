#### Clinical Trials Crawler ####

#site: https://clinicaltrials.gov/


## Manual Input ##
terms <- c("YOUR", "TERMS")
path <- "YOUR/PATH"


## Docker Setup ##
source(paste0(path, "0 - Docker Setup.R"))


## Clinical Trials Crawler ##


#Getting links
clinical_trials_links = list()

for(i in terms){
  remDr$navigate('https://clinicaltrials.gov/')
  search_box = remDr$findElement(using = 'xpath','//*[@id="home-search-other-query"]')
  search_box$clickElement()
  search_box$sendKeysToElement(list(i))
  search_box$sendKeysToActiveElement(list(key = "enter"))
  
  safely(~{
    items_page = remDr$findElement(using = 'xpath', '//*[@id="tab-body"]/div[1]/div')
    items_page$clickElement()
    items_page$sendKeysToElement(list('1'))
    items_page$sendKeysToActiveElement(list(key = "enter"))
    any_element = remDr$findElement(using = 'xpath', '//*[@id="theDataTable"]')
    any_element$clickElement()
  })
  
  clinical_trials_links[[i]] <- read_html(remDr$getPageSource()[[1]]) %>%
    html_nodes('a') %>%
    html_attr('href') %>%
    enframe(name = NULL) %>%
    na.omit() %>%
    filter(grepl('&rank=', value)) %>%
    mutate(value = paste0('https://clinicaltrials.gov', value)) 
  
}

clinical_trials_links <- clinical_trials_links %>%
  reduce(bind_rows) %>%
  na.omit() %>%
  unique()


#Getting titles and abstracts
clinical_trials_articles <- clinical_trials_links %>%
  group_by(value) %>%
  nest() %>%  
  mutate(
    title = map_chr(value, ~{
      read_html(.x) %>%
        html_nodes(xpath = '//*[@id="main-content"]/div[1]/h1') %>%
        html_text()
    })) %>%
  mutate(
    abstract = map_chr(value, ~{
      read_html(.x) %>%
        html_nodes(xpath = '//*[@id="tab-body"]/div/div[1]/div[2]') %>%
        html_text()
    })) %>%
  unnest() %>%
  ungroup()

#Tidying our data
clinical_trials_articles <- clinical_trials_articles %>%
  mutate(journal = 'CLINICAL TRIALS',
         terms = paste(terms, collapse = ' '),
         across(everything(),~gsub("\n|\t|\r|[ ]{2,}"," ",.)),
         across(everything(),~gsub(" {3,}","",.)),
         across(everything(),~gsub("^ ","",.)),
         across(everything(),~gsub(" $","",.))
  )



## Saving File ##
write_csv(clinical_trials_articles,'articles_clinical_trials_experiments.csv')

#End of File