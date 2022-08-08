#### WHOLIS ####

#site: http://apps.who.int/trialsearch/  


## Manual Input ##
terms <- c("YOUR", "TERMS")
path <- "YOUR/PATH"


## Docker Setup ##
source(paste0(path, "0 - Docker Setup.R"))


## WHOLis Crawler ##


#Searching terms and fetching articles' hyperlinks
wholis_links <- list()

for(i in terms){
  remDr$navigate('http://apps.who.int/trialsearch/')
  search_box = remDr$findElement(using = 'xpath','//*[@id="TextBox1"]')
  search_box$clickElement()
  search_box$sendKeysToElement(list(i))
  search_box$sendKeysToActiveElement(list(key = "enter"))
  
  wholis_links[[i]] = read_html(remDr$getPageSource()[[1]]) %>%
    html_nodes('a') %>%
    html_attr('href') %>%
    enframe(name = NULL) %>%
    na.omit() %>%
    filter(grepl('TrialID=', value)) %>%
    mutate(value = paste0('http://apps.who.int/trialsearch/', value)) 
}


wholis_links <- wholis_links %>%
  reduce(bind_rows) %>%
  na.omit() %>%
  unique()


#Getting articles' titles and abstracts
wholis_articles <- wholis_links %>%
  group_by(value) %>%
  nest() %>%  
  mutate(
    title = map_chr(value, ~{
      read_html(.x) %>%
        html_nodes(xpath = '//*[@id="DataList3_ctl01_Scientific_titleLabel"]') %>%
        html_text()
    })) %>%
  mutate(
    abstract = map_chr(value, ~{
      read_html(.x) %>%
        html_nodes(xpath = '//*[@id="DataList12"]') %>% 
        html_text() %>%
        reduce(bind_rows)
    })) %>%
  unnest() %>%
  ungroup() 


#Tidying our data
wholis_articles <- wholis_articles %>%
  mutate(journal = 'WHOLIS',
         terms = paste(terms, collapse = ' '),
         across(everything(),~gsub("\n|\t|\r|[ ]{2,}"," ",.)),
         across(everything(),~gsub(" {3,}","",.)),
         across(everything(),~gsub("^ ","",.)),
         across(everything(),~gsub(" $","",.))
  )

## Saving File ##
write_csv(wholis_articles,'articles_wholis_experiment.csv')  


#End of File