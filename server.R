
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(dplyr)

# Initially load the needed NFL data
set.seed(100)
TOPD.All <- read.csv("TurnOverPointData.txt")  # [T]urn [O]ver [P]oint [D]ifferential 
TOPD <- TOPD.All %>% filter(gameid < 2015000000)
TOPD <- mutate(TOPD, PlayYear = round(gameid/1000000,0)-2008)
TOPD.Test <- TOPD.All %>% filter(gameid > 2015000000)

WtDen <- sum(unique(TOPD$PlayYear))

Mean.Stats.Away <- TOPD %>% group_by(away_team,PlayYear) %>% summarise_all(mean) %>% 
    select(PlayYear,away_team, away_score, home_score, home_turnovers) %>% 
    mutate(HW = 'A') %>% 
    mutate(Weighted=PlayYear/WtDen ) %>%
    mutate(Team = away_team, Mean.PF=away_score * Weighted, Mean.PA = home_score * Weighted, Mean.FTO=home_turnovers *Weighted) %>%
    select(Team, Mean.PF, Mean.PA, Mean.FTO) %>%
    group_by(Team) %>% summarise_if(is.numeric, sum)

    
Mean.Stats.Home <- TOPD %>% group_by(home_team,PlayYear) %>% summarise_all(mean) %>% 
    select(PlayYear,home_team, home_score, away_score, away_turnovers) %>% 
    mutate(HW = 'A') %>% 
    mutate(Weighted=PlayYear/WtDen ) %>%
    mutate(Team = home_team, Mean.PF=home_score * Weighted, Mean.PA = away_score * Weighted, Mean.FTO=away_turnovers *Weighted) %>%
    select(Team, Mean.PF, Mean.PA, Mean.FTO) %>%
    group_by(Team) %>% summarise_if(is.numeric, sum)

Mean.Stats <- rbind(Mean.Stats.Away, Mean.Stats.Home)
Mean.PA <- mean(Mean.Stats$Mean.PA)
Mean.PF <- mean(Mean.Stats$Mean.PF)

# Get a team score using their mean points for, opponent points against 
# and how many turnovers they force.
GetScoreDif <- function(Home.Team, Away.Team, PF.Gain,PA.Gain, TO.Gain ) {
    hteampf <-  Mean.Stats.Home[Mean.Stats.Home$Team == Home.Team,2]
    ateampf <-  Mean.Stats.Away[Mean.Stats.Away$Team == Away.Team,2]
    hteampa <-  Mean.Stats.Home[Mean.Stats.Home$Team == Home.Team,3]
    ateampa <-  Mean.Stats.Away[Mean.Stats.Away$Team == Away.Team,3]
    hteamfto <- Mean.Stats.Home[Mean.Stats.Home$Team == Home.Team,4]
    ateamfto <- Mean.Stats.Away[Mean.Stats.Away$Team == Away.Team,4]
    
    scoredif <- (PF.Gain * hteampf * (PA.Gain * (ateampa/Mean.PA)) + 
        (TO.Gain * hteamfto)) -
        (PF.Gain * ateampf * (PA.Gain * (hteampa/Mean.PA)) + 
        (TO.Gain * ateamfto))
    return(scoredif)
}

shinyServer(function(input, output) {
    updateTOPD <- reactive ({
        TOPD.Test <<-TOPD.Test %>% rowwise() %>% 
                mutate(PredPtsDif = GetScoreDif(
                    home_team,
                    away_team,
                    input$PtsForGain,
                    input$PtsAgtGain,
                    input$TOGain
                )
            )
        TOPD.Test <<- TOPD.Test %>% mutate(PredPtsError = PointDifHome - PredPtsDif)
        TOPD.Test <<- TOPD.Test %>% mutate(WinCorrect = as.numeric((PredPtsDif * PointDifHome) > 0))
        TOPD.Test <<- TOPD.Test %>% mutate(Wins = as.numeric(PointDifHome > 0))
        TOPD.Test <<- TOPD.Test %>% mutate(Losses = as.numeric(PointDifHome <= 0))
        TOPD.Test <<- TOPD.Test %>% mutate(PWins = as.numeric(PredPtsDif > 0))
        TOPD.Test <<- TOPD.Test %>% mutate(PLosses = as.numeric(PredPtsDif <= 0))
        
    })
    
    output$NLFPredictions <- renderPlot({
        updateTOPD()
        
        p <- hist(x = TOPD.Test$PredPtsError, breaks = 40,freq = TRUE,
                  xlab = "Point Difference (Predicted - Actual)",
                  main = "Point Difference Histogram for NFL 2015 Season",
                  col = 'blue')
    })

    output$PredStats <- renderTable({
        updateTOPD()
        data.frame(MeanError=mean(TOPD.Test$PredPtsError), StandardError=sd(TOPD.Test$PredPtsError), TotalGames=nrow(TOPD.Test))
    }, width=400)
    
    
})
