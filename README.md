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
    - [Données](#donn%C3%A9es)
    - [Plan d'analyse](#plan-danalyse)

## Introduction

### Données

Notre jeu de données est issu de la plateforme **Kaggle** : [Wine Growth Weather](https://www.kaggle.com/datasets/abcd334/wine-growth-weather/), constitué par Anton Budnyak (2020) et enrichi de données météorologiques issues de [Open-Meteo.com](https://open-meteo.com/).

Le vin est un produit intimement lié aux conditions climatiques de sa région de production. La vigne est particulièrement sensible aux variations de température, d'ensoleillement et de précipitations durant la saison de croissance. Ce dataset a précisément été conçu pour explorer cette relation : les données météorologiques correspondent à l'**année précédant la production du vin**, ce qui nous permet ainsi d'évaluer l'impact du climat sur la note et la qualité perçue du vin.

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

Les variables se regroupent en trois grandes familles :

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

Notre analyse s'articule autour de quatre axes principaux, en partant des questions les plus descriptives vers les plus explicatives.

#### 1 — Vue d'ensemble et profil des données

- **Quelle est la répartition géographique des vins ?** Y a-t-il une surreprésentation de certains pays ou régions (notamment France/Italie) susceptible de biaiser les analyses globales ?
- **Comment se distribuent les notes et les prix** selon le type de vin ? Les effervescents sont-ils systématiquement mieux notés ? Les rouges plus chers ?
- **Le nombre d'évaluations (`NumberOfRatings`) est-il homogène ?** Une note basée sur 10 avis est moins fiable qu'une basée sur 1 000 — nous devrons pondérer ou filtrer en conséquence.
- **Y a-t-il des valeurs aberrantes** sur le prix (bouteilles à 3 000 €+) ou les données météo qui pourraient fausser les analyses ?

#### 2 — Facteurs commerciaux et qualitatifs

- **Le prix est-il un bon indicateur de qualité ?** Existe-t-il une corrélation entre le prix et la note, et varie-t-elle selon le type de vin ?
- **Certaines régions viticoles produisent-elles systématiquement de meilleurs vins ?** Peut-on identifier des *terroirs* d'excellence en comparant les distributions de notes par région ?
- **L'ancienneté du millésime joue-t-elle sur la note ?** Les vins plus vieux sont-ils mieux notés, ou cet effet est-il spécifique à certains types (ex. rouges de garde) ?
- **Les grandes maisons (Winery) se distinguent-elles** par une note ou un prix significativement supérieurs à la moyenne ?

#### 3 — Influence du climat sur la qualité du vin *(axe central)*

C'est la question fondatrice du dataset : les conditions météorologiques de l'année de croissance expliquent-elles la note d'un vin ?

- **Y a-t-il des mois clés** dont la température ou l'ensoleillement corrèlent davantage avec la note ? (Typiquement : été et automne pour les vendanges)
- **Un ensoleillement élevé en été (`Jul_tsun`, `Aug_tsun`) est-il associé à de meilleures notes ?** L'hypothèse est que les grandes années sont souvent les années chaudes et ensoleillées.
- **Les précipitations ont-elles un effet négatif sur la note ?** Un excès de pluie en été est réputé diluer les arômes ; peut-on le vérifier dans les données ?
- **Le profil climatique idéal varie-t-il selon le type de vin ?** Les conditions optimales pour un blanc de Bourgogne ne sont pas celles d'un rouge de Bordeaux.
- **Peut-on construire un indicateur climatique synthétique** (ex. "score de millésime") qui prédit la note mieux que chaque variable prise isolément ?

#### 4 — Analyse géo-climatique et tendances

- **Existe-t-il des patterns géographiques dans les données climatiques ?** Les régions méditerranéennes ont-elles un profil d'ensoleillement structurellement différent des régions atlantiques, et cela se reflète-t-il dans les notes ?
- **Y a-t-il une tendance temporelle dans les notes ou les conditions climatiques ?** Peut-on observer l'effet du réchauffement climatique sur les températures de croissance au fil des millésimes ?
- **Les années climatiquement extrêmes** (ex. canicule 2003 en Europe) se distinguent-elles dans les données par des notes anormalement hautes ou basses ?

#### Points de vigilance

- La **note est subjective** et agrégée sur des périodes différentes
- La **météo est géolocalisée à l'échelle de la région**, pas de la parcelle: des micro-climats peuvent exister au sein d'une même région
- La **forte asymétrie par type** (8 658 rouges vs 279 effervescents) limitera la comparabilité directe entre catégories sans rééchantillonnage
- Certaines variables météo pourraient être **colinéaires** (tmin/tmax/tavg), ce qui nécessitera une attention particulière lors des analyses multivariées
