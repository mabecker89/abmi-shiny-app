#-----------------------------------------------------------------------------------------------------------------------

# Define UI
ui <- fluidPage(

  # Title
  titlePanel("ABMI Camera VegHF Information"),

  # Side bar
  sidebarPanel(

    pickerInput(
      inputId = "project_selection",
      label = "Project:",
      choices = projects_available,
      selected = "ABMI Ecosystem Health 2015"
    )
  ),

  # Main
  mainPanel(
    DTOutput(outputId = "veghf_table"),
    br(),
    uiOutput(outputId = "show_image_button"),
    br(),
    uiOutput(outputId = "commit_button_display"),
    textOutput(outputId = "success")
  )

)

#-----------------------------------------------------------------------------------------------------------------------
