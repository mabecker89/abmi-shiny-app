#-----------------------------------------------------------------------------------------------------------------------

# Load packages:

# Working with databases:
library(DBI)
library(RSQLite)

# Shiny + associated
library(shiny)
library(shinyWidgets)
library(DT)
library(shinyBS)

# Data manipulation
library(dplyr)
library(tidyr)
library(tibble)
library(fs)
library(stringr)

# Root directory - shared Google Drive 'ABMI Camera Mammals'
root <- "G:/Shared drives/ABMI Camera Mammals/"

# Create database connection to SQLite db 'abmi-camera-mammals.db' ('acm')
acm <- DBI::dbConnect(
  drv = RSQLite::SQLite(),
  paste0(root, "database/abmi-camera-mammals.db")
)

#-----------------------------------------------------------------------------------------------------------------------

# Camera projects available - just ABMI Ecosystem Health (2015-2020) and CMU (2017-2020) for now.
projects_available <- tbl(acm, "projects_lookup") %>% pull(project)

# Available detection distance VegHF categories:
det_dist_categories <- c("Conif",
                         "Decid",
                         "WetGrass",
                         "WetTreed",
                         "HF",
                         "Shrub",
                         "Grass") # This vector is not currently used in the app. Hoping to be part of a drop-down menu.

# Add the directory where example images are location to the Shiny resource path
addResourcePath("images", paste0(root, "data/base/sample-images/shiny-app/"))

# Check resource paths - make sure "images" is there.
resourcePaths()

# Available images and their file paths:
image_file_paths <- fs::dir_ls(paste0(root, "data/base/sample-images/shiny-app/"), glob = "*.jpg", recurse = TRUE) %>%
  path_file() %>%
  as_tibble() %>%
  separate(value, into = c("project", "location", "season"), sep = "_", remove = FALSE) %>%
  mutate(html_path = paste0("<img  src='", "images/", project, "/", value, "' height='50'></img>")) %>%
  # Let's remove winter images for now. Many are missing, and sure if helpful for VegHF classification.
  filter(!str_detect(value, "winter")) %>%
  select(-season)

# Add image paths to acm database (no harm in rerunning this and updating)
dbWriteTable(acm,
             name = "image_file_paths",
             value = image_file_paths,
             overwrite = TRUE)

# Disconnect from database
DBI::dbDisconnect(acm)

#-----------------------------------------------------------------------------------------------------------------------
