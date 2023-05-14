<?php include_once('Parsedown.php');
header("Content-Type: text/html; charset=UTF-8");
?><!DOCTYPE html><html><head><meta charset="UTF-8">
<title>navycs.cc readme</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" type="text/css" href="simple.css">
</head>
<body>
<?php
$file = file_get_contents('readme.md');
$Parsedown = new Parsedown();
echo $Parsedown->text($file);
?></body></html>
