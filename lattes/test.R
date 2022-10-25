

library(tidyverse)
library(rvest)
library(RSelenium)
library(fst)

# tempo: 7:07
#filtros:
## só doutor
## curriculo atualizado
## vinculado pos graduacao 
## procurar literatura
##termos: filantropia, philantropy

rD <- rsDriver(browser = "firefox")
remDr <- rD$client
remDr$open()
remDr$navigate("https://google.com")
remDr$close()


#####################

get_id_10 <- function(id){
  remDr$navigate(paste0(paste0("http://lattes.cnpq.br/",id)))
 id10 = remDr$getCurrentUrl()[[1]]
 return(id10)
}

myswitch <- function (remDr, windowId) {
  qpath <- sprintf("%s/session/%s/window", remDr$serverURL, 
                   remDr$sessionInfo[["id"]])
  remDr$queryRD(qpath, "POST", qdata = list(handle = windowId))
}

#cnpq <- read_csv(paste0(getwd(),"/lattes/","R358737.csv"))
cnpq <- read_fst(paste0(getwd(),"/lattes/","cnpq.fst"))

cnpq$DT_ATUALIZA <- as.Date(cnpq$DT_ATUALIZA, "%d/%m/%Y")

cnpq <- cnpq %>%
  mutate(DT_ATUALIZA = as.Date(DT_ATUALIZA, "%d/%m/%Y")) %>%
  filter(lubridate::year(DT_ATUALIZA) == "2022")

id10 <- list()
resumo <- list()
fullcv <- list()

for(i in 1:nrow(cnpq)){
  id10[[i]] = get_id_10(cnpq$NRO_ID_CNPQ[i])
  id10[[i]] = gsub(".*id.","",id10[[i]])
  
  resumo[[i]] = paste0("http://buscatextual.cnpq.br/buscatextual/preview.do?metodo=apresentar&id=",
                       id10[[i]]) %>%
    read_html() %>%
    html_nodes(xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "resumo", " " ))]') %>%
    html_text2()
  
  print(i)
  
  remDr$navigate(paste0("http://buscatextual.cnpq.br/buscatextual/preview.do?metodo=apresentar&id=",
                        id10[[i]]))
  
  get_fullcv = remDr$findElement(using = "xpath",'//*[@id="id_form_previw"]/div/div/div[2]/div/div/div/div[2]/ul/li[1]/a')
  get_fullcv$clickElement()
  Sys.sleep(1)
  windows_handles <- remDr$getWindowHandles()
  myswitch(remDr, windows_handles[[2]])
  
  fullcv[[i]] = read_html(remDr$getPageSource()[[1]]) %>%
    html_nodes(xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "layout-cell-pad-main", " " ))]') %>%
    html_text2()
  
}

#http://buscatextual.cnpq.br/buscatextual/preview.do?metodo=apresentar&id=K4782056A4 #melhor

# URL = 'http://buscatextual.cnpq.br/buscatextual/preview.do?metodo=apresentar&id={0}'
# URL_LATTES_ID10 = 'http://buscatextual.cnpq.br/buscatextual/visualizacv.do?id={0}'
# URL_LATTES_ID16 = 'http://lattes.cnpq.br/{0}'
# URL_DOWNLOAD_XML = "http://buscatextual.cnpq.br/buscatextual/download.do?metodo=apresentar&idcnpq={0}"


# End of Script