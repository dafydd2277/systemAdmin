<?php

/**
 * This is a sample badge generation file.
 *
 * This file sets an array of positions and offsets for a page of 12 badges.
 * The size of an individual badge is 1013px by 600px, and they are combined
 * into jpg image "pages" of 3039px x 2400px. These dimensions are for
 * landscape oriented pages. The possibility of portrait-orientated pages is
 * allowed in the code.
 *
 * This file is released under
 * [@link http://creativecommons.org/licenses/by-nc-sa/3.0/ Creative Commons
 * Attribution Noncommercial Share-Alike 3.0 License]. You may modify this
 * code, but you may not republish it without crediting me. Thank you.
 *
 * @author David Barr
 * @copyright David Barr 2009
 * @version 0.1
 *
 */

require 'class_badges.php';


/*
* Page layout.
* 'p' for portrait
* 'l' for landscape
*/
$layout = 'l';

/*
 * Width, Height, and Position values are in pixels. Font size values are in
 * points.
 *
 * Offsets are relative to the top left corner of the badge.
 */
$offsets = array(
  'background' => array(
    'width' => 1013,
    'height' => 600
  ),
  'logo' => array(
    'offset_x' => 712,
    'offset_y' => 195,
    'width' => 282,
    'height' => 282
  ),
  'photo' => array(
    'offset_x' => 60,
    'offset_y' => 160,
    'width' => 225,
    'height' => 300
  ),
  'line1' => array(
    'font_family' => '/usr/share/fonts/truetype/arial.ttf',
    'font_size' => 80,
    'font_style' => 'B',  // Bold
    'text_align' => 'C',  // Center, but other options aren't coded.
    'red' => 255,         // 0-255
    'green' => 255,        // 0-255
    'blue' => 255,        // 0-255
    'offset_x' => 506,
    'offset_y' => 125,
    'max_length' => 950    // Maximum line length, in pixels.
  ),
  'line2' => array(
    'font_family' => '/usr/share/fonts/truetype/arial.ttf',
    'font_size' => 48,
    'font_style' => 'B',
    'text_align' => 'C',
    'red' => 255, # 0-255
    'green' => 255, # 0-255
    'blue' => 255, # 0-255
    'offset_x' => 506,
    'offset_y' => 225,
    'max_length' => 400
  ),
  'line3' => array(
    'font_family' => '/usr/share/fonts/truetype/arial.ttf',
    'font_size' => 36,
    'font_style' => 'B',
    'text_align' => 'C',
    'red' => 255, # 0-255
    'green' => 255, # 0-255
    'blue' => 255, # 0-255
    'offset_x' => 506,
    'offset_y' => 325,
    'max_length' => 400
  ),
  'line4' => array(
    'font_family' => '/usr/share/fonts/truetype/arial.ttf',
    'font_size' => 36,
    'font_style' => 'B',
    'text_align' => 'C',
    'red' => 255, # 0-255
    'green' => 255, # 0-255
    'blue' => 255, # 0-255
    'offset_x' => 506,
    'offset_y' => 400,
    'max_length' => 400
  ),
  'line5' => array(
    'font_family' => '/usr/share/fonts/truetype/arial.ttf',
    'font_size' => 36,
    'font_style' => 'B',
    'text_align' => 'C',
    'red' => 255, # 0-255
    'green' => 255, # 0-255
    'blue' => 255, # 0-255
    'offset_x' => 506,
    'offset_y' => 475,
    'max_length' => 400
  )
);

/*
* If the badges are of a consistent size, year over year, then
* $positions_landscape and $positions_portrait shouldn't need to change. In a
* landscape orientation, the individual badges are 1013px wide and 600px
* high. Reverse the values for portrait orientation.
*/
$positions_landscape = array(
  '1x' => 0,      '1y' => 0,
  '2x' => 0,      '2y' => 601,
  '3x' => 0,      '3y' => 1201,
  '4x' => 0,      '4y' => 1801,
  '5x' => 1014,    '5y' => 0,
  '6x' => 1014,    '6y' => 601,
  '7x' => 1014,   '7y' => 1201,
  '8x' => 1014,    '8y' => 1801,
  '9x' => 2028,    '9y' => 0,
  '10x' => 2028,  '10y' => 601,
  '11x' => 2028,  '11y' => 1201,
  '12x' => 2028,  '12y' => 1801,
);

$positions_portrait = array(
  '1x' => 0,      '1y' => 0,
  '2x' => 0,      '2y' => 1014,
  '3x' => 0,      '3y' => 2028,
  '4x' => 601,    '4y' => 0,
  '5x' => 601,    '5y' => 1014,
  '6x' => 601,    '6y' => 2028,
  '7x' => 1201,    '7y' => 0,
  '8x' => 1201,    '8y' => 1014,
  '9x' => 1201,    '9y' => 2028,
  '10x' => 1801,  '10y' => 0,
  '11x' => 1801,  '11y' => 1014,
  '12x' => 1801,  '12y' => 2028,
);

