# Vin & Météo : l'influence du climat sur la qualité des vins

> *"Le vin est le reflet du ciel, de la terre et du travail des hommes."*

## Membres

| L'équipe Avatar      |
| -------------------- |
| Samuel FANDIO NJIKAM |
| Samella LEUKOUO      |
| Fanta DEMBELE        |

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

Notre analyse s'articule autour de **6 axes indépendants**, progressant du descriptif vers l'analytique et l'explicatif. Chaque question est conçue pour éclairer un aspect distinct du dataset, avec des variables, des graphiques et une approche propres.

#### Axe 1 — Distributions et structure

##### Q1 — Comment se distribuent les notes des vins, et cette distribution varie-t-elle selon le type ?

**Objectif :** Établir un portrait de base de la variable cible (`Rating`) avant toute analyse explicative. Il s'agit de comprendre si les notes sont concentrées sur une plage étroite ou bien réparties, et si les 4 types de vins présentent des profils de notation distincts.

**Variables :** `Rating`, `type`

**Graphique :** Violin plot + boxplot superposés, un par type de vin

**Approche :** On représente côte à côte les 4 distributions de `Rating` par type. Le violin plot révèle la forme complète de la distribution (asymétrie, multi-modalité), tandis que la boxplot superposée permet de lire rapidement la médiane et les quartiles. On cherchera en particulier si les effervescents ont une distribution décalée vers le haut, ou si les rosés sont plus concentrés autour d'une note moyenne.

##### Q2 — Le nombre d'évaluations est-il suffisant pour que les notes soient fiables ?

**Objectif :** Identifier un biais potentiel majeur : une note de 4.5 basée sur 8 avis est très différente d'une note de 4.5 basée sur 2 000 avis. Cette question définit un seuil de fiabilité que nous appliquerons comme filtre dans les analyses suivantes.

**Variables :** `NumberOfRatings`, `Rating`, `type`

**Graphique :** Scatter plot (`NumberOfRatings` en x, `Rating` en y) avec échelle logarithmique sur l'axe x, coloré par `type`

**Approche :** On trace la relation entre le nombre d'avis et la note. Si les vins peu notés (ex. < 50 avis) présentent une forte dispersion verticale, cela confirme leur manque de fiabilité. On trace une ligne de seuil vertical et on observe que la variance des notes se réduit au-delà. Ce seuil sera appliqué comme filtre dans les axes suivants pour garantir des comparaisons robustes.

---

#### Axe 2 — Prix et qualité : le prix fait-il le vin ?

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

##### Q5 — Certains producteurs se distinguent-ils par une note systématiquement supérieure à celle de leur région, indépendamment du prix ?
 
**Objectif :** Mesurer l'effet *domaine* sur la qualité, c'est-à-dire la part de la note qui s'explique par le savoir-faire du producteur plutôt que par sa région ou son prix. Une région peut afficher une note moyenne élevée simplement parce qu'un ou deux grands domaines tirent la moyenne vers le haut — cette question permet de détecter ce phénomène et de distinguer l'excellence d'un terroir de celle d'un producteur.
 
**Variables :** `Winery`, `Region`, `Rating`, `Price`, `type`
 
**Graphique :** Dot plot des 20 producteurs dont l'écart entre leur note moyenne et la note moyenne de leur région est le plus élevé, coloré par `type`, avec barres d'erreur représentant l'intervalle de confiance
 
**Approche :** Pour chaque vin, on calcule l'écart entre sa note et la note moyenne de sa région (`Rating - mean_rating_region`). On agrège ensuite par `Winery` pour obtenir l'écart moyen par producteur, filtré sur ceux ayant au moins 10 vins notés. Un écart positif élevé indique un producteur qui surperforme structurellement son terroir. Le dot plot avec intervalles de confiance permet de distinguer les producteurs dont la surperformance est statistiquement solide de ceux dont l'écart est dû à un trop faible nombre d'observations.

---

#### Axe 3 — Millésimes et effet du temps

##### Q6 — La note moyenne des vins évolue-t-elle selon le millésime, et cet effet traduit-il un vieillissement réel ou un biais de survie ?

**Objectif :** Déterminer si les vieux millésimes sont mieux notés parce que les vins vieillis sont intrinsèquement meilleurs (*effet qualité*), ou parce que seules les bouteilles d'exception ont survécu et sont encore notées aujourd'hui (*biais de survie*). Ces deux explications sont opposées et conditionnent l'interprétation des analyses climatiques sur les anciens millésimes.

