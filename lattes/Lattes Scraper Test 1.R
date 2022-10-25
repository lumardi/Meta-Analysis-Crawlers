

library(tidyverse)
library(rvest)
library(RSelenium)


term <- "filantropia"

driver <- rsDriver(browser = "chrome", port = 9536L, chromever = "104.0.5112.79")

remDr <- driver$client

remDr$open()

myswitch <- function (remDr, windowId) 
{
  qpath <- sprintf("%s/session/%s/window", remDr$serverURL, 
                   remDr$sessionInfo[["id"]])
  remDr$queryRD(qpath, "POST", qdata = list(handle = windowId))
}


link = paste0(
  "https://buscatextual.cnpq.br/buscatextual/busca.do?metodo=forwardPaginaResultados&?numeroPagina=1&registros=0;10&query=%28%2Bidx_assunto%3A",
  term,
  "++%2Bidx_particao%3A1+%2Bidx_nacionalidade%3Ae%29+or+%28%2Bidx_assunto%3Afilantropia++%2Bidx_particao%3A1+%2Bidx_nacionalidade%3Ab+%5E500+%29&analise=cv&tipoOrdenacao=null&paginaOrigem=index.do&mostrarScore=true&mostrarBandeira=true&modoIndAdhoc=null"
)


#checar quantos resultados o termo encontra
numresults = read_html(link) %>%
  html_nodes(xpath  = "/html/body/form/div/div[3]/div/div/div/div[3]/div/div[1]/b[1]") %>%
  html_text()

# alterar link para ter do primeiro ao ultimo resultado
link = gsub("registros=0;[0-9]*",
            paste0("registros=0;",numresults),
            link
            )

# raspando previews dos autores 
preview = read_html(link) %>%
  html_nodes(xpath = "//li") %>%
  html_text() %>%
  gsub("^[0-9]*\\%","",.) %>%
  enframe(name=NULL)

write_csv(preview,paste0("preview_",term,"_raw.csv"))

#acessando links

remDr$navigate(link)

researchers = list()

for(i in 1:as.numeric(numresults)){

  researcherelem = remDr$findElement(using = "xpath",
                                  paste0(
                                    "/html/body/form/div/div[4]/div/div/div/div[3]/div/div[3]/ol/li[",
                                    i,
                                    "]/b/a"
                                  ))
  
  researcherelem$clickElement()
  
  Sys.sleep(rpois(1,2))
  
  researcherelem2 = remDr$findElement(using = 'id',
                                      'idbtnabrircurriculo')
  researcherelem2$clickElement()
  
  Sys.sleep(rpois(1,2))
  
  windows_handles <- remDr$getWindowHandles()
  
  Sys.sleep(rpois(1,2))
  
  myswitch(remDr, windows_handles[[2]])
  
  researchers[[i]] = read_html(remDr$getPageSource()[[1]]) %>% 
    html_nodes(xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "layout-cell-pad-main", " " ))]') %>%
    html_text() %>%
    enframe(name = NULL)
  
  remDr$closeWindow()
  
  myswitch(remDr, windows_handles[[1]])
  
  fechar = remDr$findElement(using = 'id', 'idbtnfechar')
  fechar$clickElement()

}





# End of File 