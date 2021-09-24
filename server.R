#-----------------------------------------------------------------------------------------------------------------------

# Define server
server <- function(input, output) {

  # An object to store reactive values
  displayed_data <- reactiveValues()

  # When a project is selected from the picker input:
  observeEvent(input$project_selection, {

    req(input$project_selection)

    # Connect to the acm database
    acm <- DBI::dbConnect(
      drv = RSQLite::SQLite(),
      paste0(root, "database/abmi-camera-mammals.db")
    )

    # Disconnect from database on exit - best practice.
    on.exit(DBI::dbDisconnect(acm))

    # Pull 'updates' table for that particular project - where revised VegHF values are stored.
    updates <- dplyr::tbl(acm, paste0(input$project_selection, " updates"))

    # Corresponding images for each location.
    file_paths <- dplyr::tbl(acm, "image_file_paths")

    # VegHF data from the specified project.
    data <- dplyr::tbl(acm, input$project_selection) %>%
      left_join(file_paths, by = c("project", "location")) %>%
      left_join(updates, by = "location") %>%
      arrange(location)

    # Store values
    displayed_data$project <- input$project_selection
    displayed_data$updates <- updates %>% dplyr::collect()
    displayed_data$data <- data %>% dplyr::collect()

    # Set flag to indicate whether values are up to date.
    displayed_data$update_commit_up_to_date <- TRUE

  })

  # Data rendering

  # Datatable
  output$veghf_table <- DT::renderDT({

    dt <- DT::datatable(data = displayed_data$data,
                        extensions = "Buttons",
                        selection = "single",
                        #escape = TRUE,
                        rownames = FALSE,
                        editable = list(target = "cell", disable = list(columns = c(0, 2, 4))),
                        #callback = htmlwidgets::JS(callback)
                        options = list(
                          # Hide a few irrelvevant columns (for now)
                          columnDefs = list(list(targets = c(1, 3, 5, 6), visible = FALSE)),
                          buttons = list(list(extend = 'collection',
                                              buttons = list(
                                                list(extend = 'csv', filename = 'abmi_veghf'),
                                                list(extend = 'excel', filename = 'abmi_veghf')),
                                              text = "Download Data")),
                          dom = 'Bftp',
                          pageLength = 20
                        ))

    # I've been trying some Javascript to create a drop down menu when edits to the VegHF_updated column are made.
    # Not working so far though!

    #path <- "C:/Users/mabec/Documents/R/abmi-shiny-app/src"
    #dep <- htmltools::htmlDependency(name = "CellEdit",
    #version = "1.0.19",
    #src = path,
    #script = "dataTables.cellEdit.js",
    #stylesheet = "dataTables.cellEdit.css")
    #dt$dependencies <- c(dt$dependencies, list(dep))

    dt

  })

  # Set up datatable proxy for when edits are made
  proxy = dataTableProxy('veghf_table')
  observeEvent(input$veghf_table_cell_edit, {

    info = input$veghf_table_cell_edit
    i = info$row
    j = info$col + 1 # Column index offset by 1
    v = info$value

    # Only VegHF_updated column can be edited
    if(colnames(displayed_data$data)[j] == "VegHF_updated"){

      location <- displayed_data$data$location[i]

      displayed_data$updates <- bind_rows(
        displayed_data$updates[!displayed_data$updates$location == location,],
        data.frame(
          location = location,
          VegHF_updated = v
        )
      )

      displayed_data$data <- displayed_data$data %>%
        # Remove old VegHF_updated
        select(-VegHF_updated) %>%
        # Join new VegHF_updated
        left_join(displayed_data$updates, by = "location") %>%
        arrange(location)

      # Set flag to FALSE - there are now updates that haven't been saved to the acm database
      displayed_data$update_commit_up_to_date <- FALSE

    }

    # Replace data in the DT
    DT::replaceData(proxy = proxy,
                    data = displayed_data$data,
                    resetPaging = FALSE,
                    rownames = FALSE)

  })

  # Commit button appears when changes to the table are made (i.e. VegHF_updated is newly filled in)
  output$commit_button_display <- renderUI({
    # Check is the flag is set to FALSE
    if(!displayed_data$update_commit_up_to_date) {
      shinyWidgets::actionBttn(inputId = "commit",
                               label = "Click here to save updates.",
                               style = "simple",
                               color = "warning",
                               size = "md")
    }
  })

  # Commit updates to acm database when commit button is clicked
  observeEvent(input$commit,{

    # Make connection
    acm <- dbConnect(
      drv = RSQLite::SQLite(),
      paste0(root, "database/abmi-camera-mammals.db")
    )

    # Disconnect
    on.exit(dbDisconnect(acm))

    # Write new table with changes
    dbWriteTable(
      conn = acm,
      name = paste0(displayed_data$project, " updates"),
      as.data.frame(displayed_data$updates),
      # Overwrite set to TRUE to update
      overwrite = TRUE
    )

    # Update flag back to TRUE
    displayed_data$update_commit_up_to_date <- TRUE

    # Display message of success
    output$success <- renderText({
      if(displayed_data$update_commit_up_to_date) {
        "Changes saved to database!"
      }
    })
  })

  # Showing images:
  output$show_image_button <- renderUI({
    s <- input$veghf_table_rows_selected # Row number of selected row
    if (length(s) != 0) {
      tagList(
        # Button
        shinyWidgets::actionBttn(inputId = "image_button",
                                 label = "Show image of location",
                                 style = "simple",
                                 color = "primary",
                                 size = "md",
                                 icon = icon("info-circle")),
        # Dialog box with image will pop up
        shinyBS::bsModal(id = "id",
                         title = paste0("Showing timelapse image from: ",
                                        displayed_data$data[s, 2],
                                        " ",
                                        displayed_data$data[s, 1]),
                         trigger = "image_button",
                         size = "large",
                         # Folder to images must be in a resource path (resourcePaths()) - done in global.R
                         img(src = paste0("images/",
                                          displayed_data$data[s, 2],
                                          "/",
                                          displayed_data$data[s, 6]),
                             width = '860')) # This width approximately fills the window
      )}
  })

}

#-----------------------------------------------------------------------------------------------------------------------
