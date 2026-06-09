# ui.R — Vin & Météo : influence du climat sur la qualité des vins
# Samuel FANDIO NJIKAM, Samella LEUKOUO, Mohamed Mehdi TRABELSSI

library(shiny)
library(shinydashboard)
library(plotly)
library(leaflet)
library(DT)

# ── Helpers ──────────────────────────────────────────────────────────────────

abox <- function(txt) {
  tags$div(class = "analysis-box", tags$strong("Analyse :"), tags$br(), txt)
}

ctrl_box <- function(...) box(width = 3, status = "danger", solidHeader = FALSE, ...)

plot_box <- function(out_id, height = "500px", tabs = NULL) {
  if (is.null(tabs)) {
    box(width = 9, status = "danger", solidHeader = FALSE,
        plotlyOutput(out_id, height = height))
  } else {
    box(width = 9, status = "danger", solidHeader = FALSE, tabs)
  }
}

qtitle <- function(txt) {
  fluidRow(column(12,
    tags$div(class = "question-title", txt)
  ))
}

type_checks <- function(id, selected = c("Red","White","Rose","Sparkling")) {
  checkboxGroupInput(id, "Types de vin :",
    choices  = c("Red","White","Rose","Sparkling"),
    selected = selected)
}

# ── UI ───────────────────────────────────────────────────────────────────────

