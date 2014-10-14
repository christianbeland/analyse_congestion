analyse_congestion
==================

Analyse de la congestion - Défi Geohack 2014

http://defigeohack.sparkboard.com/project/54008fdf8a103f0200000005

Membres de l'équipe:
 - Frédéric Morin
 - Christian Béland
 - Bruno Remy
 - Dominic Savard

Environnement Technologique du serveur web
 - Ubuntu 14.04
 - PostgreSQL/PostGIS
 - PgAdmin
 - GDAL/OGR
 - imposm
 - PHP
 - Apache
 
Données ouvertes:
 - Couverture OSM du Québec: http://download.geofabrik.de/north-america/canada/quebec-latest.osm.pbf
 - Données MonTrajet: http://donnees.ville.quebec.qc.ca/Handler.ashx?id=76&f=JSON
  
Procédure:
 - Installer les logiciels
 - Utiliser imposm afin de charger les données OSM dans la base de donnée PostGIS
 - Utiliser OGR afin de charger les données de MonTrajet
 - Lancer les scripts SQL afin de préparer les données
 - Déployer le code source sur apache et modifier ses paramètres de configuration
 

