#### Cochrane Crawler ####

# site: https://www.cochranelibrary.com/cdsr/reviews


## Manual Input ##
terms <- c("YOUR", "TERMS")
path <- "YOUR/PATH"


## Docker Setup ##
source(paste0(path, "0 - Docker Setup.R"))


## Cochrane Crawler ##

links_cochrane = tibble(value = NA)


#Searching Reviews:

for(i in terms){
  remDr$navigate('https://www.cochranelibrary.com/cdsr/reviews')
  
  search_box = remDr$findElement(using = 'xpath','//*[@id="searchText"]')
  search_box$clickElement()
  search_box$doubleclick()
  search_box$sendKeysToActiveElement(list(key = "delete"))
  search_box$sendKeysToElement(list(i))
  search_box$sendKeysToActiveElement(list(key = "enter"))
  
  Sys.sleep(20)
  
  number_results_page = remDr$findElement(using = 'xpath', '//*[@id="searchArticleForm"]/div[4]/div[2]/div[2]/div/div')
  number_results_page$clickElement()
  Sys.sleep(20)
  
  number_results_page_100 = remDr$findElement(using = 'xpath', '//*[@id="searchArticleForm"]/div[4]/div[2]/div[2]/div/ul/li[4]')
  number_results_page_100$clickElement()
  
  links_cochrane_partial = remDr$getPageSource()[[1]] %>%
    map_df(~{
      .x %>%
        read_html() %>%
        html_nodes('a') %>%
        html_attr('href') %>%
        enframe(name = NULL)
    }) %>%
    filter(grepl('doi', value)) %>%
    unique() %>%
    mutate(value = paste0('https://www.cochranelibrary.com', value))
  
  links_cochrane = bind_rows(links_cochrane, links_cochrane_partial)
}



#Searching Trials:

for(i in terms){
  remDr$navigate('https://www.cochranelibrary.com/cdsr/reviews')
  
  search_box = remDr$findElement(using = 'xpath','//*[@id="searchText"]')
  search_box$clickElement()
  search_box$doubleclick()
  search_box$sendKeysToActiveElement(list(key = "delete"))
  search_box$sendKeysToElement(list(i))
  search_box$sendKeysToActiveElement(list(key = "enter"))
  
  Sys.sleep(20)
  
  box_trials = remDr$findElement(using = 'xpath', '//*[@id="column-2"]/div[1]/div[1]/ul/li[3]')
  box_trials$clickElement()
  
  Sys.sleep(20)
  
  number_results_page = remDr$findElement(using = 'xpath', '//*[@id="searchArticleForm"]/div[4]/div[2]/div[2]/div/div')
  number_results_page$clickElement()
  Sys.sleep(10)
  
  number_results_page_100 = remDr$findElement(using = 'xpath', '//*[@id="searchArticleForm"]/div[4]/div[2]/div[2]/div/ul/li[4]')
  number_results_page_100$clickElement()
  
  Sys.sleep(60)
  
  links_cochrane_partial = remDr$getPageSource()[[1]] %>%
    map_df(~{
      .x %>%
        read_html() %>%
        html_nodes('a') %>%
        html_attr('href') %>%
        enframe(name = NULL)
    }) %>%
    filter(grepl('doi', value)) %>%
    unique() %>%
    mutate(value = paste0('https://www.cochranelibrary.com', value))
  
  max_page = 2
  #changing page:
  for(j in 1:max_page){
    print(j)
    try({
      next_page = remDr$findElement(using = 'xpath', '//*[@id="column-2"]/div[2]/div/div[2]/a')
      next_page$clickElement()
    })
    
    links_cochrane_partial_sub = remDr$getPageSource()[[1]] %>%
      map_df(~{
        .x %>%
          read_html() %>%
          html_nodes('a') %>%
          html_attr('href') %>%
          enframe(name = NULL)
      }) %>%
      filter(grepl('doi', value)) %>%
      unique() %>%
      mutate(value = paste0('https://www.cochranelibrary.com', value))
    
    links_cochrane_partial = bind_rows(links_cochrane_partial, links_cochrane_partial_sub)
  }
  
  links_cochrane = bind_rows(links_cochrane, links_cochrane_partial)
}


#Tidying links
links_cochrane <- links_cochrane %>%
  na.omit() %>%
  unique() 


##Getting titles and abstracts
cochrane_articles <- links_cochrane %>%
  group_by(value) %>%
  nest() %>%  
  mutate(
    title = map_chr(value, ~{
      Sys.sleep(round(runif(1, min = 20, max = 30)))
      try({
        read_html(.x) %>%
          html_nodes(xpath = '//*[@id="portlet_scolariscontentdisplay_WAR_scolariscontentdisplay"]/div[1]/div/div/div[1]/article/header/h1') %>%
          html_text()
      }) %>%
        ifelse(length(.) == 0, NA, .) %>%
        ifelse(is.null(.), NA, .)
    })) %>%
  mutate(
    abstract = map_chr(value, ~{
      Sys.sleep(round(runif(1, min = 20, max = 30)))
      try({
        read_html(.x) %>%
          html_nodes(xpath = '//*[@id="portlet_scolariscontentdisplay_WAR_scolariscontentdisplay"]/div[1]/div/div/div[1]/article/section[1]') %>%
          html_text()
      }) %>%
        ifelse(length(.) == 0, NA, .) %>%
        ifelse(is.null(.), NA, .)
    })) %>%
  unnest() %>%
  ungroup()


#Tidying our data
cochrane_articles <- cochrane_articles %>%
  mutate(journal = 'COCHRANE',
         terms = paste(terms, collapse = ' '),
         across(everything(),~gsub("\n|\t|\r|[ ]{2,}"," ",.)),
         across(everything(),~gsub(" {3,}","",.)),
         across(everything(),~gsub("^ ","",.)),
         across(everything(),~gsub(" $","",.))
  )


## Saving File ##
write_csv(cochrane_articles,'cochrane_articles_experiments.csv')


#End of File