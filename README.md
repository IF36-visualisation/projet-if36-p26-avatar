# Vin & Météo : l'influence du climat sur la qualité des vins

> *"Le vin est le reflet du ciel, de la terre et du travail des hommes."*

## Membres

| L'équipe Avatar         |
| --------------------    |
| Samuel FANDIO NJIKAM    |
| Samella LEUKOUO         |  
| Fanta DEMBELE           |
| Mohamed Mehdi TRABELSSI |

---

## Sommaire

- [Introduction](#introduction)
  - [Données](#données)
  - [Plan d'analyse](#plan-danalyse)

## Introduction

### Données

Notre jeu de données est issu de la plateforme **Kaggle** : [Wine Growth Weather](https://www.kaggle.com/datasets/abcd334/wine-growth-weather/), constitué par Anton Budnyak (2020) et enrichi de données météorologiques issues de [Open-Meteo.com](https://open-meteo.com/).

Le vin est un produit intimement lié aux conditions climatiques de sa région de production. La vigne est particulièrement sensible aux variations de température, d'ensoleillement et de précipitations durant la saison de croissance. Ce dataset a précisément été conçu pour explorer cette relation : les données météorologiques correspondent à l'**année précédant la production du vin**, ce qui nous permet d'évaluer l'impact du climat sur la note et la qualité perçue du vin.

Nous avons choisi ce sujet car il croise deux domaines riches en données : l'**œnologie** et la **climatologie**. Il offre une problématique centrale claire et engageante : *les conditions météorologiques durant la saison de croissance des raisins permettent-elles de prédire la qualité d'un vin ?*

**Le dataset**

Les données se présentent initialement sous la forme de **4 fichiers CSV**, un par type de vin. Nous les avons fusionnés en un dataset unique après nettoyage, en ajoutant une colonne `type` pour distinguer les catégories.

| Type de vin | Observations |
|-------------|-------------|
| Rouge (*Red*) | 8 658 |
| Blanc (*White*) | 3 759 |
| Rosé (*Rose*) | 394 |
| Effervescent (*Sparkling*) | 279 |
| **Total fusionné** | **13 090** |

Le dataset final comporte **71 variables** et **13 090 observations**, réparties sur des vins produits entre **1961 et 2020**, dans **30 pays** et **plus de 1 200 régions viticoles**.

Les variables se regroupent en quatre grandes familles :

*Informations sur le vin (6 variables)*

| Variable | Type | Description |
|----------|------|-------------|
| `Name` | `character` | Nom du vin |
| `Country` | `character` | Pays de production |
| `Region` | `character` | Région viticole |
| `Winery` | `character` | Nom du domaine / producteur |
| `Year` | `integer` | Millésime du vin |
| `type` | `factor` | Type de vin (Red, White, Rose, Sparkling) |

*Métriques commerciales et de notation (3 variables)*

| Variable | Type | Description |
|----------|------|-------------|
| `Rating` | `double` | Note moyenne des utilisateurs (2.5 – 4.9) |
| `NumberOfRatings` | `integer` | Nombre d'évaluations reçues |
| `Price` | `double` | Prix en euros (3.55 – 3 410 €) |

*Géolocalisation (2 variables)*

| Variable | Type | Description |
|----------|------|-------------|
| `lat` | `double` | Latitude de la région de production |
| `lng` | `double` | Longitude de la région de production |

*Données météorologiques mensuelles (60 variables)*

Pour chacun des **12 mois** (Jan à Dec), 5 indicateurs climatiques sont renseignés, soit **60 colonnes** de la forme `Mois_indicateur` :

| Suffixe | Type | Description |
|---------|------|-------------|
| `_tavg` | `double` | Température moyenne (°C) |
| `_tmin` | `double` | Température minimale (°C) |
| `_tmax` | `double` | Température maximale (°C) |
| `_prcp` | `double` | Précipitations (mm) |
| `_tsun` | `double` | Durée d'ensoleillement (secondes, seuil > 120 W/m²) |

**Sous-groupes notables**

- **Par type** : 4 catégories de vins aux profils très différents en termes de volume, de région et de prix
- **Par pays** : 30 pays représentés, avec une forte dominance de la France, de l'Italie et de l'Espagne
- **Par millésime** : des vins de 1961 à 2020, pour une analyse temporelle
- **Par gamme de prix** : distribution très asymétrique, de vins d'entrée de gamme à des bouteilles d'exception

---

### Plan d'analyse

Notre analyse s'articule autour de **7 axes indépendants**, progressant du descriptif vers l'analytique et l'explicatif. Chaque question est conçue pour éclairer un aspect distinct du dataset, avec des variables, des graphiques et une approche propres.

#### Axe 1 — Distributions et structure

##### Q1 — Comment se distribuent les notes des vins, et cette distribution varie-t-elle selon le type ?

**Objectif :** Établir un portrait de base de la variable cible (`Rating`) avant toute analyse explicative. Il s'agit de comprendre si les notes sont concentrées sur une plage étroite ou bien réparties, et si les 4 types de vins présentent des profils de notation distincts.

**Variables :** `Rating`, `type`

**Graphique :** Violin plot + boxplot superposés, un par type de vin

**Approche :** On représente côte à côte les 4 distributions de `Rating` par type. Le violin plot révèle la forme complète de la distribution (asymétrie, multi-modalité), tandis que la boxplot superposée permet de lire rapidement la médiane et les quartiles. On cherchera en particulier si les effervescents ont une distribution décalée vers le haut, ou si les rosés sont plus concentrés autour d'une note moyenne.

##### Q2 — Le nombre d'évaluations est-il suffisant pour que les notes soient fiables ?

**Objectif :** Identifier un biais potentiel majeur : une note de 4.5 basée sur 30 avis est très différente d'une note de 4.5 basée sur 2 000 avis. Cette question définit un seuil de fiabilité que nous appliquerons comme filtre dans les analyses suivantes.

**Variables :** `NumberOfRatings`, `Rating`, `type`

**Graphique :** Boxplot des distributions de Rating par tranche de nombre d'avis (25–49, 50–99, 100–199, 200–499, 500–999, 1 000+)

**Approche :** On regroupe les vins en tranches croissantes de nombre d'avis et on compare la dispersion des notes (hauteur des boîtes, étendue des moustaches) entre tranches. Si les tranches basses présentent une dispersion nettement plus forte que les tranches hautes, cela confirme leur manque de fiabilité statistique. On identifie visuellement le seuil à partir duquel la dispersion se stabilise — ce seuil sera appliqué comme filtre dans les axes suivants pour garantir des comparaisons robustes.

---

#### Axe 2 — Prix, popularité et qualité

##### Q3 — Existe-t-il une corrélation entre le prix et la note, et est-elle uniforme entre les types de vins ?

**Objectif :** Tester l'hypothèse commune selon laquelle "plus un vin est cher, mieux il est noté". Cette relation est loin d'être garantie et peut varier fortement selon le type : un effervescent cher est souvent un Champagne de prestige, tandis qu'un rouge très cher peut être une bouteille de collection rarement consommée.

**Variables :** `Price`, `Rating`, `type`

**Graphique :** Scatter plot avec axe `Price` en échelle logarithmique et droite de régression par type (`geom_smooth`), facetté par `type`

**Approche :** On applique une transformation logarithmique sur `Price` pour corriger la forte asymétrie de cette variable (quelques bouteilles très chères écrasent l'axe). On trace une droite de régression par type pour comparer les pentes : une pente positive et significative valide l'hypothèse pour ce type. On s'attend à des comportements différents entre rosés (gamme de prix serrée) et rouges (gamme très large).

##### Q4 — Quelles régions viticoles produisent les vins les mieux notés en moyenne ?

**Objectif :** Identifier les *terroirs* d'excellence dans les données, indépendamment du prix. Une région peut produire des vins très bien notés à prix modéré, ou inversement des vins chers mais ordinaires.

**Variables :** `Region`, `Country`, `Rating`, `NumberOfRatings`

**Graphique :** Bar chart horizontal des 20 régions avec la note moyenne la plus élevée, filtré sur les régions comptant au moins 30 vins évalués, coloré par `Country`

**Approche :** On agrège le dataset par région pour calculer la note moyenne et le nombre de vins. On filtre les régions avec trop peu d'observations (seuil défini à partir de Q2) pour éviter les régions anecdotiques. Le bar chart horizontal permet de lire facilement les noms de régions souvent longs, et la couleur par pays révèle si les meilleures régions sont concentrées dans un même pays ou dispersées géographiquement.

##### Q5 — Certains producteurs se distinguent-ils par une note systématiquement supérieure à celle de leur région ?
 
**Objectif :** Mesurer l'effet *domaine* sur la qualité, c'est-à-dire la part de la note qui s'explique par le savoir-faire du producteur plutôt que par son terroir. Une région peut afficher une note moyenne élevée simplement parce qu'un ou deux grands domaines tirent la moyenne vers le haut — cette question permet de détecter ce phénomène et de distinguer l'excellence d'un terroir de celle d'un producteur.
 
**Variables :** `Winery`, `Region`, `Rating`, `type`
 
**Graphique :** Dot plot des 20 producteurs dont l'écart entre leur note moyenne et la note moyenne de leur région est le plus élevé, coloré par `type`, avec barres d'erreur représentant l'intervalle de confiance
 
**Approche :** Pour chaque vin, on calcule l'écart entre sa note et la note moyenne de sa région (`Rating - mean_rating_region`). On agrège ensuite par `Winery` pour obtenir l'écart moyen par producteur, filtré sur ceux ayant au moins 10 vins notés. Un écart positif élevé indique un producteur qui surperforme structurellement son terroir. Le dot plot avec intervalles de confiance permet de distinguer les producteurs dont la surperformance est statistiquement solide de ceux dont l'écart est dû à un trop faible nombre d'observations.

##### Q6 — Les vins chers sont-ils aussi les plus populaires, et cette relation se reflète-t-elle dans la note ?
 
**Objectif :** Explorer la relation entre positionnement tarifaire (`Price`) et popularité (`NumberOfRatings`), puis observer comment la note se distribue dans ces deux dimensions.
 
**Variables :** `Price`, `NumberOfRating`, `Rating`, `type`
 
**Graphique :** Scatter plot `log(Price)` vs `log(NumberOfRatings)`, coloré par `Rating`, avec lignes médianes délimitant 4 quadrants, facetté par `type`
 
**Approche :** On applique des transformations logarithmiques sur les deux axes.

---

#### Axe 3 — Profil géographique et comparaison internationale
 
##### Q7 — Quels pays produisent les vins les mieux notés, et à quel prix ?
 
**Objectif :** Comparer les grands pays producteurs (12 pays avec ≥ 100 vins) sur leur positionnement simultané en note et en prix. Cette question adopte une granularité nationale, qui revèle des stratégies de marché différentes : la France produit cher (médiane 27€) là où le Portugal produit abordable (11€) pour des notes similaires.
 
**Variables :** `Country`, `Rating`, `Price`, `type`
 
**Graphique :** Scatter plot des pays (`price_med` en x, `rating_med` en y), avec des points dimensionnés par nombre de vins et colorés par continent, avec annotation des noms de pays
 
**Approche :** On agrège par pays (filtre ≥ 100 vins, 12 pays exploitables). Chaque pays devient un point sur le graphique prix/note. On identifiera les pays à fort rapport qualité/prix (Portugal, Espagne, Chili) vs. les pays premium (France, États-Unis).
 
##### Q8 — Quel type de vin offre le meilleur rapport qualité/prix, et dans quels pays ce rapport est-il le plus favorable ?
 
**Objectif :** Construire un indicateur synthétique de rapport qualité/prix (`Rating / log(Price)`) pour comparer les types de vins et les pays de production sur une dimension unique. Question qui combine prix et note en un seul score et le compare entre groupes.
 
**Variables :** `Rating`, `Price`, `type`, `Country`
 
**Graphique :** Bar chart double : d'abord par `type`, puis par `Country` (top 8 pays), ce qui montrerait le score qualité/prix moyen avec barres d'erreur
 
**Approche :** On construit `qp_ratio = Rating / log(Price + 1)` (qp = qualité_prix).
 
##### Q9 — La latitude d'une région viticole influence-t-elle la qualité structurelle de ses vins ?
 
**Objectif :** Explorer si la position géographique d'une région (qui détermine structurellement son ensoleillement et ses températures moyennes) est associée à la qualité moyenne des vins produits, indépendamment des variations annuelles.
 
**Variables :** `lat`, `lng`, `Rating`, `Country`, `type`
 
**Graphique :** Carte géographique (`ggplot2` + `geom_point`) où chaque région est positionnée par `lat`/`lng`, colorée par note moyenne et dimensionnée par nombre de vins ; complétée d'un scatter plot `lat` vs `Rating` avec droite de régression
 
**Approche :** On agrège les données par région pour obtenir la note moyenne et le nombre de vins. On projette chaque région sur une carte du monde pour révéler des patterns spatiaux visuels. Le scatter plot complémentaire `lat` vs `Rating` quantifie la tendance. On contrôle par `type` pour isoler l'effet de la latitude de celui du type de vin produit dans chaque zone.
 
---

#### Axe 4 — Millésimes et effet du temps

##### Q10 — La note moyenne des vins a-t-elle évolué sur la période (2005–2019), et ce phénomène est-il homogène entre les types ?

**Objectif :** Observer si la qualité perçue des vins, mesurée par leur note moyenne, évolue au fil des millésimes récents. Et la tendance d'évolution est partagée par tous les types de vins ou si certains se distinguent.

**Variables :** `Year`, `Rating`, `type`

**Graphique :** Line chart de la note moyenne par millésime (2005–2019) avec bande de confiance (`geom_ribbon`), facetté par `type`

**Approche :** On agrège les notes par année et par type sur la période 2005–2019. On trace l'évolution avec une bande de confiance proportionnelle au nombre d'observations. On compare les pentes entre types pour voir si certains résistent mieux à cette tendance que d'autres.

##### Q11 — Certaines régions viticoles sont-elles plus régulières que d'autres d'une année à l'autre ?
 
**Objectif :** Comparer les régions non plus sur leur note moyenne (comme en Q4) mais sur leur *régularité* : une région peut être excellente en moyenne mais capricieuse selon les millésimes, tandis qu'une autre produit des vins d'une qualité constante. 
 
**Variables :** `Region`, `Year`, `Rating`, `Country` — variable construite : `std_rating_region`
 
**Graphique :** Bar chart des 15 régions les plus stables vs les 15 plus capricieuses (classées par `std_rating_region`), coloré par `Country`
 
**Approche :** On filtre les régions ayant ≥ 5 millésimes distincts. Pour chaque région, on calcule l'écart-type des notes par année. Le bar chart comparatif révèle quelles régions (et quels pays) produisent les vins les plus prévisibles vs. les plus variables d'une année à l'autre.

---

#### Axe 5 — Climat et qualité : le cœur de la problématique

##### Q12 — Sur l'ensemble du calendrier climatique annuel, quels mois et quels indicateurs météo sont les plus associés à la note du vin ?

**Objectif :** Dresser une cartographie complète et sans a priori des corrélations entre les 60 variables météo mensuelles et la note du vin. L'objectif est exploratoire : plutôt que de tester une hypothèse précise, on laisse les données révéler quelles périodes de l'année climatique (pas nécessairement l'été) et quels indicateurs (température, ensoleillement, précipitations) sont les plus liés à la qualité perçue. Cette question sert de boussole pour les analyses suivantes.

**Variables :** `Rating` et les 60 variables météo mensuelles (`Jan_tavg` à `Dec_tsun`)

**Graphique :** Heatmap de corrélation, avec les 12 mois sur l'axe x et les 5 indicateurs météo (`tavg`, `tmin`, `tmax`, `prcp`, `tsun`) sur l'axe y, la couleur encodant le coefficient de corrélation de Pearson avec `Rating`

**Approche :** On calcule le coefficient de corrélation de Pearson entre `Rating` et chacune des 60 variables météo. La heatmap permet de visualiser en un coup d'œil les zones de corrélation forte et faible sur l'ensemble du calendrier. On laisse les résultats guider l'interprétation plutôt que de confirmer une hypothèse préétablie.

##### Q13 — L'ensoleillement estival prédit-il mieux la note que l'ensoleillement printanier, et cet effet varie-t-il selon le type de vin ?

**Objectif :** Comparer le pouvoir prédictif de deux périodes climatiques distinctes (le printemps (floraison de la vigne, avril-juin) et l'été (maturation des raisins, juillet-septembre)) sur la note finale. 

**Variables :** `Apr_tsun`, `May_tsun`, `Jun_tsun`, `Jul_tsun`, `Aug_tsun`, `Sep_tsun`, `Rating`, `type`

**Graphique :** Scatter plot facetté par `type` avec deux courbes `geom_smooth` superposées — une pour `tsun_print` (printemps) et une pour `tsun_ete` (été) — colorées différemment

**Approche :** On construit `tsun_print` (moyenne avril-juin) et `tsun_ete` (moyenne juillet-septembre). On trace les deux relations sur le même graphique par type. La comparaison des pentes révèle quelle période compte le plus pour chaque type de vin. Les effervescents devraient montrer un printemps plus déterminant, contrairement aux rouges.

##### Q14 — Les précipitations estivales ont-elles un effet négatif sur la note des vins effervescents, et comment cet effet se compare-t-il aux autres types ?

**Objectif :** Examiner si les précipitations estivales influencent différemment la note selon le type de vin. Les vins effervescents, issus majoritairement de régions fraîches (Champagne, Crémant, Cava), sont réputés particulièrement sensibles à l'excès d'humidité qui nuit à la concentration des arômes. Cette question analyse un mécanisme différent (l'excès d'eau) et permet de comparer la sensibilité aux précipitations entre les 4 types de vins.

**Variables :** `Jul_prcp`, `Aug_prcp`, `Sep_prcp`, `Rating`, `type`

**Graphique :** Scatter plot `prcp_ete` vs `Rating` avec `geom_smooth` (méthode *loess*), facetté par `type`, pour comparer visuellement les pentes et formes de relation entre types

**Approche :** On construit une variable `prcp_ete` (somme des précipitations de juillet à septembre). On trace la relation avec `Rating` séparément pour chaque type via un facettage. 

##### Q15 — Une température hivernale plus froide est-elle associée à de meilleures notes, particulièrement pour les vins blancs ?
 
**Objectif :** Explorer l'effet des températures hivernales sur la qualité du vin. Question distincte des axes estivaux car elle porte sur le repos végétatif de la vigne (décembre-février).
 
**Variables :** `Dec_tavg`, `Jan_tavg`, `Feb_tavg`, `Rating`, `type`
 
**Graphique :** Scatter plot `tavg_hiver` vs `Rating` avec `geom_smooth` par type, facetté par `type`
 
**Approche :** On construit `tavg_hiver` (moyenne décembre-février). On compare la relation avec `Rating` entre types.

---

#### Axe 6 — Évolution climatique

##### Q16 — La hausse des températures estivales liée au réchauffement climatique est-elle visible dans les régions viticoles méditerranéennes entre 2005 et 2019 ?

**Objectif :** Vérifier si le réchauffement climatique laisse une trace mesurable dans les données météo du dataset, en se concentrant sur la zone méditerranéenne (latitude 35°–45°N) où le signal est le plus net et le plus documenté scientifiquement. Cette question porte *uniquement sur les variables météo*, sans impliquer la note; elle valide la cohérence du dataset avec les données climatiques officielles et donne de la crédibilité aux analyses de l'axe 4.

**Variables :** `Year`, `Jul_tavg`, `Aug_tavg`, `Sep_tavg`, `lat`

**Graphique :** Line chart de la température estivale moyenne par année (2005–2019) pour les régions méditerranéennes (35°N < `lat` < 45°N), avec droite de tendance linéaire (`geom_smooth`, méthode *lm*) et bande de confiance

**Approche :** On filtre les vins des régions situées entre 35° et 45° de latitude nord (Espagne, Sud de la France, Italie, Grèce). On agrège la température estivale moyenne (`tavg_ete`) par année.

---

#### Axe 7 — Structure et diversité du marché viticole
 
##### Q17 — Quel est le profil de diversité géographique de chaque type de vin, et comment cela se reflète-t-il dans leurs gammes de prix ?
 
**Objectif :** Comparer les 4 types de vins sur leur empreinte géographique (nombre de pays et de régions couverts) et leur positionnement tarifaire.
 
**Variables :** `type`, `Country`, `Region`, `Price`
 
**Graphique :** Graphique à bulles (`geom_point`) avec le nombre de pays en x, le nombre de régions en y, la taille des bulles proportionnelle au prix médian, et la couleur encodant le type ; complété d'un bar chart des prix médians par type
 
**Approche :** On agrège par type pour obtenir le nombre de pays distincts, de régions distinctes et le prix médian. Le graphique à bulles positionne chaque type dans l'espace diversité/concentration.

##### Q18 — La variabilité des notes au sein d'un même pays reflète-t-elle une hétérogénéité de production ou une richesse de terroirs ?
 
**Objectif :** Comparer les pays non sur leur note moyenne (comme en Q7) mais sur leur *dispersion* interne (`std` des notes). Un pays avec une forte dispersion produit à la fois de très bons et de très mauvais vins (profil hétérogène), tandis qu'un pays homogène maintient un niveau constant.
 
**Variables :** `Country`, `Rating`, `type`
 
**Graphique :** Bar chart horizontal des pays (≥ 100 vins) classés par écart-type des notes, avec la note moyenne annotée sur chaque barre, coloré par continent
 
**Approche :** On calcule la note moyenne et l'écart-type par pays. On trie par écart-type décroissant. On annote la note moyenne sur chaque barre pour lire simultanément qualité moyenne et régularité. Les pays "surprises" (bonne moyenne + forte dispersion) seront les plus intéressants à commenter.

##### Q19 — Quelles régions surperforment en note tout en restant moins chères que la moyenne du pays ?
 
**Objectif :** Identifier les régions qui combinent deux avantages : une note supérieure à la moyenne nationale ET un prix inférieur à la médiane nationale. Ce sont les "pépites" du dataset, des terroirs d'excellence accessibles. Question qui croise note, prix et ancrage géographique.
 
**Variables :** `Region`, `Country`, `Rating`, `Price`
 
**Graphique :** Scatter plot des régions (≥ 15 vins) avec `ecart_note_pays` en x et `ecart_prix_pays` en y, annoté pour les régions dans le quadrant "mieux notées + moins chères", coloré par `Country`
 
**Approche :** Pour chaque région, on calcule l'écart à la note moyenne nationale et l'écart au prix médian national. On projette chaque région sur le plan (écart_note, écart_prix). Le quadrant supérieur gauche (meilleure note, prix inférieur) identifie les pépites.

##### Q20 — Le profil climatique annuel d'une région permet-il de prédire la régularité de sa production d'une année à l'autre ?
 
**Objectif :** Tester si les régions au climat annuel plus stable (faible variabilité de la température estivale d'une année à l'autre) produisent des vins avec des notes plus homogènes entre millésimes. Question conclusive qui relie les axes climatiques (Axe 5) et la stabilité de production (Q11), ce qui cloture la problématique centrale du projet.
 
**Variables :** `Region`, `Year`, `Rating`, `Jul_tavg`, `Aug_tavg`, `Sep_tavg` — variables construites : `std_rating_region`, `std_tavg_region`
 
**Graphique :** Scatter plot `std_tavg_region` (variabilité climatique) vs `std_rating_region` (variabilité des notes) avec les régions comme points colorés par `Country`, annoté pour les cas extrêmes, avec droite de tendance
 
**Approche :** On filtre les régions avec ≥ 5 millésimes. On calcule l'écart-type de la note et de la température estivale par région. Le scatter plot teste visuellement la corrélation entre stabilité climatique et stabilité qualitative. La visualisation obtenue permettra d'ouvrir sur les limites du seul facteur climatique pour expliquer la régularité d'une production viticole.
 
---

#### Points de vigilance

- La **note est subjective** et agrégée sur des périodes différentes ; un vin de 1990 noté aujourd'hui souffre d'un biais de sélection (seules les bonnes bouteilles survivent et sont encore notées)
- La **météo est géolocalisée à l'échelle de la région** et non de la parcelle : des micro-climats peuvent exister au sein d'une même région sans être capturés
- La **forte asymétrie par type** (8 658 rouges vs 279 effervescents) limitera la comparabilité directe entre catégories sans rééchantillonnage ou pondération
- Certaines variables météo sont **colinéaires** (`tmin`, `tmax`, `tavg` sont par définition liées), ce qui sera pris en compte pour éviter les interprétations redondantes dans les analyses multivariées
- Le dataset ne contient **aucune information sur les pratiques viticoles** (agriculture biologique, irrigation, rendement), ce qui laisse une part de variance inexpliquée par le seul climat
