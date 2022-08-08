#### Docker Config ####


# Needed packages
pkgs <- c("tidyverse", "rvest", "RSelenium","xml2")


# Install and/or Update packages
install_update <- function(x) {
  if (x %in% rownames(installed.packages()) == F) {
    install.packages(x, dependencies = T,
                     repos = "http://cran.us.r-project.org")
  }
  if (x %in% rownames(old.packages() == T)) {
    update.packages(x,
                    repos = "http://cran.us.r-project.org")
  }
}

# Load packages
lapply(pkgs, install_update)
lapply(pkgs, require, character.only = T)
rm(pkgs, install_update)


## Install Docker dependencies ##

# installing browser dependency
system("docker pull browserless/chrome")
system("docker run --name chrome -d -p 4445:4444 selenium/standalone-chrome")


# installing vpn dependency


## RSelenium configs ##

remDr <- RSelenium::remoteDriver(remoteServerAddr = "localhost",
                                 port = 4445L,
                                 browserName = "chrome")
remDr$open()



# End of File