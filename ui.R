
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)

shinyUI(
  fluidPage(

  # Application title
  titlePanel("NFL Game Score Predictor"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      helpText("The sliders adjust gain:",
               "1) Points for offensive scoring mean",
               "2) How strong the defense is at preventing points",
               "3) Points award/subtracted to offensive for each turnover"),
      sliderInput("PtsForGain",
                  "Offensive Gain:",
                  min = 0.1,
                  max = 2.0, 
                  value = 1),
      sliderInput("PtsAgtGain",
                  "Defensive Gain:",
                  min = 0.1,
                  max = 2, 
                  value = 1),
      sliderInput("TOGain",
                  "Turnover Points:",
                  min = 0,
                  max = 10, 
                  value = 4.6)
    ),

    # Show a plot of the generated distribution
    mainPanel(
      helpText("The following histogram shows the variation of the predictor",
             "from the actual NFL games played in the 2015 season.",
             "Setting the slider gains will vary the accuracy of the",
             "model.  The goal would be to have a zero MeanError with minimum",
             "StandardError."),
      plotOutput("NLFPredictions"),
      
      fluidPage(
          fluidRow(
              column(3,offset = 3,
                     tableOutput("PredStats")
              )
          )
      )
    )
  )
))