**Variables :** `Year`, `Rating`, `NumberOfRatings`, `type`

**Graphique :** Line chart de la note moyenne par millésime (1990–2020) avec bande de confiance (`geom_ribbon`), facetté par `type`, complété d'un graphique du nombre d'observations par année

**Approche :** On calcule la note moyenne et le nombre d'observations par année et par type. On trace l'évolution temporelle avec une bande de confiance pour visualiser l'incertitude. Si les années anciennes cumulent très peu d'observations mais des notes très élevées, cela révèle un biais de survie. Ce constat sera utilisé pour borner les analyses climatiques aux millésimes récents (ex. après 1995) où les données sont plus denses et fiables.

---

#### Axe 4 — Climat et qualité : le cœur de la problématique

##### Q7 — Quels mois de l'année de croissance ont la plus forte corrélation avec la note du vin ?

**Objectif :** Identifier les périodes climatiques clés du cycle de la vigne (floraison en mai-juin, véraison en juillet-août, vendanges en septembre) en cherchant lesquelles ont le plus d'impact statistique sur la note finale. Cette question est exploratoire et sert de guide pour les analyses suivantes.

**Variables :** `Rating` et les 60 variables météo mensuelles (`Jan_tavg` à `Dec_tsun`)

**Graphique :** Heatmap de corrélation, avec les 12 mois sur l'axe x et les 5 indicateurs météo (`tavg`, `tmin`, `tmax`, `prcp`, `tsun`) sur l'axe y, la couleur encodant le coefficient de corrélation avec `Rating`

**Approche :** On calcule le coefficient de corrélation de Pearson entre `Rating` et chacune des 60 variables météo. La heatmap permet de visualiser d'un coup d'œil quels mois et quels indicateurs sont les plus associés à la note. On s'attend à ce que l'été (juillet-août) et l'automne (septembre) ressortent comme les périodes les plus déterminantes, les mois hivernaux devant afficher des corrélations proches de zéro.

##### Q8 — L'ensoleillement estival est-il le meilleur prédicteur de la note, et cet effet varie-t-il entre types de vins ?

**Objectif :** Approfondir le résultat de Q6 sur l'indicateur météo le plus corrélé à la note (l'ensoleillement estival, hypothèse œnologique classique). On cherche ici à savoir si cet effet est universel ou propre à certains types, ce qui révèlerait des exigences climatiques différentes selon les cépages.

**Variables :** `Jul_tsun`, `Aug_tsun`, `Sep_tsun`, `Rating`, `type`

**Graphique :** Scatter plot de `tsun_ete` (variable construite) vs `Rating`, avec `geom_smooth` par type, facetté par `type`

**Approche :** On construit une variable synthétique `tsun_ete` comme moyenne de `Jul_tsun`, `Aug_tsun` et `Sep_tsun`. On trace la relation avec `Rating` séparément pour chaque type via un facettage. Des pentes différentes entre types confirmeraient que les vins blancs et rouges n'ont pas les mêmes besoins en ensoleillement. On notera également les cas atypiques (vins très bien notés malgré peu de soleil) qui suggèrent l'influence d'autres facteurs non capturés.

##### Q9 — Les précipitations estivales nuisent-elles à la note du vin, et cet effet est-il linéaire ?

