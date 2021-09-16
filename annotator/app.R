#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(googlesheets4)
library(tidyverse)
library(shinyWidgets)
library(htmltools)




ui <- fluidPage(
    
    # Application title
    titlePanel("Data Annotator"),

    sidebarLayout(
        sidebarPanel(  # Input: Select a file ----
                       fileInput("json_auth", "Choose JSON File",
                                 multiple = FALSE),  # Input: Select a file ----
                       fileInput("data_file", "Choose data File",
                                 multiple = FALSE,
                                 accept = c("text/csv",
                                            "text/comma-separated-values,text/plain",
                                            ".csv")),
                       textInput('sheet_key', "Sheet Key:"),
                       actionButton('load', 'Load sheet'),
                       actionBttn('yes', 'Yes', style = 'fill', size = 'sm', color = 'success'),
                       actionBttn('no', 'No', style = 'fill', size = 'sm', color = 'danger'),
                       actionBttn('maybe', 'Maybe', style = 'fill', size = 'sm', color = 'primary'),
                       br(),
                       br(),
                       actionButton('previous', 'Previous'),
                       actionButton('nextone', 'Next'),
                       actionButton("show", "Show Image"),
                       br(),
                       br(),
                       textInput('places', "Notes Field 1"),
                       textInput('text', "Notes Field 2"),
                       actionButton('just_notes', 'Add notes'),
                       br(),
                       br(),
                       textInput('skipto', 'Skip to abstract', width = 200),
                       actionButton('skip', 'Skip'),
                       br()
        ),
        
        # Show a plot of the generated distribution
        mainPanel(fluidRow(column(6,h3("Letter Details:"),
                                  htmlOutput("the_component"),
                                  uiOutput('component_number'),
                                  h3("Existing Details:"), 
                                  uiOutput("current_selection"),
                                  htmlOutput('ind_match', height = 800)),
                           column(3, uiOutput("checkbox")),h3("Progress:"),
                           column(5, 
                                  plotOutput("progress", height = 550, click = 'click', hover = 'hover'), uiOutput('vals'),
                                  uiOutput("5")))
        )
    )
)

# Define server logic required to draw a histogram

