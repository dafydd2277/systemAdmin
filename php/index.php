<?php

###
### INITIAL DEBUGGING
###

ini_set("display_errors", 'On');
ini_set("display_startup_errors", 'On');


###
### LIBRARIES
###

$path = '/usr/local/php/lib/';
set_include_path(get_include_path() . PATH_SEPARATOR . $path);


###
### INCLUDES
###

require 'vendor/autoload.php';
$parser = new \cebe\markdown\GithubMarkdown();
$parser->html5 = true;


###
### FUNCTIONS
###

/*
* $_GET and $_POST input parser
*
* This function will sanitize problematic characters and quote marks
# in incoming $_GET and $_POST arrays, and create $get and $post with the
# sanitized versions. This function will handle multiple option arrays
* within $_GET or %_POST, as well.
* 
* @param array $input The incoming GET or POST array.
* @return array The resulting sanitized array.
*
*/
function sanitizeInput ($input)
{
  $return = array();

  foreach ($input as $index1 => $value1)
  {
    if (is_array($value1))
    {
      foreach ($value1 as $index2 => $value2)
      {
        $return[$index1][$index2] =
          trim(htmlentities(stripslashes($value2), ENT_QUOTES));
      }
    }
    else
    {
      $return[$index1] =
        trim(htmlentities(stripslashes($value1), ENT_QUOTES));
    }
 }
 return $return;
}

$get = array();
$post = array();

$inputs = array ('_GET' => 'get', '_POST' => 'post');
foreach ($inputs as $in => $out)
{
  if ( is_array($$in) )
  {
    $$out = sanitizeInput($$in);
  }
  else
  {
    $$out = array();
  }
}

// Set the navigation links.
$page_navigation = "<ul>\n" .
  "<li><a href=\"?pg=main\">Main</a></li>\n" .
  "<li><a href=\"?pg=about\">About</a></li>\n" .
  "<li><a href=\"?pg=resume\">Resume</a> <span class=\"text8\">2017-01-01</span></li>\n" .
  "<li><a href=\"?pg=projects\">Projects</a></li>\n" .
  "<li><a href=\"?pg=emslist\">EMS Mnemonics</a></li>\n" .
  "<li><a href=\"?pg=firelist\">Firefighting Mnemonics</a></li>\n" .
  "</ul>\n";

// Modify the navigation links.
switch ($get['pg'])
{
  default:
  case 'main':
    $page_navigation = str_replace
    (
      '<a href="?pg=main">Main</a>',
      'Main',
      $page_navigation
    );
    break;
  case 'about':
    $page_navigation = str_replace
    (
      '<a href="?pg=about">About</a>',
      'About',
      $page_navigation
    );
    break;
  case 'resume':
    $page_navigation = str_replace
    (
      '<a href="?pg=resume">Resume</a>',
      'Resume',
      $page_navigation
    );
    break;
  case 'projects':
    $page_navigation = str_replace
    (
      '<a href="?pg=projects">Projects</a>',
      'Projects',
      $page_navigation
    );
    break;
  case 'emslist':
    $page_navigation = str_replace
    (
      '<a href="?pg=emslist">EMS Mnemonics</a>',
      'EMS Mnemonics',
      $page_navigation
    );
    break;
  case 'firelist':
    $page_navigation = str_replace
    (
      '<a href="?pg=firelist">Firefighting Mnemonics</a>',
      'Firefighting Mnemonics',
      $page_navigation
    );
    break;
}