$sources = array(
  'work_dir' => '/tmp',        # Location to store the images.
  'dc' => 'esd'                # Short name of department.
);

// Identify the layout for the year.
switch ($layout) {
  case 'l':
    $positions = $positions_landscape;
    $dimensions['page_w'] = 3039;
    $dimensions['page_h'] = 2400;
    break;
  case 'p':
    $positions = $positions_portrait;
    $dimensions['page_w'] = 2400;
    $dimensions['page_h'] = 3039;
    break;
}

/*
* Generate the document for the single page tests. This is done separately
* in/for the production code, below. Comment this out for production runs.
*/
/*
$badges = new Badges();
$badges->set_background('background.jpg');  // Loc. of badge background.
$badges->set_element_offsets($offsets);
$badges->set_dimensions($dimensions);
$badges->set_positions($positions);
$badges->set_sources($sources);
*/


// Test 1: Set the photo, logo, and text element_offsets for position 1.
/*
$badges->open_page();
$data = array();
$data['photo'] = 'photo.jpg'; // File location of individual user photo.
$data['line1'] = 'Line 1';
$data['line2'] = 'Line 2';
$data['line3'] = 'Line 3';
$data['line4'] = 'Line 4';
$data['line5'] = 'Line 5';
$badges->assemble_badge(1, $data);
$outfile = $badges->close_page();

$file = basename($outfile);
$filesize = filesize($outfile);

header('Content-type: image/jpeg');
header('Content-Length: ' . $filesize);
header('Content-disposition: attachment; filename="' . $file . '"');
readfile($outfile);
*/

// Test 2: Print a page with one repeated badge, in positions 1 to 12.
/*
$badges->open_page();
$data = array();
$data['photo'] = 'photo.jpg';
$data['line1'] = 'Line 1';
$data['line2'] = 'Line 2';
$data['line3'] = 'Line 3';
$data['line4'] = 'Line 4';
$data['line5'] = 'Line 5';

for ($i = 1; $i <= 12; $i++) {
  $badges->assemble_badge($i, $data);
}

$outfile = $badges->close_page();

$file = basename($outfile);
$filesize = filesize($outfile);

header('Content-type: image/jpeg');
header('Content-Length: ' . $filesize);
header('Content-disposition: attachment; filename="' . $file . '"');
readfile($outfile);
*/


/*
* Test 3: Print two complete pages and one incomplete page of a single
* badge.
*/
/*
$data = array();
$data['photo'] = 'photo.jpg';
$data['line1'] = 'Line 1';
$data['line2'] = 'Line 2';
$data['line3'] = 'Line 3';
$data['line4'] = 'Line 4';
$data['line5'] = 'Line 5';

for ($i = 1; $i <= 34; $i++) {
  if ($i % 12 == 1) {
    $badges->open_page();
  }

  $position = $i % 12;
  if ($position == 0) {
    $position = 12;
  }

  $badges->assemble_badge($position, $data);

  if ($position == 12) {
    $result = $badges->close_page();
  }
}

$outfile = $badges->close_badges();
$file = basename($outfile);
$filesize = filesize($outfile);

header('Content-type: application/zip');
header('Content-Length: ' . $filesize);
header('Content-disposition: attachment; filename="' . $file . '"');
readfile($outfile);
*/


/*
* Production run: Print badges. Make sure the previous jpg setup and test
* code is commented out.
*/

// This is the array of all members getting badges in this run.
$members = array(
  array(
    'photo' => 'image.jpg',
    'line1' => 'Line 1',
    'line2' => 'Line 2',
    'line3' => 'Line 3',
    'line4' => 'Line 4',
    'line5' => 'Line 5'
  ),
  array(
    'photo' => 'image.jpg',
    'line1' => 'Line 1',
    'line2' => 'Line 2',
    'line3' => 'Line 3',
    'line4' => 'Line 4',
    'line5' => 'Line 5'
  ),
  # etc...
);

foreach ($members as $index => $data) {

  # Indexes start at 0. This is bad...
  $position = ($index + 1) % 12;

  if ($position == 1) {
    // If we're at position 1, we need to start a new page.
    $badges->open_page();
  }
  elseif ($position == 0) {
    // If $position is evenly divisible by 12, the modulo operator returns
    // 0.
    $position = 12;
  }

  $badges->assemble_badge($position, $data);

  if ($position == 12) {
    $badges->close_page();
  }

}

// After all the individual badges are built, close everything down,...
$outfile = $badges->close_badges();
$file = basename($outfile);
$filesize = filesize($outfile);

// ... and send the file to the user.
header('Content-type: application/zip');
header('Content-Length: ' . $filesize);
header('Content-disposition: attachment; filename="' . $file . '"');
readfile($outfile);

?>

