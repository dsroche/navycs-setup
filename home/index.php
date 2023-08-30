<?php
header("Content-Type: text/html; charset=UTF-8");
?><!DOCTYPE html><html><head><meta charset="UTF-8">
<title>USNA CS Department Web Blogs</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" type="text/css" href="simple.css">
</head>
<body>
<h1></h1>
<h2>USNA links</h2>
<ul>
<li><a href="https://www.usna.edu/">U.S. Naval Academy</a></li>
<li><a href="https://usna.edu/CS/">Computer Science Department</a></li>
<li><a href="https://www.instagram.com/usnacompsci">CS Department Instagram</a></li>
</ul>
<h2>Faculty</h2>
<?php
echo '<table>';
function ulink($user) {
  return '<a href="~' . $user . '/">' . $user . '</a>';
}
$users = array_map('trim', file('scs.txt'));
natcasesort($users);
if (count($users) <= 6) {
  echo '<ul>';
  foreach ($users as $user) {
    $user = trim($user);
    echo '<li>', ulink($user), '</li>';
  }
  echo '</ul>';
} else {
  $column = 0;
  foreach ($users as $user) {
    $user = trim($user);
    if ($column == 0) echo '<tr>';
    echo '<td>', ulink($user), '</td>';
    $column += 1;
    if ($column == 3) {
      echo '</tr>';
      $column = 0;
    }
  }
  if ($column > 0) echo '</tr>';
  echo '</table>';
}
?>
<h2>Enjoy!</h2>
<p>This image was created by
<a href="https://stability.ai/blog/stable-diffusion-public-release">Stable Diffusion</a>
with the prompt &quot;soothing&quot;. I hope it calms your day.</p>
<img src="soothing.png" />
<!--
<h2>How can I join?</h2>
<p>If you are a USNA faculty member and want your blog hosted here,
email Dan Roche with your numeric uid and an ssh public key file.
Or, if you want to be fancy about it, make a pull request
on <a href="https://github.com/dsroche/navycs-setup">this GitHub project</a>
according to the instructions in the README.
</p>
<h2>Why does this exist?</h2>
<p>There is no reason for this web server to exist.
In fact, it <em>should</em> not exist and for many years had no reason to exist.
We hope that it will be only temporary.</p>
-->
</body></html>