// Set the pages.
switch ($get['pg'])
{
  default:
  case 'main':
    $page_title = "dafydd's home page";
    $page_header = "<h1>dafydd's home page</h1>\n" .
      "<h6>last updated: 2012-12-03</h6>\n";
    $page_content = $parser->parse(file_get_contents('main.md'));
    break;
  case 'about':
    $page_title = "about dafydd";
    $page_header = "<h1>who is dafydd?</h1>\n" .
    	"<h6>Last updated 2017-01-01</h6>\n";
    $page_content = $parser->parse(file_get_contents('about.md'));
    break;
  case 'resume':
    $page_title = "dafydd's resume";
    $page_header = "<h1>dafydd's resume</h1>\n" .
      "<h6>Last updated: 2017-01-01</h6>\n";
    $page_content = $parser->parse(file_get_contents('resume.md'));
    break;
  case 'projects':
    $page_title = "dafydd's projects";
    $page_header = "<h1>dafydd's projects</h1>\n" .
	    "<h6>last updated: 2017-01-01</h6>\n";
    $page_content = $parser->parse(file_get_contents('projects.md'));
    break;
  case 'emslist':
    $page_title = "ems mnemonics";
    $page_header = "<h1>ems mnemonics</h1>\n" .
      "<h6>Last updated: 2017-01-01</h6>\n";

    $page_content = "<div id=\"r1\">\n";
    $page_content .= $parser->parse(file_get_contents('emslist-top.md'));
    $page_content .= "</div><hr />\n";
    
    $page_content .= "<div id=\"r2\">\n";
    $page_content .= "<div id=\"r2l\" class=\"left\">\n";
    $page_content .= $parser->parse(file_get_contents('emslist-left-1.md'));
    $page_content .= "</div>\n";
    $page_content .= "<div id=\"r2r\" class=\"right\">\n";
    $page_content .= $parser->parse(file_get_contents('emslist-right-1.md'));
    $page_content .= "</div>\n";
    $page_content .= "</div>\n<hr />\n";
    
    $page_content .= "<div id=\"r3\">\n";
    $page_content .= "<div id=\"r3l\" class=\"left\">\n";
    $page_content .= $parser->parse(file_get_contents('emslist-left-2.md'));
    $page_content .= "</div>\n";
    $page_content .= "<div id=\"r3r\" class=\"right\">\n";
    $page_content .= $parser->parse(file_get_contents('emslist-right-2.md'));
    $page_content .= "</div>\n";
    $page_content .= "</div>\n<hr />\n";
    
    $page_content .= "<div id=\"r4\">\n";
    $page_content .= "<div id=\"r4l\" class=\"left\">\n";
    $page_content .= $parser->parse(file_get_contents('emslist-left-3.md'));
    $page_content .= "</div>\n";
    $page_content .= "<div id=\"r4r\" class=\"right\">\n";
    $page_content .= $parser->parse(file_get_contents('emslist-right-3.md'));
    $page_content .= "</div>\n";
    $page_content .= "</div>\n";
    break;
  case 'firelist':
    $page_title = "firefighting mnemonics";
    $page_header = "<h1>firefighting mnemonics</h1>\n" .
      "<h6>Last updated: 2017-01-01</h6>\n";
    
    $page_content = "<div id=\"r1\">\n";
    $page_content .= $parser->parse(file_get_contents('firelist-top.md'));
    $page_content .= "</div><hr />\n";
    
    $page_content .= "<div id=\"r2\">\n";
    $page_content .= "<div id=\"r2l\" class=\"left\">\n";
    $page_content .= $parser->parse(file_get_contents('firelist-left-1.md'));
    $page_content .= "</div>\n";
    $page_content .= "<div id=\"r2r\" class=\"right\">\n";
    $page_content .= $parser->parse(file_get_contents('firelist-right-1.md'));
    $page_content .= "</div>\n";
    $page_content .= "</div>\n<hr />\n";
    
    $page_content .= "<div id=\"r3\">\n";
    $page_content .= "<div id=\"r3l\" class=\"left\">\n";
    $page_content .= $parser->parse(file_get_contents('firelist-left-2.md'));
    $page_content .= "</div>\n";
    #$page_content .= "<div id=\"r3r\" class=\"right\">\n";
    #$page_content .= $parser->parse(file_get_contents('firelist-right-2.md'));
    #$page_content .= "</div>\n";
    $page_content .= "</div>\n<hr />\n";
    
    $page_content .= "<div id=\"r4\">\n";
    $page_content .= "<div id=\"r4l\" class=\"left\">\n";
    $page_content .= $parser->parse(file_get_contents('firelist-left-3.md'));
    $page_content .= "</div>\n";
    #$page_content .= "<div id=\"r4r\" class=\"right\">\n";
    #$page_content .= $parser->parse(file_get_contents('firelist-right-3.md'));
    #$page_content .= "</div>\n";
    $page_content .= "</div>\n";
    break;
}

// Print the page
$template = "template.xhtml";
if(is_file($template))
{
  $template = file_get_contents($template); // Variable reassignment surgery.

  $template = str_replace('/*TITLE*/', $page_title, $template);
  $template = str_replace('/*HEADER*/', $page_header, $template);
  $template = str_replace('/*NAVIGATION*/', $page_navigation, $template);
  $template = str_replace('/*CONTENT*/', $page_content, $template);
}

header('Content-type: text/html');
header("X-Clacks-Overhead: GNU Terry Pratchett");
#header("Cache-Control: no-cache, must-revalidate");
#header("Expires: Wed, 31 Dec 1969 11:59:59 GMT");
echo $template;

?>