dashboardPage(
  skin = "red",

  dashboardHeader(
    title = tags$span("🍷 Vin & Météo"),
    titleWidth = 240
  ),

  dashboardSidebar(
    width = 240,
    sidebarMenu(id = "tabs",
      menuItem("Accueil",               tabName = "home",  icon = icon("home")),
      menuItem("Axe 1 — Distributions", icon = icon("chart-bar"),
        menuSubItem("Q1 — Distribution des notes", tabName = "q1",  icon = icon("angle-right")),
        menuSubItem("Q2 — Fiabilité des notes",    tabName = "q2",  icon = icon("angle-right"))
      ),
      menuItem("Axe 2 — Prix & Qualité", icon = icon("tag"),
        menuSubItem("Q3 — Prix vs Note",       tabName = "q3",  icon = icon("angle-right")),
        menuSubItem("Q4 — Top régions",        tabName = "q4",  icon = icon("angle-right")),
        menuSubItem("Q5 — Effet domaine",      tabName = "q5",  icon = icon("angle-right")),
        menuSubItem("Q6 — Prix & Popularité",  tabName = "q6",  icon = icon("angle-right"))
      ),
      menuItem("Axe 3 — Géographie", icon = icon("globe"),
        menuSubItem("Q7 — Pays : note vs prix",  tabName = "q7",  icon = icon("angle-right")),
        menuSubItem("Q8 — Rapport qualité/prix", tabName = "q8",  icon = icon("angle-right")),
        menuSubItem("Q9 — Latitude & qualité",   tabName = "q9",  icon = icon("angle-right"))
      ),
      menuItem("Axe 4 — Millésimes", icon = icon("calendar"),
        menuSubItem("Q10 — Évolution temporelle", tabName = "q10", icon = icon("angle-right")),
        menuSubItem("Q11 — Régularité régions",   tabName = "q11", icon = icon("angle-right"))
      ),
      menuItem("Axe 5 — Climat & Qualité", icon = icon("cloud-sun"),
        menuSubItem("Q12 — Heatmap météo",       tabName = "q12", icon = icon("angle-right")),
        menuSubItem("Q13 — Ensoleillement",      tabName = "q13", icon = icon("angle-right")),
        menuSubItem("Q14 — Précipitations été",  tabName = "q14", icon = icon("angle-right")),
        menuSubItem("Q15 — Températures hiver",  tabName = "q15", icon = icon("angle-right"))
      ),
      menuItem("Axe 6 — Évolution climat", icon = icon("temperature-high"),
        menuSubItem("Q16 — Réchauffement", tabName = "q16", icon = icon("angle-right"))
      ),
      menuItem("Axe 7 — Marché viticole", icon = icon("wine-bottle"),
        menuSubItem("Q17 — Diversité géo",    tabName = "q17", icon = icon("angle-right")),
        menuSubItem("Q18 — Variabilité pays", tabName = "q18", icon = icon("angle-right")),
        menuSubItem("Q19 — Régions pépites",  tabName = "q19", icon = icon("angle-right")),
        menuSubItem("Q20 — Stabilité climat", tabName = "q20", icon = icon("angle-right"))
      ),
      menuItem("Explorer les données", tabName = "data", icon = icon("table"))
    )
  ),

  dashboardBody(

    tags$head(tags$style(HTML("
      .skin-red .main-header .logo  { background-color:#7b0000!important; }
      .skin-red .main-header .navbar { background-color:#c0392b!important; }
      .skin-red .main-sidebar        { background-color:#1c1c1c; }
      .skin-red .main-sidebar .sidebar .sidebar-menu .active > a { background-color:#c0392b; }
      .content-wrapper, .right-side  { background-color:#f5f5f5; }
      .box.box-danger                { border-top-color:#c0392b; }
      .question-title {
        color:#c0392b; font-weight:700; font-size:17px;
        margin:0 0 12px 0; padding:0;
      }
      .analysis-box {
        background:#fff8f8; border-left:4px solid #c0392b;
        padding:10px 14px; border-radius:3px;
        font-size:13px; line-height:1.55; color:#333;
      }
      .home-card {
        background:#fff; border-left:4px solid #c0392b;
        padding:12px 14px; border-radius:4px;
        margin-bottom:8px;
      }
    "))),

    tabItems(

      # ── HOME ─────────────────────────────────────────────────────────────
      tabItem(tabName = "home",
        fluidRow(column(12,
          tags$div(
            style="background:linear-gradient(135deg,#7b0000,#c0392b);color:white;
                   padding:28px 30px;border-radius:8px;margin-bottom:18px;",
            tags$h1("🍷 Vin & Météo", style="margin:0;font-size:30px;"),
            tags$p("Influence du climat sur la qualité des vins",
                   style="margin:6px 0 0;font-size:15px;opacity:.9;"),
            tags$p("Samuel FANDIO NJIKAM · Samella LEUKOUO · Mohamed Mehdi TRABELSSI",
                   style="margin:4px 0 0;font-size:12px;opacity:.75;")
          )
        )),
        fluidRow(
          valueBoxOutput("vb_wines",    width = 3),
          valueBoxOutput("vb_countries",width = 3),
          valueBoxOutput("vb_regions",  width = 3),
          valueBoxOutput("vb_vars",     width = 3)
        ),
        fluidRow(
          box(title="Répartition par type", status="danger", solidHeader=TRUE,
              width=6, plotlyOutput("home_types",  height="260px")),
          box(title="Distribution des notes", status="danger", solidHeader=TRUE,
              width=6, plotlyOutput("home_ratings", height="260px"))
        ),
        fluidRow(
          box(title="Plan d'analyse — 7 axes, 20 questions", status="danger",
              solidHeader=TRUE, width=12,
              tags$div(style="display:flex;flex-wrap:wrap;gap:10px;",
                lapply(list(
                  list("Axe 1","Distributions & structure","Q1, Q2"),
                  list("Axe 2","Prix, popularité & qualité","Q3, Q4, Q5, Q6"),
                  list("Axe 3","Profil géographique","Q7, Q8, Q9"),
                  list("Axe 4","Millésimes & effet du temps","Q10, Q11"),
                  list("Axe 5","Climat & qualité","Q12, Q13, Q14, Q15"),
                  list("Axe 6","Évolution climatique","Q16"),
                  list("Axe 7","Structure du marché","Q17, Q18, Q19, Q20")
                ), function(x) {
                  tags$div(class="home-card", style="flex:1;min-width:140px;",
                    tags$strong(x[[1]], style="color:#c0392b;"), tags$br(),
                    tags$span(x[[2]], style="font-size:12px;color:#555;"), tags$br(),
                    tags$span(x[[3]], style="font-size:11px;color:#999;")
                  )
                })
              )
          )
        )
      ),

      # ── Q1 ───────────────────────────────────────────────────────────────
      tabItem(tabName = "q1",
        qtitle("Q1 — Comment se distribuent les notes des vins selon le type ?"),
        fluidRow(
          ctrl_box(
            type_checks("q1_types"),
            checkboxInput("q1_bxp",    "Afficher la boxplot",  value = TRUE),
            checkboxInput("q1_filter", "Filtre ≥ 100 avis",    value = FALSE),
            hr(), abox("Les médianes vont de 3,75 (rosés) à 4,10 (effervescents).
              Les effervescents se démarquent clairement vers le haut.
              Les rouges se positionnent légèrement au-dessus des blancs et rosés,
              ces trois types partageant des queues basses similaires.")
          ),
          plot_box("q1_plot", "520px")
        )
      ),

      # ── Q2 ───────────────────────────────────────────────────────────────
      tabItem(tabName = "q2",
        qtitle("Q2 — Le nombre d'évaluations est-il suffisant pour que les notes soient fiables ?"),
        fluidRow(
          ctrl_box(
            sliderInput("q2_thresh", "Seuil à mettre en évidence :",
                        min=25, max=500, value=100, step=25),
            type_checks("q2_types"),
            hr(), abox("En dessous de 100 avis, la dispersion est trop élevée.
              À partir de ce seuil les distributions convergent.
              Les vins très médiatisés (1000+) polarisent davantage les opinions.")
          ),
          plot_box("q2_plot", "500px")
        )
      ),

      # ── Q3 ───────────────────────────────────────────────────────────────
      tabItem(tabName = "q3",
        qtitle("Q3 — Existe-t-il une corrélation entre le prix et la note ?"),
        fluidRow(
          ctrl_box(
            type_checks("q3_types"),
            checkboxInput("q3_reg",    "Droite de régression", value = TRUE),
            checkboxInput("q3_filter", "Filtre ≥ 100 avis",   value = TRUE),
            hr(), uiOutput("q3_cors"),
            hr(), abox("Les effervescents ont la corrélation prix-note la plus forte,
              avec un nuage serré autour de la droite.
              Les blancs présentent la relation la plus dispersée.
              L'hypothèse 'cher = bon' se vérifie partout, avec une intensité variable.")
          ),
          plot_box("q3_plot", "500px")
        )
      ),

      # ── Q4 ───────────────────────────────────────────────────────────────
      tabItem(tabName = "q4",
        qtitle("Q4 — Quelles régions viticoles produisent les vins les mieux notés en moyenne ?"),
        fluidRow(
          ctrl_box(
            sliderInput("q4_n",    "Nombre de régions :", min=5,  max=30, value=20, step=5),
            sliderInput("q4_minw", "Min. vins / région :", min=5, max=50, value=20, step=5),
            hr(), abox("La France domine (9 régions dans le top 20) devant l'Italie (7).
              Les terroirs d'Europe occidentale prédominent dans la perception internationale
              de la qualité viticole.")
          ),
          plot_box("q4_plot", "560px")
        )
      ),

      # ── Q5 ───────────────────────────────────────────────────────────────
      tabItem(tabName = "q5",
        qtitle("Q5 — Certains producteurs se distinguent-ils par une note systématiquement supérieure ?"),
        fluidRow(
          ctrl_box(
            sliderInput("q5_minw", "Min. vins / producteur :", min=5, max=30, value=10, step=5),
            sliderInput("q5_n",    "Nb de producteurs :",     min=10, max=30, value=20, step=5),
            type_checks("q5_types"),
            hr(), abox("La majorité des intervalles de confiance excluent zéro :
              la surperformance n'est pas due au hasard.
              L'effet domaine existe — le savoir-faire du vigneron fait une vraie différence.")
          ),
          plot_box("q5_plot", "560px")
        )
      ),

      # ── Q6 ───────────────────────────────────────────────────────────────
      tabItem(tabName = "q6",
        qtitle("Q6 — Les vins chers sont-ils aussi les plus populaires ?"),
        fluidRow(
          ctrl_box(
            type_checks("q6_types"),
            sliderInput("q6_minr", "Min. évaluations :", min=25, max=200, value=25, step=25),
            hr(), abox("Les volumes les plus élevés se concentrent sur les vins les moins chers.
              Les vins chers restent peu évalués mais mieux notés (teinte verte) :
              logique de prestige confidentiel.")
          ),
          plot_box("q6_plot", "500px")
        )
      ),

      # ── Q7 ───────────────────────────────────────────────────────────────
      tabItem(tabName = "q7",
        qtitle("Q7 — Quels pays produisent les vins les mieux notés, et à quel prix ?"),
        fluidRow(
          ctrl_box(
            sliderInput("q7_minw",  "Min. vins / pays :", min=50, max=300, value=100, step=50),
            checkboxInput("q7_lbl", "Afficher les étiquettes", value=TRUE),
            hr(), abox("La France partage la même note médiane (3,90) avec Portugal, Allemagne,
              Italie et États-Unis. Sa distinction est uniquement par les prix.
              Portugal et Espagne sont les vrais champions du rapport qualité/prix.")
          ),
          plot_box("q7_plot", "500px")
        )
      ),

      # ── Q8 ───────────────────────────────────────────────────────────────
      tabItem(tabName = "q8",
        qtitle("Q8 — Quel type de vin offre le meilleur rapport qualité/prix ?"),
        fluidRow(
          ctrl_box(
            sliderInput("q8_nc",  "Nombre de pays :", min=5, max=12, value=8, step=1),
            checkboxInput("q8_eb","Barres d'erreur IC 95%", value=TRUE),
            hr(), abox("Les rosés offrent le meilleur rapport qualité/prix, suivis des blancs.
              Les effervescents arrivent derniers malgré leurs bonnes notes :
              leur prix élevé pénalise fortement leur ratio.
              Espagne et Chili dominent par pays, France dernière.")
          ),
          plot_box("q8_plot", "500px")
        )
      ),

      # ── Q9 ───────────────────────────────────────────────────────────────
      tabItem(tabName = "q9",
        qtitle("Q9 — La latitude d'une région viticole influence-t-elle la qualité de ses vins ?"),
        fluidRow(
          ctrl_box(
            sliderInput("q9_minw",  "Min. vins / région :", min=5, max=30, value=10, step=5),
            checkboxInput("q9_reg", "Droite de tendance", value=TRUE),
            hr(), abox("Concentration des régions les mieux notées en Europe occidentale.
              Tendance positive latitude-note, mais faible et dispersée.
              La latitude est un facteur structurel mais pas déterminant à elle seule.")
          ),
          box(width=9, status="danger",
            tabsetPanel(
              tabPanel("🗺 Carte mondiale",
                       leafletOutput("q9_map", height="460px")),
              tabPanel("📈 Latitude vs Note",
                       plotlyOutput("q9_scat", height="460px"))
            )
          )
        )
      ),

      # ── Q10 ──────────────────────────────────────────────────────────────
      tabItem(tabName = "q10",
        qtitle("Q10 — La note moyenne des vins a-t-elle évolué sur la période 2005-2019 ?"),
        fluidRow(
          ctrl_box(
            sliderInput("q10_yr", "Période :", min=2005, max=2019,
                        value=c(2005,2019), step=1, sep=""),
            type_checks("q10_types"),
            checkboxInput("q10_rib", "Bande de confiance", value=TRUE),
            hr(), abox("Les rouges montrent une baisse continue et solide sur toute la période.
              Les effervescents suivent la même direction.
              Seuls les blancs paraissent relativement stables.
              Probable biais de maturité des millésimes.")
          ),
          plot_box("q10_plot", "500px")
        )
      ),

      # ── Q11 ──────────────────────────────────────────────────────────────
      tabItem(tabName = "q11",
        qtitle("Q11 — Certaines régions viticoles sont-elles plus régulières que d'autres ?"),
        fluidRow(
          ctrl_box(
            sliderInput("q11_n",    "Nb de régions :",       min=5,  max=20, value=15, step=5),
            sliderInput("q11_miny", "Min. millésimes :",     min=3,  max=10, value=5,  step=1),
            hr(), abox("Les régions stables varient de moins de 0,1 point par an,
              les plus capricieuses jusqu'à 0,5 point.
              La France représente près de la moitié des 15 régions les plus stables,
              talonnée par l'Italie.")
          ),
          plot_box("q11_plot", "560px")
        )
      ),

      # ── Q12 ──────────────────────────────────────────────────────────────
      tabItem(tabName = "q12",
        qtitle("Q12 — Quels mois et quels indicateurs météo sont les plus associés à la note ?"),
        fluidRow(
          ctrl_box(
            type_checks("q12_types"),
            checkboxGroupInput("q12_inds", "Indicateurs :",
              choices  = c("T moy."="tavg","T min."="tmin","T max."="tmax",
                           "Précipitations"="prcp","Ensoleillement"="tsun"),
              selected = c("tavg","tmin","tmax","prcp","tsun")),
            hr(), abox("L'ensoleillement estival (juin-août) est le plus positivement corrélé
              (r = 0,14 en juillet). Les précipitations estivales sont quasi nulles.
              Les variables hivernales sont négativement corrélées :
              hivers froids = meilleures notes.")
          ),
          plot_box("q12_plot", "440px")
        )
      ),

      # ── Q13 ──────────────────────────────────────────────────────────────
      tabItem(tabName = "q13",
        qtitle("Q13 — L'ensoleillement estival prédit-il mieux la note que le printanier ?"),
        fluidRow(
          ctrl_box(
            type_checks("q13_types"),
            hr(), abox("Printemps et été se comportent de façon très similaire pour trois
              types sur quatre. Seuls les rosés montrent une différence visible mais avec
              un large intervalle de confiance.
              Les effervescents sont les plus sensibles à l'ensoleillement,
              les blancs quasi insensibles.")
          ),
          plot_box("q13_plot", "500px")
        )
      ),

      # ── Q14 ──────────────────────────────────────────────────────────────
      tabItem(tabName = "q14",
        qtitle("Q14 — Les précipitations estivales ont-elles un effet négatif sur la note ?"),
        fluidRow(
          ctrl_box(
            type_checks("q14_types"),
            hr(), abox("Les blancs montrent la relation négative la plus nette et continue.
              Les effervescents ont un profil non-linéaire : note stable jusqu'à 5mm
              puis chute claire. Les rouges et rosés sont largement insensibles.")
          ),
          plot_box("q14_plot", "500px")
        )
      ),

      # ── Q15 ──────────────────────────────────────────────────────────────
      tabItem(tabName = "q15",
        qtitle("Q15 — Une température hivernale plus froide est-elle associée à de meilleures notes ?"),
        fluidRow(
          ctrl_box(
            type_checks("q15_types"),
            hr(), abox("Tous les types montrent une pente négative : hivers plus froids = meilleures notes.
              Effet le plus marqué pour les rouges et les blancs.
              Cohérent avec le rôle agronomique de la dormance hivernale.")
          ),
          plot_box("q15_plot", "500px")
        )
      ),

      # ── Q16 ──────────────────────────────────────────────────────────────
      tabItem(tabName = "q16",
        qtitle("Q16 — Le réchauffement climatique est-il visible dans les régions méditerranéennes ?"),
        fluidRow(
          ctrl_box(
            sliderInput("q16_lat", "Latitude (°N) :", min=28, max=52,
                        value=c(35,45), step=1),
            sliderInput("q16_yr",  "Période :", min=2005, max=2019,
                        value=c(2005,2019), step=1, sep=""),
            checkboxInput("q16_tr", "Droite de tendance", value=TRUE),
            hr(), abox("Hausse progressive d'environ +1,5°C sur 15 ans dans les régions
              méditerranéennes. Signal cohérent avec les données scientifiques sur
              le réchauffement en zone méditerranéenne, validant la cohérence du dataset.")
          ),
          plot_box("q16_plot", "500px")
        )
      ),

      # ── Q17 ──────────────────────────────────────────────────────────────
      tabItem(tabName = "q17",
        qtitle("Q17 — Quel est le profil de diversité géographique de chaque type de vin ?"),
        fluidRow(
          ctrl_box(
            hr(), abox("Les rouges dominent (30 pays, 630 régions).
              Les effervescents sont les plus concentrés géographiquement mais affichent
              le prix médian le plus élevé (35€) : la niche géographique permet un
              positionnement premium. Rosés et effervescents ont le même profil géo
              mais divergent fortement sur le prix.")
          ),
          plot_box("q17_plot", "500px")
        )
      ),

      # ── Q18 ──────────────────────────────────────────────────────────────
      tabItem(tabName = "q18",
        qtitle("Q18 — La variabilité des notes au sein d'un pays révèle-t-elle une hétérogénéité de production ?"),
        fluidRow(
          ctrl_box(
            sliderInput("q18_minw", "Min. vins / pays :", min=50, max=300, value=100, step=50),
            radioButtons("q18_sort", "Trier par :",
              choices = c("Dispersion décr." = "std_d",
                          "Dispersion croiss."= "std_a",
                          "Note moyenne"     = "mean"),
              selected = "std_d"),
            hr(), abox("Les pays du Nouveau Monde (Argentine, États-Unis, Chili, Australie)
              sont les plus dispersés : production à deux vitesses.
              Les pays européens combinent dispersion plus faible et notes plus élevées :
              production homogène vers le haut.")
          ),
          plot_box("q18_plot", "500px")
        )
      ),

      # ── Q19 ──────────────────────────────────────────────────────────────
      tabItem(tabName = "q19",
        qtitle("Q19 — Quelles régions surperforment en note tout en restant moins chères que la moyenne ?"),
        fluidRow(
          ctrl_box(
            sliderInput("q19_minw", "Min. vins / région :", min=5, max=30, value=15, step=5),
            hr(), abox("Pépites identifiées : Gigondas (France), Salento et Primitivo di Manduria
              (Italie), Toro et Rías Baixas (Espagne), Mosel (Allemagne),
              Robertson (Afrique du Sud). Ces opportunités ne sont pas l'apanage
              d'une seule région du monde.")
          ),
          plot_box("q19_plot", "560px")
        )
      ),

      # ── Q20 ──────────────────────────────────────────────────────────────
      tabItem(tabName = "q20",
        qtitle("Q20 — Le profil climatique permet-il de prédire la régularité de production ?"),
        fluidRow(
          ctrl_box(
            sliderInput("q20_miny",  "Min. millésimes :", min=3, max=10, value=5, step=1),
            checkboxInput("q20_tr",  "Droite de tendance",      value=TRUE),
            checkboxInput("q20_lbl", "Étiquettes cas extrêmes", value=TRUE),
            hr(), abox("La relation est quasi inexistante : droite de régression horizontale.
              Le savoir-faire viticole compense largement les aléas climatiques.
              Le climat influence la qualité, mais ne détermine pas la régularité,
              qui reste avant tout une affaire humaine.")
          ),
          plot_box("q20_plot", "500px")
        )
      ),

      # ── DATA ─────────────────────────────────────────────────────────────
      tabItem(tabName = "data",
        fluidRow(column(12,
          tags$div(class="question-title", "Explorer les données brutes")
        )),
        fluidRow(
          box(width=3, status="danger",
            type_checks("dt_types"),
            sliderInput("dt_minr",  "Min. évaluations :",   min=0,   max=500, value=0,        step=25),
            sliderInput("dt_price", "Gamme de prix (€) :",  min=0,   max=500, value=c(0,500), step=10),
            sliderInput("dt_rate",  "Note :",               min=2.5, max=5.0, value=c(2.5,5), step=0.1),
            actionButton("dt_reset","Réinitialiser", icon=icon("undo"),
                         style="background:#c0392b;color:white;border:none;width:100%;margin-top:6px;")
          ),
          box(width=9, status="danger", DTOutput("dt_table"))
        )
      )
    )
  )
)
