alter table montrajet_12au18 add column geom_p geometry;
alter table montrajet_12au18 add column dtg timestamp;
update montrajet_12au18 set geom_p=st_geomfromgeojson(geom);
update montrajet_12au18 set geom_p=st_setsrid(geom_p,4326);
update montrajet_12au18 set dtg=to_timestamp(datetrajet,'YYYYMMDDHH24MISS');
create index montrajet_12au18_gix on montrajet_12au18 using gist(geom_p);
create index trip_id_12au18_idx on montrajet_12au18(trip_id);
create index dtg_12au18_idx on montrajet_12au18(dtg);
alter table montrajet_12au18 add column osm_id bigint;

update montrajet_12au18 set osm_id=(select osm_new_roads.osm_id from osm_new_roads where st_dwithin(st_transform(geom_p,900913),geometry,10) order by st_distance(st_transform(geom_p,900913),geometry) limit 1);
alter table montrajet_12au18 add column trip_azymuth float;
create table montrajet_line (id serial, trip_id bigint, day int,hour int, dataset int, geom_l geometry);
insert into montrajet_line(trip_id,dataset,day,hour,geom_l)  (select montrajet_12au18.trip_id, 1, date_part('day',montrajet_12au18.dtg),date_part('hour',montrajet_12au18.dtg), st_makeline(geom_p order by dtg) from montrajet_12au18 where osm_id is not null group by trip_id,date_part('day',montrajet_12au18.dtg),date_part('hour',montrajet_12au18.dtg));


alter table montrajet_line add column azymuth float;
update montrajet_line set azymuth=st_azimuth(st_startpoint(geom_l), st_endpoint(geom_l));

delete from montrajet_line where azymuth is null;
delete from montrajet_line where st_length(geom_l) >.5;

alter table montrajet_12au18 add column day int;
alter table montrajet_12au18 add column hour int;
alter table montrajet_12au18 add column dow int;
alter table montrajet_12au18 add column demiheure int;

alter table montrajet_12au18 add column direction varchar(1);

update montrajet_12au18 set day=date_part('day',montrajet_12au18.dtg);
update montrajet_12au18 set hour=date_part('hour',montrajet_12au18.dtg);
update montrajet_12au18 set dow=extract(dow from montrajet_12au18.dtg);
update montrajet_12au18 set demiheure=floor(extract(minute from dtg)/30);

create index trip_id_line on montrajet_line(trip_id);

update montrajet_12au18 set trip_azymuth=(
	select azymuth 
	from montrajet_line 
	where montrajet_12au18.trip_id=montrajet_line.trip_id 
		and montrajet_12au18.day=montrajet_line.day 
		and montrajet_12au18.hour=montrajet_line.hour);

update montrajet_12au18 set direction=(CASE 
	WHEN trip_azymuth>0 and trip_azymuth<pi()/4 THEN 'N'
	WHEN trip_azymuth>7*pi()/8 and trip_azymuth<2*pi() THEN 'N'
	WHEN trip_azymuth>3*pi()/4 and trip_azymuth<5*pi()/4 THEN 'S'
	WHEN trip_azymuth>pi()/4 and trip_azymuth<3*pi()/4 THEN 'E'
	WHEN trip_azymuth>5*pi()/4 and trip_azymuth<7*pi()/8 THEN 'W'
       END);


drop table montrajet_result12au18;
create table montrajet_result12au18(id serial,osm_id bigint, geometry geometry, name varchar(255), type varchar(255), class varchar(255), vitesse float, count int, dayofweek float, hour float, demiheure float, direction varchar(1)); 
insert into montrajet_result12au18(osm_id,vitesse,count,dayofweek,hour,demiheure,direction)  ( 
select montrajet_12au18.osm_id,
	avg(montrajet_12au18.vitesse)*3.6 as vitesse,
	count(montrajet_12au18.trip_id),
	montrajet_12au18.dow,
	montrajet_12au18.hour,
	montrajet_12au18.demiheure,
	montrajet_12au18.direction
from montrajet_12au18
where montrajet_12au18.osm_id is not null
group by montrajet_12au18.osm_id,hour,demiheure,dow,direction
); 
