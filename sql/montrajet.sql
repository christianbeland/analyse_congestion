create table montrajet_extent (id serial, geom geometry)

select * from montrajet_12au18 limit 10;
select * from montrajet_24au8 limit 10;
select * from montrajet_5au11 limit 10;
select * from montrajet_extent;

select coord_id,datetrajet,dtg from montrajet_24au8 limit 10;
alter table montrajet_24au8 add column geom_p geometry;
alter table montrajet_24au8 add column dtg timestamp;
update montrajet_24au8 set geom_p=st_geomfromgeojson(geom);
update montrajet_24au8 set geom_p=st_setsrid(geom_p,4326);
update montrajet_24au8 set dtg=to_timestamp(datetrajet,'YYYYMMDDHH24MISS');
create index montrajet_24au8_gix on montrajet_24au8 using gist(geom_p);

alter table montrajet_12au18 add column geom_p geometry;
alter table montrajet_12au18 add column dtg timestamp;
update montrajet_12au18 set geom_p=st_geomfromgeojson(geom);
update montrajet_12au18 set geom_p=st_setsrid(geom_p,4326);
update montrajet_12au18 set dtg=to_timestamp(datetrajet,'YYYYMMDDHH24MISS');
create index montrajet_12au18_gix on montrajet_12au18 using gist(geom_p);

alter table montrajet_5au11 add column geom_p geometry;
alter table montrajet_5au11 add column dtg timestamp;
update montrajet_5au11 set geom_p=st_geomfromgeojson(geom);
update montrajet_5au11 set geom_p=st_setsrid(geom_p,4326);
update montrajet_5au11 set dtg=to_timestamp(datetrajet,'YYYYMMDDHH24MISS');
create index montrajet_5au11_gix on montrajet_5au11 using gist(geom_p);

alter table montrajet_24au8 add column osm_id bigint;
alter table montrajet_12au18 add column osm_id bigint;
alter table montrajet_5au11 add column osm_id bigint;

update montrajet_24au8 set osm_id=(select osm_new_roads.osm_id from osm_new_roads where st_dwithin(st_transform(geom_p,900913),geometry,10) order by st_distance(st_transform(geom_p,900913),geometry) limit 1)
update montrajet_12au18 set osm_id=(select osm_new_roads.osm_id from osm_new_roads where st_dwithin(st_transform(geom_p,900913),geometry,10) order by st_distance(st_transform(geom_p,900913),geometry) limit 1)
update montrajet_5au11 set osm_id=(select osm_new_roads.osm_id from osm_new_roads where st_dwithin(st_transform(geom_p,900913),geometry,10) order by st_distance(st_transform(geom_p,900913),geometry) limit 1)

alter table montrajet_24au8 add column trip_azymuth float;
alter table montrajet_12au18 add column trip_azymuth float;
alter table montrajet_5au11 add column trip_azymuth float;

drop table if exists montrajet_line;
create table montrajet_line (id serial, trip_id bigint, day int,hour int, dataset int, geom_l geometry);
insert into montrajet_line(trip_id,dataset,day,hour,geom_l)  (select montrajet_24au8.trip_id, 1, date_part('day',montrajet_24au8.dtg),date_part('hour',montrajet_24au8.dtg), st_makeline(geom_p order by dtg) from montrajet_24au8 where osm_id is not null group by trip_id,date_part('day',montrajet_24au8.dtg),date_part('hour',montrajet_24au8.dtg));
insert into montrajet_line(trip_id,dataset,day,hour,geom_l)  (select montrajet_12au18.trip_id, 2, date_part('day',montrajet_12au18.dtg),date_part('hour',montrajet_12au18.dtg), st_makeline(geom_p order by dtg) from montrajet_12au18 where osm_id is not null group by trip_id,date_part('day',montrajet_12au18.dtg),date_part('hour',montrajet_12au18.dtg));
insert into montrajet_line(trip_id,dataset,day,hour,geom_l)  (select montrajet_5au11.trip_id, 3, date_part('day',montrajet_5au11.dtg),date_part('hour',montrajet_5au11.dtg), st_makeline(geom_p order by dtg) from montrajet_5au11 where osm_id is not null group by trip_id,date_part('day',montrajet_5au11.dtg),date_part('hour',montrajet_5au11.dtg));

drop view if exists montrajet_v;
create view montrajet_v as (select *,'24au8' as dataset from montrajet_24au8 union select *,'12au18' as dataset from montrajet_12au18 union select *,'5au11' as dataset from montrajet_5au11);