**Objectif :** Tester une hypothèse œnologique bien établie. Un excès de pluie en été dilue la concentration des arômes et favorise les maladies de la vigne, dégradant la qualité. Cette question est distincte de Q7 car elle porte sur un mécanisme différent (excès d'eau vs. intensité lumineuse) et peut produire un effet *non linéaire* : un peu de pluie est nécessaire, trop est néfaste.

**Variables :** `Jul_prcp`, `Aug_prcp`, `Sep_prcp`, `Rating`, `type`

**Graphique :** Scatter plot avec `geom_smooth` en méthode *loess* (pour capturer une relation non linéaire), facetté par `type`

**Approche :** On construit une variable `prcp_ete` (somme des précipitations de juillet à septembre). On utilise une régression locale (loess) plutôt qu'une droite pour détecter un éventuel seuil : la note pourrait rester stable jusqu'à un certain niveau de pluie puis chuter. On compare ces seuils entre types pour identifier si certains cépages sont plus tolérants à l'humidité que d'autres.

---

#### Axe 5 — Évolution climatique et grands millésimes

##### Q10 — Peut-on observer une hausse des températures de croissance au fil des millésimes dans les données ?

**Objectif :** Vérifier si le réchauffement climatique est visible dans ce dataset à travers l'évolution des températures estivales par région et par année. Cette question porte *uniquement sur les variables météo*, sans impliquer la note; elle valide la cohérence du dataset avec les données climatiques officielles et donne de la crédibilité aux analyses de l'axe 4.

**Variables :** `Year`, `Jul_tavg`, `Aug_tavg`, `Sep_tavg`, `lat`

**Graphique :** Line chart de la température estivale moyenne par année (1990–2020) avec droite de tendance linéaire (`geom_smooth`, méthode *lm*), facetté par grande zone géographique (définie à partir de `lat`)

**Approche :** On agrège les données par année et par zone géographique (nord/sud d'une latitude seuil de 45°N, séparant approximativement l'Europe du Nord de l'Europe méditerranéenne). On trace la tendance linéaire sur 30 ans et on vérifie si la pente est positive. Si le dataset est cohérent avec les données climatiques réelles, on devrait observer une hausse progressive des températures, ce qui validera les variables météo comme indicateurs fiables.

##### Q11 — Les années climatiquement exceptionnelles correspondent-elles à des millésimes exceptionnels dans les notes ?

**Objectif :** Relier les analyses climatiques (axe 4) et temporelles (axe 3) en vérifiant si les années reconnues comme extrêmes (ex. canicule 2003, été frais 2013) produisent bien des anomalies de note dans le dataset. C'est un test de *validité externe* : si le lien climat↔note est réel, les grands millésimes viticoles historiques doivent être visibles.

**Variables :** `Year`, `Rating`, `Jul_tavg`, `Aug_tavg`, `Jul_tsun`, `Country`, `type`

**Graphique :** Bar chart des notes moyennes par millésime (2000–2019) pour les vins européens, avec annotation des années climatiquement remarquables (`geom_label`), superposé à une courbe de température estivale sur un axe secondaire

**Approche :** On calcule la note moyenne par millésime pour les vins d'Europe. On superpose la courbe de température estivale moyenne. On annote manuellement les années connues comme climatiquement exceptionnelles (2003, 2010, 2015). Une concordance entre pics de chaleur/ensoleillement et pics de note validerait l'hypothèse centrale du projet. Les discordances seront tout aussi commentées pour nuancer les conclusions.

---

#### Axe 6 — Géographie et profil climatique structurel des régions

##### Q12 — La latitude d'une région viticole influence-t-elle la qualité structurelle de ses vins, indépendamment des variations annuelles ?

**Objectif :** Explorer si la position géographique d'une région (qui détermine *structurellement* son ensoleillement et ses températures moyennes) est associée à la qualité moyenne des vins produits. Cet axe est fondamentalement distinct des précédents : au lieu d'analyser l'effet d'une *année particulière*, on cherche un effet *permanent* lié à la géographie; indépendant du millésime.

**Variables :** `lat`, `lng`, `Rating`, `Country`, `type`

**Graphique :** Carte géographique (`ggplot2` + `geom_point`) où chaque région est positionnée par `lat`/`lng`, colorée par note moyenne et dimensionnée par nombre de vins ; complétée d'un scatter plot `lat` vs `Rating` avec droite de régression

**Approche :** On agrège les données par région pour obtenir la note moyenne et le nombre de vins. On projette chaque région sur une carte du monde pour révéler des patterns spatiaux visuels. Le scatter plot complémentaire `lat` vs `Rating` quantifie la tendance : les régions méditerranéennes (basse latitude, fort ensoleillement structurel) sont-elles systématiquement mieux notées que les régions septentrionales ? On contrôle par `type` pour isoler l'effet de la latitude de celui du type de vin produit dans chaque zone.

---

#### Points de vigilance

- La **note est subjective** et agrégée sur des périodes différentes ; un vin de 1990 noté aujourd'hui souffre d'un biais de sélection (seules les bonnes bouteilles survivent et sont encore notées)
- La **météo est géolocalisée à l'échelle de la région** et non de la parcelle : des micro-climats peuvent exister au sein d'une même région sans être capturés
- La **forte asymétrie par type** (8 658 rouges vs 279 effervescents) limitera la comparabilité directe entre catégories sans rééchantillonnage ou pondération
- Certaines variables météo sont **colinéaires** (`tmin`, `tmax`, `tavg` sont par définition liées), ce qui sera pris en compte pour éviter les interprétations redondantes dans les analyses multivariées
- Le dataset ne contient **aucune information sur les pratiques viticoles** (agriculture biologique, irrigation, rendement), ce qui laisse une part de variance inexpliquée par le seul climat