server <- function(input, output, session) {
    
    # Authorise the Google API using your .json file.
    
    observeEvent(input$load,{
        
        googlesheets4::gs4_auth(path = input$json_auth$datapath)
        
    })
    
    # Put the sheet key provided into a reactive variable
    
    sheet_key = eventReactive(input$load,{
        
        input$sheet_key
        
    })
    
    # Load the sheet using the sheet key provided.
    
    sheet = eventReactive(input$load,{
        
        read_sheet(sheet_key(), col_names = F)
        
    })
    
    # Load the data to be labelled, from the provided .csv.
    
    data_to_label = reactive({
        
        read_csv(input$data_file$datapath)
    })
    
    
    
    # Create a 'counter' variable with a value of 1. Changing this will navigate through the data.
    
    counter <- reactiveValues(countervalue = 1)
    
    
    # Create a set of observe events which will increase or decrease the counter value, depending on an action taken. 
    
    observeEvent(input$previous,{
        
        counter$countervalue <- counter$countervalue - 1
    })
    
    observeEvent(input$nextone,{
        
        counter$countervalue <- counter$countervalue + 1
    })
    
    observeEvent(input$skip,{
        
        counter$countervalue <- as.numeric(input$skipto)
    })
    

    # This last one changes the counter value to the value clicked on in the GUI.
    
    observeEvent(input$click,{
        
        
        row_to_click = nearPoints(data(), input$click,maxpoints = 1) %>% pull(row_id)
        counter$countervalue <- row_to_click 
    })
    
    
    # Print the relevant text from the current data row in the main portion of the screen.
    
    output$current_selection = renderUI({
        print(counter$countervalue)
        fields = range_read(sheet_key(), sheet = 1, range = paste0("B", counter$countervalue, ":", "E", counter$countervalue), col_names = F) %>% 
            as.character()
        
        p(em("Current decision:"),br(fields[1]), br(),
          em("Places found:"),
          br(fields[2]),
          em("Notes:"),
          br(fields[3]), br(),
          em("Matches correct (if only some correct):"),br(fields[4]))
    })
    
    # Create a a a series of Observe events which will write the relevant data to Google sheets, and also increase the counter value by one, depending on a decision button clicked.
    
    observeEvent(input$yes, {
        
        
        data = tibble(data_to_label()$key[counter$countervalue],'yes', input$places, input$text)
        range_write(sheet_key(), data, sheet = 1, range = paste0("A", counter$countervalue), col_names = F)
        counter$countervalue <- counter$countervalue + 1
    })
    
    observeEvent(input$no, {
        
        
        data = tibble(data_to_label()$key[counter$countervalue], 'no',input$places, input$text)
        range_write(sheet_key(), data, sheet = 1, range = paste0("A", counter$countervalue), col_names = F)
        counter$countervalue <- counter$countervalue + 1
    })
    
    observeEvent(input$maybe, {
        
        matches_correct = paste(input$checkbox,collapse=";")
        data = tibble(data_to_label()$key[counter$countervalue],'maybe',input$places, input$text, matches_correct)
        range_write(sheet_key(), data, sheet = 1, range = paste0("A", counter$countervalue), col_names = F)
        counter$countervalue <- counter$countervalue + 1
    })
    
    observeEvent(input$just_notes, {
        
        
        data = tibble(data_to_label()$key[counter$countervalue], 'just_notes', input$places,input$text)
        range_write(sheet_key(), data, sheet = 1, range = paste0("A", counter$countervalue), col_names = F)
        updateTextInput(session,"text", "Notes Field:", value=NULL)
    })
    
    

    # Create the data needed for the progress grid. 
    
    data = eventReactive(c(input$yes,input$no, input$previous, input$nextone),{
        
        
        
        fields = read_sheet(input$sheet_key, sheet = 1, col_names = T) %>% 
            mutate(row_id = 1:nrow(.))
        
        colnames(fields) = c('key', 'decision', 'places', 'notes', 'row_id')
        
        fields = fields %>% 
            mutate(done = ifelse(is.na(decision), 'no', 
                                 ifelse(decision == 'yes', 'correct',
                                        ifelse(decision == 'maybe', 'some', 'no_mention'))))
        
        
        x <- LETTERS[1:20]
        y <- paste0("var", seq(1,(nrow(data_to_label())/20)))
        data <- expand.grid(X=x, Y=y)
        data = data %>% mutate(row_id = 1:nrow(.))
        
        data %>% 
            left_join(fields %>% 
                          select(row_id, done), by = 'row_id') %>% 
            mutate(done = ifelse(is.na(done), 'no', done))
    })
    
    # Draw the progress grid, updated any time there's a change in the data.
    
    output$progress = renderPlot({
        
        p =  ggplot(data(), aes(X, Y, fill= done, text = row_id)) + 
            geom_tile(color = 'black') +
            theme_void() + theme(legend.position = 'bottom') + 
            scale_fill_manual(values = c('no' = 'gray80', 'correct' = 'green', 'no_mention' = 'red', 'some' = 'blue'))
        
        p
        
    })
    
    
    # Print the first 100 characters of a row underneath the progress grid, when hovered over.
    
    output$vals <- renderPrint({
        hover <- input$hover 
        y <- nearPoints(data(), input$hover, maxpoints = 1) %>% pull(row_id)
        z = data_to_label() %>% slice(y) %>% pull(abstract)  %>% substr(1,100)
        HTML(paste0("<br><b>ROW: ", z, "</b>"))
    }) 
    
    output$component_number = renderUI(h4("Abstract ID:",counter$countervalue))
    
}

# Run the application 
shinyApp(ui = ui, server = server)
