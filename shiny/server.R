# server.R — Vin & Météo : influence du climat sur la qualité des vins

library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(tidyr)
library(plotly)
library(leaflet)
library(DT)
library(stringr)
library(forcats)
library(RColorBrewer)
library(ggrepel)
library(readr)

# ── Données (chargées une seule fois) ────────────────────────────────────────

wines <- read_csv("../data/wines_merged.csv", show_col_types = FALSE) %>%
  mutate(type = as.factor(type))

wines_f <- wines %>% filter(NumberOfRatings >= 100)

# Palette de couleurs constante par type
TYPE_COLS <- c(Red="#c0392b", White="#8e44ad", Rose="#2980b9", Sparkling="#27ae60")

# Table continent
CONTINENT <- tibble(
  Country = c("France","Italy","Spain","Portugal","Germany","Austria","Switzerland",
              "Greece","Hungary","Romania","United States","Argentina","Chile",
              "Uruguay","Brazil","Australia","New Zealand","South Africa",
              "Israel","Lebanon","Turkey","China","Japan"),
  Continent = c("Europe","Europe","Europe","Europe","Europe","Europe","Europe",
                "Europe","Europe","Europe","Amériques","Amériques","Amériques",
                "Amériques","Amériques","Océanie","Océanie","Afrique",
                "Asie","Asie","Asie","Asie","Asie")
)

