# Invasive_species

## Overview
This repository contains the R code and necessary material to retrieve species occurrences from GBIF for a specific year range in Flanders and to visually plot these data as a map of observations and a bar chart of observations per year.

## Installation

1. Clone this repository to your computer
2. Open the RStudio Script
3. Click `Run > Run all` to run the commands

Note: To run this code you'll need to have a GBIF account, and allow the rgbif package access 
to your GBIF credentials. This can be easily done by saving them in your **.Renviron** file by running 
the following code in RStudio:

```install.packages("usethis")  
usethis::edit_r_environ()  
GBIF_USER="yourusername"  
GBIF_PWD="yourpassword"  
GBIF_EMAIL="youremail" ```

