#-----------------------------------------------
#-----------SCRIPT: CASE STUDY INBO ------------
#-----------------------------------------------

#------------------------
#--1.Load Packages-------
#------------------------

packages <- c("rgbif", "dplyr", "ggplot2", "rnaturalearth", "sf", "CoordinateCleaner")

for(i in packages) {
  print(i)
  if( ! i %in% rownames(installed.packages()) ) { install.packages( i ) }
  library(i, character.only = TRUE)
}



#------------------------
#--2.Define parameters--
#-----------------------
#Year Range (2018 - 2023)
Min_year<-2018
Max_year<-2023

#Species (Vespa velutina)
taxon_key<-name_backbone(name = "Vespa velutina")$usageKey 


#------------------------------------
#---3.Download occurrence records----
#------------------------------------

#Download records from GBIF server
Vespa_velutina_download<- occ_download(
    pred("taxonKey", taxon_key),   #Retrieve all Vespa velutina records
    pred_gte("year", Min_year), #earliest year 
    pred_lte("year", Max_year), #latest year
    pred("hasGeospatialIssue", FALSE), #Remove default geospatial issues
    pred("hasCoordinate", TRUE), # Keep only records with coordinates
    pred("occurrenceStatus", "PRESENT"), #Keep only presences
    pred_gte("distanceFromCentroidInMeters","2000"), #Keep only occurrences at 2k or more from a country centroid
    format= "SIMPLE_CSV" #return a csv file of occurrences
)

#Follow the status of the download    
occ_download_wait(Vespa_velutina_download)

#Retrieve downloaded records
Vespa_velutina_records <- occ_download_get(Vespa_velutina_download,overwrite = TRUE) %>%
  occ_download_import() 
    
#Retrieve citation of downloaded dataset
print(gbif_citation(occ_download_meta(Vespa_velutina_download))$download)


#------------------------------------
#OPTIONAL: some more data cleaning
#------------------------------------
#coordinatePrecision : A decimal representation of the precision of the coordinates.
#coordinateUncertaintyInMeters : the uncertainty of the coordinates in meters.
Vespa_velutina_cleaned <- Vespa_velutina_records  %>%
  cc_dupl()  %>% #Remove duplicated records based on coordinates
  filter(is.na(coordinateUncertaintyInMeters) | # Guarantee a certain precision and low uncertainty in coordinates
           coordinateUncertaintyInMeters < 10000, 
         is.na(coordinatePrecision) | # It is recommended to keep missing values in 
           coordinatePrecision > 0.01)

print(paste0(nrow(Vespa_velutina_records)-nrow(Vespa_velutina_cleaned), " records deleted; ",
             nrow(Vespa_velutina_cleaned), " records remaining." )) 


#----------------------------------------------------------
#---4.Keep only occurrence records in Flanders ------------
#----------------------------------------------------------
#Upload the shapefile of Flanders (shapefile retrieved from https://zenodo.org/records/3386224))
#SIDENOTE: Does not include Brussels
Flanders <- read_sf("Flanders_Occurrence_filter_shapefile/flanders.shp")

#Check CRS of this file
st_crs(Flanders) 

#Convert occurrence dataset to sf object
Vespa_velutina_flanders= st_as_sf(Vespa_velutina_cleaned, coords=c("decimalLongitude","decimalLatitude"), crs=4326 )

#Make sure the shapefile and occurrence sf object both use the same crs (use 4326 in this case)
Flanders<- st_transform(Flanders, st_crs(Vespa_velutina_flanders))

#Select records in occurrence dataset that occur in polygon of Flanders
Vespa_velutina_flanders<- st_filter(Vespa_velutina_flanders, Flanders)


# Create a new column with lat and lon based on the geometry column, remove the latter
Vespa_velutina_flanders <- Vespa_velutina_flanders %>%
  dplyr::mutate(decimalLongitude = sf::st_coordinates(.)[,1],
                decimalLatitude = sf::st_coordinates(.)[,2]) %>% 
  st_drop_geometry()


#--------------------------------------------
#---------5. Plot records on a map-----------
#--------------------------------------------

#Download map of Belgium
Belgium_map <- ne_countries(country = "Belgium", scale = 50)

#Plot occurrence records on the map
ggplot() +
  geom_sf(data = Belgium_map) +
  geom_sf(data=Flanders, fill="green")+ #Highlight Flanders in Green
  geom_point(data = Vespa_velutina_flanders, #Plot occurrences in blue
             aes(x = decimalLongitude,
                 y = decimalLatitude),
                 shape = "x",
             color = "blue") +
  labs(title= expression(paste(italic("Vespa velutina")," in Flanders (2018-2023)")), x="Longitude", y="Latitude") +
  theme_bw()              
  
 
#-----------------------------------------------------------------
#---------6. Plot occurrences as a bargraph (per year) -----------
#-----------------------------------------------------------------

#For plotting purposes, convert column year to factor, and put the levels in the right order
Vespa_velutina_flanders$year <- factor(Vespa_velutina_flanders$year, levels = c("2018","2019", "2020", "2021", "2022", "2023"))

#Plot number of records as a bargraph
bargraph<-ggplot() +
  geom_bar(data=Vespa_velutina_flanders, aes(group=year),color="black", fill="#3495eb", stat="count", width=0.6)+
  aes(x = year) +
  scale_y_continuous(limits=c(0,30000), breaks=c(0,10000, 20000, 30000)) +
  labs(title=expression(paste("Annual observations of ",italic("Vespa velutina")," in Flanders (2018-2023)")),
       x="Year", y ="Number of observations")+
  theme_bw()

bargraph+ theme(   plot.title=element_text(colour = "black", size = rel(1.4)),
                   axis.text = element_text(colour = "black", size = rel(1)),
                   axis.title= element_text(colour = "black", size = rel(1.3)),
                   axis.title.y = element_text(vjust = 2.5),
                   axis.title.x = element_text(vjust = -0.5),
                   axis.text.x = element_text(angle=45, hjust=1, size = rel(1))
                   )


#-----------------------------------------------------------------
#---------7. Short quality check -----------
#-----------------------------------------------------------------
#Couple of records seem to be in NL
unique(Vespa_velutina_flanders$countryCode)

#How many? 357
sum(Vespa_velutina_flanders$countryCode=="NL")

#Plot them:looks okay (border observations)
recordsnl<-dplyr::filter(Vespa_velutina_flanders, countryCode=="NL")
ggplot() +
  geom_sf(data = Belgium_map) +
  geom_sf(data=Flanders, fill="green")+ #Highlight Flanders in Green
  geom_point(data = recordsnl, #Plot occurrences in blue
             aes(x = decimalLongitude,
                 y = decimalLatitude),
             shape = "x",
             color = "blue") +
  labs(x="Longitude", y="Latitude") +
  theme_bw()    