# ── Server ────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {
  
  # ── HOME ──────────────────────────────────────────────────────────────────
  
  output$vb_wines     <- renderValueBox(valueBox(
    format(nrow(wines), big.mark=" "), "Vins dans le dataset",
    icon=icon("wine-glass"), color="red"))
  
  output$vb_countries <- renderValueBox(valueBox(
    n_distinct(wines$Country, na.rm=TRUE), "Pays producteurs",
    icon=icon("globe"), color="red"))
  
  output$vb_regions   <- renderValueBox(valueBox(
    format(n_distinct(wines$Region, na.rm=TRUE), big.mark=" "), "Régions viticoles",
    icon=icon("map-marker"), color="red"))
  
  output$vb_vars      <- renderValueBox(valueBox(
    ncol(wines), "Variables (dont 60 météo)",
    icon=icon("cloud"), color="red"))
  
  output$home_types <- renderPlotly({
    df <- wines %>% count(type) %>% mutate(pct=round(n/sum(n)*100,1))
    ggplotly(
      ggplot(df, aes(x=reorder(type,-n), y=n, fill=type,
                     text=paste0(type,": ",n," vins (",pct,"%)"))) +
        geom_col(width=.65) +
        scale_fill_manual(values=TYPE_COLS, guide="none") +
        labs(x=NULL, y="Nombre de vins") + theme_bw(),
      tooltip="text")
  })
  
  output$home_ratings <- renderPlotly({
    ggplotly(
      ggplot(wines, aes(x=Rating, fill=type)) +
        geom_histogram(binwidth=.1, alpha=.75, position="stack") +
        scale_fill_manual(values=TYPE_COLS, name="Type") +
        labs(x="Note", y="Nombre de vins") + theme_bw()
    )
  })
  
  # ── Q1 — Distribution ─────────────────────────────────────────────────────
  
  output$q1_plot <- renderPlotly({
    df <- if (input$q1_filter) wines_f else wines
    df <- df %>% filter(type %in% input$q1_types)
    p  <- ggplot(df, aes(x=type, y=Rating, fill=type)) +
      geom_violin(alpha=.55, trim=FALSE) +
      scale_fill_manual(values=TYPE_COLS, guide="none") +
      scale_y_continuous(limits=c(2,5.3), breaks=seq(2.5,5,.25)) +
      labs(title="Distribution des notes par type", x="Type", y="Note (Rating)") +
      theme_bw()
    if (input$q1_bxp)
      p <- p + geom_boxplot(width=.12, fill="white", alpha=.85,
                            outlier.size=.4, outlier.alpha=.3)
    ggplotly(p)
  })
  
  # ── Q2 — Fiabilité ────────────────────────────────────────────────────────
  
  output$q2_plot <- renderPlotly({
    df <- wines %>%
      filter(type %in% input$q2_types, NumberOfRatings >= 25) %>%
      mutate(tr = cut(NumberOfRatings,
                      breaks=c(25,50,100,200,500,1000,Inf),
                      labels=c("25–49","50–99","100–199","200–499","500–999","1 000+"),
                      right=FALSE))
    
    # Position x de la ligne seuil selon le slider
    tranche_breaks <- c(25, 50, 100, 200, 500, 1000, Inf)
    thresh_x <- findInterval(input$q2_thresh, tranche_breaks) - 0.5
    thresh_x <- max(0.5, min(thresh_x, 5.5))  # borner entre 0.5 et 5.5
    
    # Libellé dynamique pour la zone retenue
    tr_labels <- c("25–49","50–99","100–199","200–499","500–999","1 000+")
    thresh_label <- paste0("Zone retenue (≥ ", input$q2_thresh, " avis)")
    
    p <- ggplot(df, aes(x=tr, y=Rating, fill=tr)) +
      geom_boxplot(outlier.size=.4, outlier.alpha=.3, width=.65) +
      annotate("rect", xmin=.5,       xmax=thresh_x, ymin=-Inf, ymax=Inf,
               fill="#e74c3c", alpha=.07) +
      annotate("rect", xmin=thresh_x, xmax=6.5,      ymin=-Inf, ymax=Inf,
               fill="#27ae60", alpha=.07) +
      geom_vline(xintercept=thresh_x, linetype="dashed", color="grey20", linewidth=.9) +
      annotate("text", x=max(.8, thresh_x/2),       y=4.87,
               label="Zone peu fiable",   color="#c0392b", size=3.5, fontface="bold") +
      annotate("text", x=min(5.5, thresh_x + 1.5),  y=4.87,
               label=thresh_label,        color="#27ae60", size=3.5, fontface="bold") +
      scale_fill_brewer(palette="Blues", guide="none") +
      labs(title="Fiabilité des notes selon le nombre d'évaluations",
           x="Tranche de nombre d'avis", y="Note moyenne") +
      theme_bw()
    ggplotly(p)
  })
  
  # ── Q3 — Prix vs Note ─────────────────────────────────────────────────────
  
  output$q3_cors <- renderUI({
    df <- (if (input$q3_filter) wines_f else wines) %>%
      filter(type %in% input$q3_types, !is.na(Price), Price>0)
    cors <- df %>% group_by(type) %>%
      summarise(r=round(cor(log10(Price), Rating, use="complete.obs"),3), .groups="drop")
    tags$div(tags$strong("r (log Prix ~ Note) :"), tags$br(),
             lapply(seq_len(nrow(cors)), function(i)
               tags$span(paste0(cors$type[i],": ",cors$r[i]), tags$br())))
  })
  
  output$q3_plot <- renderPlotly({
    df <- (if (input$q3_filter) wines_f else wines) %>%
      filter(type %in% input$q3_types, !is.na(Price), Price>0)
    p <- ggplot(df, aes(x=Price, y=Rating, color=type)) +
      geom_point(alpha=.25, size=.7) +
      scale_x_log10() +
      scale_color_manual(values=TYPE_COLS, guide="none") +
      facet_wrap(~type, scales="free_x") +
      labs(title="Relation prix-note par type", x="Prix (échelle log)", y="Note") +
      theme_bw()
    if (input$q3_reg)
      p <- p + geom_smooth(method="lm", se=FALSE, color="black", linewidth=.9)
    ggplotly(p)
  })
  
  # ── Q4 — Top régions ──────────────────────────────────────────────────────
  
  output$q4_plot <- renderPlotly({
    df <- wines_f %>%
      filter(!is.na(Region), !is.na(Country)) %>%
      group_by(Region, Country) %>%
      summarise(n=n(), mean_r=mean(Rating,na.rm=TRUE), .groups="drop") %>%
      filter(n >= input$q4_minw) %>%
      slice_max(mean_r, n=input$q4_n)
    pal <- colorRampPalette(brewer.pal(12,"Paired"))(n_distinct(df$Country))
    p <- ggplot(df, aes(y=reorder(Region,mean_r), x=mean_r, color=Country,
                        text=paste0(Region," (",Country,")<br>Note: ",round(mean_r,3),
                                    "  |  N vins: ",n))) +
      geom_segment(aes(x=min(mean_r)-.02, xend=mean_r,
                       yend=reorder(Region,mean_r)), color="grey75", linewidth=.6) +
      geom_point(size=4) +
      scale_color_manual(values=pal, name="Pays") +
      labs(title=paste("Top",input$q4_n,"régions par note moyenne"),
           x="Note moyenne", y=NULL) + theme_bw()
    ggplotly(p, tooltip="text")
  })
  
  # ── Q5 — Effet domaine ────────────────────────────────────────────────────
  
  output$q5_plot <- renderPlotly({
    reg_avg <- wines %>% group_by(Region) %>%
      summarise(reg_m=mean(Rating,na.rm=TRUE), .groups="drop")
    df <- wines %>%
      filter(!is.na(Winery), !is.na(Region), type %in% input$q5_types) %>%
      left_join(reg_avg, by="Region") %>%
      mutate(ecart=Rating-reg_m) %>%
      group_by(Winery, type) %>%
      summarise(n=n(), em=mean(ecart,na.rm=TRUE),
                se=sd(ecart,na.rm=TRUE)/sqrt(n()), .groups="drop") %>%
      filter(n>=input$q5_minw) %>% slice_max(em, n=input$q5_n)
    p <- ggplot(df, aes(x=em, y=reorder(Winery,em), color=type,
                        text=paste0(Winery," (",type,")<br>Écart: +",
                                    round(em,3),"  |  N: ",n))) +
      geom_point(size=3) +
      geom_errorbarh(aes(xmin=em-1.96*se, xmax=em+1.96*se), height=.3, linewidth=.6) +
      geom_vline(xintercept=0, linetype="dashed", color="grey40") +
      scale_color_manual(values=TYPE_COLS, name="Type") +
      labs(title="Producteurs surperformant leur région",
           x="Écart moyen à la note régionale", y=NULL,
           caption="Barres d'erreur = IC 95%") + theme_bw()
    ggplotly(p, tooltip="text")
  })
  
  # ── Q6 — Prix & Popularité ────────────────────────────────────────────────
  
  output$q6_plot <- renderPlotly({
    df <- wines %>%
      filter(type %in% input$q6_types, !is.na(Price), Price>0,
             NumberOfRatings>=input$q6_minr) %>%
      mutate(lp=log10(Price), lnr=log10(NumberOfRatings),
             type=fct_relevel(type,"Red","White","Rose","Sparkling"))
    med <- df %>% group_by(type) %>%
      summarise(mp=median(lp), mnr=median(lnr), .groups="drop")
    p <- ggplot(df, aes(x=lp, y=lnr, color=Rating,
                        text=paste0("Prix: ",round(10^lp),"€<br>Avis: ",
                                    round(10^lnr),"<br>Note: ",round(Rating,2)))) +
      geom_point(alpha=.25, size=.9) +
      geom_vline(data=med, aes(xintercept=mp),  linetype="dashed",color="grey40",linewidth=.5) +
      geom_hline(data=med, aes(yintercept=mnr), linetype="dashed",color="grey40",linewidth=.5) +
      scale_color_gradientn(colours=c("#d73027","#fee08b","#1a9850"),
                            name="Note", limits=c(2.5,5)) +
      scale_x_continuous(name="Prix (€, log)",
                         breaks=log10(c(5,10,50,100,500,1000)),labels=c("5","10","50","100","500","1k")) +
      scale_y_continuous(name="Nb évaluations (log)",
                         breaks=log10(c(25,100,500,1000,5000,20000)),labels=c("25","100","500","1k","5k","20k")) +
      facet_wrap(~type, ncol=2, scales="free") +
      labs(title="Prix, popularité et note : quatre profils de vins") + theme_bw()
    ggplotly(p, tooltip="text")
  })
  
  # ── Q7 — Pays note vs prix ────────────────────────────────────────────────
  
  output$q7_plot <- renderPlotly({
    df <- wines_f %>%
      filter(!is.na(Country), !is.na(Price), Price>0) %>%
      group_by(Country) %>%
      summarise(n=n(), rm=median(Rating,na.rm=TRUE), pm=median(Price,na.rm=TRUE), .groups="drop") %>%
      filter(n>=input$q7_minw) %>%
      left_join(CONTINENT, by="Country") %>%
      mutate(Continent=replace_na(Continent,"Autre"))
    p <- ggplot(df, aes(x=pm, y=rm, color=Continent,
                        text=paste0(Country,"<br>Note méd.: ",round(rm,2),
                                    "<br>Prix méd.: ",round(pm,0),"€<br>N: ",n))) +
      geom_point(size=5, alpha=.85) +
      scale_color_brewer(palette="Set1", name="Continent") +
      scale_x_log10(labels=function(x) paste0(x,"€")) +
      labs(title="Positionnement des pays : note vs prix médians",
           x="Prix médian (€, log)", y="Note médiane") + theme_bw()
    if (input$q7_lbl)
      p <- p + geom_text_repel(aes(label=Country), size=3.2, show.legend=FALSE)
    ggplotly(p, tooltip="text")
  })
  
  # ── Q8 — Rapport qualité/prix ─────────────────────────────────────────────
  
  output$q8_plot <- renderPlotly({
    df <- wines_f %>% filter(!is.na(Price), Price>0) %>%
      mutate(qp=Rating/log(Price+1))
    tqp <- df %>% group_by(type) %>%
      summarise(m=mean(qp,na.rm=TRUE), se=sd(qp,na.rm=TRUE)/sqrt(n()), .groups="drop")
    top_c <- df %>% count(Country,sort=TRUE) %>% slice_max(n,n=input$q8_nc) %>% pull(Country)
    cqp   <- df %>% filter(Country %in% top_c) %>% group_by(Country) %>%
      summarise(m=mean(qp,na.rm=TRUE), se=sd(qp,na.rm=TRUE)/sqrt(n()), .groups="drop")
    eb <- input$q8_eb
    p1 <- ggplot(tqp, aes(x=reorder(type,m), y=m, fill=type,
                          text=paste0(type,"<br>Score: ",round(m,3)))) +
      geom_col(width=.65) +
      { if(eb) geom_errorbar(aes(ymin=m-1.96*se,ymax=m+1.96*se),width=.3) } +
      scale_fill_manual(values=TYPE_COLS,guide="none") + coord_flip() +
      labs(title="Par type de vin", x=NULL, y="Score qualité/prix") + theme_bw()
    p2 <- ggplot(cqp, aes(x=reorder(Country,m), y=m, fill=Country,
                          text=paste0(Country,"<br>Score: ",round(m,3)))) +
      geom_col(width=.65) +
      { if(eb) geom_errorbar(aes(ymin=m-1.96*se,ymax=m+1.96*se),width=.3) } +
      scale_fill_brewer(palette="Paired",guide="none") + coord_flip() +
      labs(title="Par pays", x=NULL, y="Score qualité/prix") + theme_bw()
    subplot(ggplotly(p1,tooltip="text"), ggplotly(p2,tooltip="text"),
            nrows=1, shareY=FALSE, titleX=TRUE)
  })
  
  # ── Q9 — Latitude ─────────────────────────────────────────────────────────
  
  q9_geo <- reactive({
    wines_f %>% filter(!is.na(lat),!is.na(lng)) %>%
      group_by(Region,lat,lng) %>%
      summarise(mean_r=mean(Rating,na.rm=TRUE), n=n(), .groups="drop") %>%
      filter(n>=input$q9_minw)
  })
  
  output$q9_map <- renderLeaflet({
    df  <- q9_geo()
    pal <- colorNumeric(c("#d73027","#fee08b","#1a9850"), domain=c(3,4.8))
    leaflet(df) %>% addTiles() %>%
      addCircleMarkers(~lng, ~lat, radius=6, color=~pal(mean_r),
                       fillOpacity=.8, stroke=TRUE, weight=1,
                       popup=~paste0("<b>",Region,"</b><br>Note moy.: ",round(mean_r,2),
                                     "<br>N vins: ",n)) %>%
      addLegend(pal=pal, values=~mean_r, title="Note moy.", position="bottomright")
  })
  
  output$q9_scat <- renderPlotly({
    df <- q9_geo()
    p  <- ggplot(df, aes(x=lat, y=mean_r, color=mean_r,
                         text=paste0(Region,"<br>Lat: ",round(lat,1),"°<br>Note: ",
                                     round(mean_r,2)))) +
      geom_point(size=2.5, alpha=.7) +
      scale_color_gradientn(colours=c("#d73027","#fee08b","#1a9850"), guide="none") +
      labs(title="Latitude vs note moyenne par région",
           x="Latitude (degrés N)", y="Note moyenne") + theme_bw()
    if (input$q9_reg) {
      lm_fit  <- lm(mean_r ~ lat, data=df)
      x_seq   <- seq(min(df$lat, na.rm=TRUE), max(df$lat, na.rm=TRUE), length.out=100)
      lm_pred <- predict(lm_fit, newdata=data.frame(lat=x_seq),
                         interval="confidence", level=.95)
      lm_df   <- data.frame(lat=x_seq, mean_r=lm_pred[,"fit"],
                            lo=lm_pred[,"lwr"], hi=lm_pred[,"upr"])
      p <- p +
        geom_ribbon(data=lm_df, aes(x=lat, ymin=lo, ymax=hi),
                    fill="grey70", alpha=.35, inherit.aes=FALSE) +
        geom_line(data=lm_df, aes(x=lat, y=mean_r),
                  color="black", linewidth=.9, inherit.aes=FALSE)
    }
    ggplotly(p, tooltip="text")
  })
  
  # ── Q10 — Évolution temporelle ────────────────────────────────────────────
  
  output$q10_plot <- renderPlotly({
    df <- wines_f %>%
      filter(type %in% input$q10_types,
             Year>=input$q10_yr[1], Year<=input$q10_yr[2]) %>%
      group_by(Year,type) %>%
      summarise(m=mean(Rating,na.rm=TRUE), se=sd(Rating,na.rm=TRUE)/sqrt(n()), .groups="drop")
    p <- ggplot(df, aes(x=Year, y=m, color=type, fill=type))
    if (input$q10_rib)
      p <- p + geom_ribbon(aes(ymin=m-1.96*se,ymax=m+1.96*se), alpha=.15, color=NA)
    p <- p + geom_line(linewidth=.9) + geom_point(size=2) +
      scale_color_manual(values=TYPE_COLS, name="Type") +
      scale_fill_manual(values=TYPE_COLS, guide="none") +
      scale_x_continuous(breaks=seq(2005,2019,2)) +
      facet_wrap(~type, ncol=2) +
      labs(title="Évolution de la note moyenne par millésime",
           x="Millésime", y="Note moyenne") + theme_bw()
    ggplotly(p)
  })
  
  # ── Q11 — Régularité régions ──────────────────────────────────────────────
  
  output$q11_plot <- renderPlotly({
    reg <- wines_f %>% filter(!is.na(Region),!is.na(Year)) %>%
      group_by(Region,Year) %>% summarise(m=mean(Rating,na.rm=TRUE),.groups="drop") %>%
      group_by(Region) %>%
      summarise(ny=n_distinct(Year), std=sd(m,na.rm=TRUE), .groups="drop") %>%
      filter(ny>=input$q11_miny) %>%
      left_join(wines %>% distinct(Region,Country) %>% group_by(Region) %>% slice(1),
                by="Region")
    stable <- reg %>% slice_min(std, n=input$q11_n)
    capric <- reg %>% slice_max(std, n=input$q11_n)
    df <- bind_rows(mutate(stable,g="Plus stables"), mutate(capric,g="Plus capricieuses"))
    pal <- colorRampPalette(brewer.pal(12,"Paired"))(n_distinct(df$Country))
    p <- ggplot(df, aes(x=std, y=reorder(Region,-std), fill=Country,
                        text=paste0(Region," (",Country,")<br>σ: ",round(std,3),
                                    "  |  Millésimes: ",ny))) +
      geom_col(width=.7) + facet_wrap(~g, scales="free_y") +
      scale_fill_manual(values=pal, name="Pays") +
      labs(title="Régions les plus stables vs les plus capricieuses",
           x="Écart-type de la note par année", y=NULL) + theme_bw()
    ggplotly(p, tooltip="text")
  })
  
  # ── Q12 — Heatmap météo ───────────────────────────────────────────────────
  
  output$q12_plot <- renderPlotly({
    df <- wines_f %>% filter(type %in% input$q12_types, !is.na(Rating))
    months <- c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
    inds   <- input$q12_inds
    if (length(inds)==0) inds <- c("tavg","tmin","tmax","prcp","tsun")
    ind_lab <- c(tavg="T moy.",tmin="T min.",tmax="T max.",prcp="Precip.",tsun="Ensoleil.")
    cols_ok <- names(df)[str_detect(names(df),
                                    paste0("^(",paste(months,collapse="|"),")_(",paste(inds,collapse="|"),")$"))]
    cor_v <- sapply(cols_ok, function(cn)
      cor(df[[cn]], df$Rating, use="pairwise.complete.obs"))
    cdf <- tibble(var=names(cor_v), r=cor_v) %>%
      mutate(month    = factor(str_extract(var,"^[A-Za-z]+"), levels=months),
             ind_key  = str_extract(var,"[a-z]+$"),
             indicator= factor(ind_lab[ind_key], levels=rev(unname(ind_lab)))) %>%
      filter(!is.na(month),!is.na(indicator))
    p <- ggplot(cdf, aes(x=month, y=indicator, fill=r,
                         text=paste0(month," - ",indicator,"<br>r = ",round(r,3)))) +
      geom_tile(color="white", linewidth=.5) +
      geom_text(aes(label=sprintf("%.2f",r)), size=2.9) +
      scale_fill_gradient2(low="#2166ac", mid="white", high="#d73027",
                           midpoint=0, limits=c(-.3,.3), name="r") +
      labs(title="Corrélations météo mensuelles vs note du vin",
           x="Mois", y="Indicateur") + theme_minimal(base_size=11) +
      theme(panel.grid=element_blank())
    ggplotly(p, tooltip="text")
  })
  
  # ── Q13 — Ensoleillement ──────────────────────────────────────────────────
  
  output$q13_plot <- renderPlotly({
    df <- wines_f %>%
      filter(type %in% input$q13_types,
             !is.na(Apr_tsun),!is.na(May_tsun),!is.na(Jun_tsun),
             !is.na(Jul_tsun),!is.na(Aug_tsun),!is.na(Sep_tsun)) %>%
      mutate(tsun_print=(Apr_tsun+May_tsun+Jun_tsun)/3,
             tsun_ete  =(Jul_tsun+Aug_tsun+Sep_tsun)/3) %>%
      pivot_longer(c(tsun_print,tsun_ete), names_to="saison", values_to="tsun") %>%
      mutate(saison=factor(saison,
                           levels=c("tsun_print","tsun_ete"),
                           labels=c("Printemps (avr-juin)","Été (jul-sep)")))
    p <- ggplot(df, aes(x=tsun, y=Rating, color=saison)) +
      geom_smooth(method="lm", se=TRUE, linewidth=1) +
      scale_color_manual(values=c("#2ca25f","#e6550d"), name="Saison") +
      facet_wrap(~type, ncol=2) +
      labs(title="Ensoleillement printanier vs estival et note du vin",
           x="Ensoleillement moyen (sec/jour)", y="Note") + theme_bw()
    ggplotly(p)
  })
  
  # ── Q14 — Précipitations été ──────────────────────────────────────────────
  
  output$q14_plot <- renderPlotly({
    df <- wines_f %>%
      filter(type %in% input$q14_types,
             !is.na(Jul_prcp),!is.na(Aug_prcp),!is.na(Sep_prcp)) %>%
      mutate(prcp_ete=Jul_prcp+Aug_prcp+Sep_prcp)
    p <- ggplot(df, aes(x=prcp_ete, y=Rating)) +
      geom_point(alpha=.12, size=.8, color="steelblue") +
      geom_smooth(method="loess", se=TRUE, color="black", linewidth=.9) +
      facet_wrap(~type, ncol=2, scales="free_x") +
      labs(title="Précipitations estivales et note du vin",
           x="Précipitations estivales (mm, juil-sept)", y="Note") + theme_bw()
    ggplotly(p)
  })
  
  # ── Q15 — Températures hiver ──────────────────────────────────────────────
  
  output$q15_plot <- renderPlotly({
    df <- wines_f %>%
      filter(type %in% input$q15_types,
             !is.na(Dec_tavg),!is.na(Jan_tavg),!is.na(Feb_tavg)) %>%
      mutate(tavg_hiv=(Dec_tavg+Jan_tavg+Feb_tavg)/3)
    p <- ggplot(df, aes(x=tavg_hiv, y=Rating)) +
      geom_point(alpha=.12, size=.8, color="steelblue") +
      geom_smooth(method="lm", se=TRUE, color="black", linewidth=.9) +
      facet_wrap(~type, ncol=2) +
      labs(title="Températures hivernales et note du vin",
           x="Température hivernale moyenne (°C)", y="Note") + theme_bw()
    ggplotly(p)
  })
  
  # ── Q16 — Réchauffement ───────────────────────────────────────────────────
  
  output$q16_plot <- renderPlotly({
    df <- wines %>%
      filter(!is.na(lat), lat>=input$q16_lat[1], lat<=input$q16_lat[2],
             Year>=input$q16_yr[1], Year<=input$q16_yr[2],
             !is.na(Jul_tavg),!is.na(Aug_tavg),!is.na(Sep_tavg)) %>%
      mutate(te=(Jul_tavg+Aug_tavg+Sep_tavg)/3) %>%
      group_by(Year) %>%
      summarise(m=mean(te,na.rm=TRUE), se=sd(te,na.rm=TRUE)/sqrt(n()), .groups="drop")
    p <- ggplot(df, aes(x=Year, y=m,
                        text=paste0("Année: ",Year,"<br>T°C: ",round(m,2)))) +
      geom_ribbon(aes(ymin=m-1.96*se, ymax=m+1.96*se), fill="#fc8d59", alpha=.3) +
      geom_line(color="#d73027", linewidth=1) + geom_point(color="#d73027", size=2.2) +
      scale_x_continuous(breaks=seq(input$q16_yr[1],input$q16_yr[2],2)) +
      labs(title="Évolution des températures estivales méditerranéennes",
           x="Année", y="Température estivale moyenne (°C)") + theme_bw()
    if (input$q16_tr)
      p <- p + geom_smooth(method="lm", se=FALSE, color="black",
                           linetype="dashed", linewidth=.8)
    ggplotly(p, tooltip="text")
  })
  
  # ── Q17 — Diversité géo ───────────────────────────────────────────────────
  
  output$q17_plot <- renderPlotly({
    td <- wines %>% filter(!is.na(type),!is.na(Country),!is.na(Region),!is.na(Price),Price>0) %>%
      group_by(type) %>%
      summarise(np=n_distinct(Country), nr=n_distinct(Region),
                pm=median(Price,na.rm=TRUE), .groups="drop")
    p1 <- ggplot(td, aes(x=np, y=nr, fill=type,
                         text=paste0(type,"<br>Pays: ",np,"<br>Régions: ",nr,"<br>Prix méd.: ",pm,"€"))) +
      geom_point(shape=21, size=14, alpha=.85) +
      geom_text(aes(label=type), size=3.2, vjust=-2.2, show.legend=FALSE) +
      scale_fill_manual(values=TYPE_COLS, guide="none") +
      labs(title="Diversité géographique", x="Nombre de pays", y="Nombre de régions") +
      theme_bw()
    p2 <- ggplot(td, aes(x=reorder(type,pm), y=pm, fill=type,
                         text=paste0(type,"<br>",pm,"€"))) +
      geom_col(width=.65) +
      geom_text(aes(label=paste0(round(pm),"€")), vjust=-.35, size=3.8) +
      scale_fill_manual(values=TYPE_COLS, guide="none") +
      labs(title="Prix médian par type", x=NULL, y="Prix médian (€)") + theme_bw()
    subplot(ggplotly(p1,tooltip="text"), ggplotly(p2,tooltip="text"),
            nrows=1, shareY=FALSE, titleX=TRUE)
  })
  
  # ── Q18 — Variabilité pays ────────────────────────────────────────────────
  
  output$q18_plot <- renderPlotly({
    df <- wines_f %>% filter(!is.na(Country)) %>%
      group_by(Country) %>%
      summarise(n=n(), m=mean(Rating,na.rm=TRUE), s=sd(Rating,na.rm=TRUE), .groups="drop") %>%
      filter(n>=input$q18_minw)
    df <- switch(input$q18_sort,
                 std_d = df %>% arrange(desc(s)),
                 std_a = df %>% arrange(s),
                 mean  = df %>% arrange(desc(m))
    )
    p <- ggplot(df, aes(x=s, y=reorder(Country,s), fill=m,
                        text=paste0(Country,"<br>σ: ",round(s,3),
                                    "<br>Moy.: ",round(m,2),"<br>N: ",n))) +
      geom_col(width=.7) +
      geom_text(aes(label=sprintf("moy=%.2f",m)), x=.005, hjust=0, size=2.8,
                color="white", fontface="bold") +
      scale_fill_gradientn(colours=c("#d73027","#fee08b","#1a9850"),
                           name="Note moy.", limits=c(3.5,4.3)) +
      labs(title="Variabilité interne des notes par pays",
           x="Écart-type des notes", y=NULL) + theme_bw()
    ggplotly(p, tooltip="text")
  })
  
  # ── Q19 — Régions pépites ─────────────────────────────────────────────────
  
  output$q19_plot <- renderPlotly({
    nat <- wines_f %>% filter(!is.na(Country),!is.na(Price),Price>0) %>%
      group_by(Country) %>%
      summarise(nm=mean(Rating,na.rm=TRUE), np=median(Price,na.rm=TRUE), .groups="drop")
    df <- wines_f %>%
      filter(!is.na(Region),!is.na(Country),!is.na(Price),Price>0) %>%
      group_by(Region,Country) %>%
      summarise(n=n(), mr=mean(Rating,na.rm=TRUE), mp=median(Price,na.rm=TRUE), .groups="drop") %>%
      filter(n>=input$q19_minw) %>%
      left_join(nat, by="Country") %>%
      mutate(en=mr-nm, ep=mp-np)
    pal <- colorRampPalette(brewer.pal(12,"Paired"))(n_distinct(df$Country))
    pep <- df %>% filter(en>0, ep<0) %>% slice_max(en, n=12)
    x_max <- max(df$en, na.rm=TRUE) * 1.1
    y_min <- min(df$ep, na.rm=TRUE) * 1.1
    p <- ggplot(df, aes(x=en, y=ep, color=Country,
                        text=paste0(Region," (",Country,")<br>Δnote: ",round(en,3),
                                    "<br>Δprix: ",round(ep,0),"€<br>N: ",n))) +
      annotate("rect", xmin=0, xmax=x_max, ymin=y_min, ymax=0, fill="#27ae60", alpha=.07) +
      geom_point(size=2.5, alpha=.65) +
      geom_text_repel(data=pep, aes(label=Region), size=2.7, show.legend=FALSE,
                      max.overlaps=20) +
      geom_vline(xintercept=0, linetype="dashed", color="grey40") +
      geom_hline(yintercept=0, linetype="dashed", color="grey40") +
      scale_color_manual(values=pal, name="Pays") +
      labs(title="Régions pépites : mieux notées ET moins chères que la moyenne nationale",
           subtitle="Zone verte = pépites",
           x="Écart à la note nationale moyenne", y="Écart au prix médian national (€)") +
      theme_bw()
    ggplotly(p, tooltip="text")
  })
  
  # ── Q20 — Stabilité climatique ────────────────────────────────────────────
  
  output$q20_plot <- renderPlotly({
    df <- wines_f %>%
      filter(!is.na(Region),!is.na(Year),
             !is.na(Jul_tavg),!is.na(Aug_tavg),!is.na(Sep_tavg)) %>%
      mutate(te=(Jul_tavg+Aug_tavg+Sep_tavg)/3) %>%
      group_by(Region,Year) %>%
      summarise(mr=mean(Rating,na.rm=TRUE), mt=mean(te,na.rm=TRUE), .groups="drop") %>%
      group_by(Region) %>%
      summarise(ny=n(), sr=sd(mr,na.rm=TRUE), st=sd(mt,na.rm=TRUE), .groups="drop") %>%
      filter(ny>=input$q20_miny) %>%
      left_join(wines %>% distinct(Region,Country) %>% group_by(Region) %>% slice(1),
                by="Region")
    pal <- colorRampPalette(brewer.pal(12,"Paired"))(n_distinct(df$Country))
    extremes <- df %>%
      filter(sr>quantile(sr,.88,na.rm=TRUE) | st>quantile(st,.88,na.rm=TRUE))
    p <- ggplot(df, aes(x=st, y=sr, color=Country,
                        text=paste0(Region," (",Country,")<br>σ climat: ",round(st,2),
                                    "<br>σ notes: ",round(sr,3),"<br>Millésimes: ",ny))) +
      geom_point(size=2.5, alpha=.7) +
      scale_color_manual(values=pal, name="Pays") +
      labs(title="Stabilité climatique vs régularité de production",
           x="Variabilité climatique (σ T° estivale, °C)",
           y="Variabilité de production (σ note annuelle)") + theme_bw()
    if (input$q20_tr) {
      # Calcul manuel de la droite de régression (évite le problème color hérité avec ggplotly)
      lm_fit  <- lm(sr ~ st, data=df)
      x_seq   <- seq(min(df$st, na.rm=TRUE), max(df$st, na.rm=TRUE), length.out=100)
      lm_pred <- predict(lm_fit, newdata=data.frame(st=x_seq),
                         interval="confidence", level=.95)
      lm_df   <- data.frame(st=x_seq, sr=lm_pred[,"fit"],
                            lo=lm_pred[,"lwr"], hi=lm_pred[,"upr"])
      p <- p +
        geom_ribbon(data=lm_df, aes(x=st, ymin=lo, ymax=hi),
                    fill="grey70", alpha=.35, inherit.aes=FALSE) +
        geom_line(data=lm_df, aes(x=st, y=sr),
                  color="black", linewidth=.9, inherit.aes=FALSE)
    }
    if (input$q20_lbl)
      p <- p + geom_text_repel(data=extremes, aes(label=Region),
                               size=2.6, max.overlaps=15, show.legend=FALSE)
    ggplotly(p, tooltip="text")
  })
  
  # ── DATA TABLE ─────────────────────────────────────────────────────────────
  
  output$dt_table <- renderDT({
    df <- wines %>%
      filter(type %in% input$dt_types,
             NumberOfRatings >= input$dt_minr,
             !is.na(Price), Price>=input$dt_price[1], Price<=input$dt_price[2],
             Rating>=input$dt_rate[1], Rating<=input$dt_rate[2]) %>%
      select(Name, Country, Region, Winery, Year, type, Rating, NumberOfRatings, Price) %>%
      rename(Nom=Name, Pays=Country, Région=Region, Producteur=Winery,
             Millésime=Year, Type=type, Note=Rating,
             `Nb évals`=NumberOfRatings, `Prix €`=Price)
    datatable(df,
              options=list(pageLength=15, scrollX=TRUE,
                           language=list(url="//cdn.datatables.net/plug-ins/1.10.11/i18n/French.json")),
              filter="top", rownames=FALSE
    ) %>% formatRound(c("Note","Prix €"), 2)
  })
  
  observeEvent(input$dt_reset, {
    updateCheckboxGroupInput(session,"dt_types",
                             selected=c("Red","White","Rose","Sparkling"))
    updateSliderInput(session,"dt_minr",  value=0)
    updateSliderInput(session,"dt_price", value=c(0,500))
    updateSliderInput(session,"dt_rate",  value=c(2.5,5.0))
  })
}