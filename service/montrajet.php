<?php
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");
header("Last-Modified: ".gmdate("D, d M Y H:i:s")." GMT");
header("Cache-Control: no-cache, must-revalidate");
header("Pragma: no-cache");
header("Content-Type:application/json");


$dayofweek = $_GET['day'];
$orientation = $_GET['orientation'];
$hour = $_GET['hour'];
$halfhour = $_GET['halfhour'];

//$sql = "select *, st_asgeojson(st_transform(geometry,4326)) as g from montrajet_result;";
//http://localhost/montrajet.php?orientation=N&day=0&hour=6&halfhour=0
$sql = "select *,st_asgeojson(st_transform(geometry,4326)) as g from montrajet_result_24au8_v inner join osm_new_roads on osm_new_roads.osm_id=montrajet_result_24au8_v.osm_id where dayofweek={$dayofweek} and hour={$hour} and demiheure={$halfhour} and direction='{$orientation}';";

error_log($sql);

$dbconn = pg_connect("host=localhost port=5432 dbname=osm user=postgres password=postgres");
$result = pg_query($dbconn, $sql);
if (!$result) {
  echo "An error occurred.\n";
  exit;
}

$geojson = new stdClass();
$geojson->type = "FeatureCollection";

$data = array();

while ($row = pg_fetch_assoc($result)) {
   $line = new stdClass();
   $line->type = "Feature";
$geometry=   json_decode($row['g']);
$line->geometry = $geometry;
//die(json_encode($geometry));
  // $geom = str_replace('"{','{',$row['g']);
   //$geom = str_replace('}"','}',$geom);
   //$geom = str_replace('/','',$geom);
   //$geom = str_replace('LineString','"LineString"',$geom);

   //$line->geometry = $geom;
   //$line->geometry = str_replace('"','',$row['g']); //substr($row['g'],1,strlen($row['g'])-2);
   //$geometry = json_decode($row['g']);
   //$line->geometry = $geometry;
   //$line->geometry->type="LineString";// = $row['g'];
//   $line->geometry->coordinates=
   $line->properties = new stdClass();
   $line->properties->vitesse = $row['vitesse'];
	
    $limite = 70;
    if($row['class']=="mainroads")
       $limite=90;
    else if($row['class']=="minorroads")
       $limite=30;
    else if($row['class']=="motorways")
       $limite=90;

   $line->properties->limite = $limite;//$row['vitesse'];

//"mainroads"
//"motorways"
//"minorroads"

   $data[] = $line;
}
$geojson->features = $data;
die(json_encode($geojson));
//$output = json_encode($geojson)
//$output = str_replace('"type"','type',$output);
//die($output);

?>