alter table montrajet_line add column azymuth float;
update montrajet_line set azymuth=st_azimuth(st_startpoint(geom_l), st_endpoint(geom_l));

--faire un peu de menage dans les donnees...
delete from montrajet_line where azymuth is null;
delete from montrajet_line where st_length(geom_l) >.5

alter table montrajet_24au8 add column day int;
alter table montrajet_24au8 add column hour int;
alter table montrajet_24au8 add column dow int;
alter table montrajet_24au8 add column demiheure int;

alter table montrajet_24au8 add column direction varchar(1);

update montrajet_24au8 set day=date_part('day',montrajet_24au8.dtg);
update montrajet_24au8 set hour=date_part('hour',montrajet_24au8.dtg);
update montrajet_24au8 set dow=extract(dow from montrajet_24au8.dtg);
update montrajet_24au8 set demiheure=floor(extract(minute from dtg)/30);



--Nord: entre 0 et pi/4 et 7pi/8 et 2pi
--Est:  entre pi/4 et 3pi/4
--Sud:  entre 3pi/4 et 5pi/4
--Ouest:entre 5pi/4 et 7pi/8

update montrajet_24au8 set direction=(CASE 
	WHEN trip_azymuth>0 and trip_azymuth<pi()/4 THEN 'N'
	WHEN trip_azymuth>7*pi()/8 and trip_azymuth<2*pi() THEN 'N'
	WHEN trip_azymuth>3*pi()/4 and trip_azymuth<5*pi()/4 THEN 'S'
	WHEN trip_azymuth>pi()/4 and trip_azymuth<3*pi()/4 THEN 'E'
	WHEN trip_azymuth>5*pi()/4 and trip_azymuth<7*pi()/8 THEN 'W'
       END);

--select trip_id from montrajet_24au8 group by trip_id order by trip_id limit 1000;
create index trip_id_24au8_idx on montrajet_24au8(trip_id);
create index trip_id_line on montrajet_line(trip_id);

update montrajet_24au8 set trip_azymuth=(
	select azymuth 
	from montrajet_line 
	where montrajet_24au8.trip_id=montrajet_line.trip_id 
		and montrajet_24au8.day=montrajet_line.day 
		and montrajet_24au8.hour=montrajet_line.hour);
		

create table montrajet_result24au8(id serial,osm_id bigint, geometry geometry, name varchar(255), type varchar(255), class varchar(255), vitesse float, count int, dayofweek float, hour float, demiheure float); 
insert into montrajet_result24au8(osm_id,vitesse,count,dayofweek,hour,demiheure)  ( 
select montrajet_24au8.osm_id,
	avg(montrajet_24au8.vitesse)*3.6 as vitesse,
	count(montrajet_24au8.trip_id),
	extract(dow from montrajet_24au8.dtg) dayofweek,
	date_part('hour',montrajet_24au8.dtg) as hour,
	floor(extract(minute from montrajet_24au8.dtg)/30) as demiheure,
	CASE trip_azymuth>0 and trip_azymuth<pi() THEN 'one'
       END
from montrajet_24au8
where montrajet_24au8.osm_id is not null
group by montrajet_24au8.osm_id,date_part('hour',montrajet_24au8.dtg),demiheure,dayofweek
);

select montrajet_24au8.osm_id,
	avg(montrajet_24au8.vitesse)*3.6 as vitesse,
	count(montrajet_24au8.trip_id),
	montrajet_24au8.dow as dayofweek,
	montrajet_24au8.hour,
	montrajet.demiheure,
	montrajet.direction,
	from montrajet_24au8
where montrajet_24au8.osm_id is not null and trip_azymuth is not null
group by montrajet_24au8.osm_id,hour,demiheure,dayofweek,direction limit 10;


--drop view montrajet;
create view montrajet as
select osm_new_roads.osm_id,
	osm_new_roads.geometry,
	osm_new_roads.name,
	osm_new_roads.type,
	osm_new_roads.class,
	avg(montrajet_24au8.vitesse)*3.6 as vitesse,
	count(montrajet_24au8.trip_id),
	extract(dow from montrajet_24au8.dtg) dayofweek,
	date_part('hour',montrajet_24au8.dtg) as hour,
	floor(extract(minute from montrajet_24au8.dtg)/30) as demiheure
from osm_new_roads 
inner join montrajet_24au8 on osm_new_roads.osm_id=montrajet_24au8.osm_id 
group by osm_new_roads.osm_id,osm_new_roads.geometry,osm_new_roads.name,osm_new_roads.type,osm_new_roads.class,date_part('hour',montrajet_24au8.dtg),demiheure,dayofweek limit 1;


