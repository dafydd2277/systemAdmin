<?php

/**
 * This is the badge generation class file.
 *
 * This file takes information on the sizes and offsets of badge elements
 * and assembles individual badges, badge jpg-format "pages," and a zip
 * file containing all the individual pages.
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
class badges {
	var $background = '';
	var $element_offsets = '';
	var $lam_sheet = '';
	var $margins = '';
	var $page_w = 0;
	var $page_h = 0;
	var $positions = '';
	var $sources = '';

	/**
	 * assembles the background image, user photograph, and printed information
	 * in the correct position on the page.
	 *
	 * @param integer $position The position on the page.
	 * @param array $data Associative array of subject information.
	 * @return void
	 */
	function assemble_badge ($position, $data) {
		# Set variable short names.
		$pos_x = $this->positions[$position . 'x'];
		$pos_y = $this->positions[$position . 'y'];

		$bg_offset_x = $pos_x;
		$bg_offset_y = $pos_y;
		$bg_width = $this->element_offsets['background']['width'];
		$bg_height = $this->element_offsets['background']['height'];

		$photo = imagecreatefromjpeg($data['photo']);
		$stats = getimagesize($data['photo']);
		$ph_offset_x = $pos_x + $this->element_offsets['photo']['offset_x'];
		$ph_offset_y = $pos_y + $this->element_offsets['photo']['offset_y'];
		$ph_width = $this->element_offsets['photo']['width'];
		$ph_height = $this->element_offsets['photo']['height'];

		/*
		* Place images. Setting numeric widths and heights eliminates the need
		* to resize the logo or photograph by hand. The background is created
		* in the correct dimensions, so resizing is unnecessary.
		*/
		$result = imagecopyresampled($this->lam_sheet, $this->background,
			$pos_x, $pos_y,			# Top left position point on the page.
			0, 0,					# Top left corner of the image.
			$bg_width, $bg_height,	# W/H of image on the page.
			$bg_width, $bg_height); # W/H of source image.
		$result = imagecopyresampled($this->lam_sheet, $photo,
			$ph_offset_x, $ph_offset_y,
			0, 0,
			$ph_width, $ph_height,
			$stats[0], $stats[1]);

		// Release the photo memory.
		$result = imagedestroy($photo);

		// Place lines
		$lines = array('line1', 'line2', 'line3', 'line4', 'line5');
		foreach ($lines as $line) {

			// Set variable short names.
			$line_text =  $data[$line];
			$font_family = $this->element_offsets[$line]['font_family'];
			$font_size = $this->element_offsets[$line]['font_size'];
			$font_style = $this->element_offsets[$line]['font_style'];
			$text_align = $this->element_offsets[$line]['text_align'];
			$red = $this->element_offsets[$line]['red'];
			$green = $this->element_offsets[$line]['green'];
			$blue = $this->element_offsets[$line]['blue'];
			$line_offset_x = $pos_x + $this->element_offsets[$line]['offset_x'];
			$line_offset_y = $pos_y + $this->element_offsets[$line]['offset_y'];
			$max_length = $this->element_offsets[$line]['max_length'];

			// Set the color
			$line_color = imagecolorallocate($this->lam_sheet, $red, $green, $blue);

			// Get the initial length.
			$corners = imagettfbbox($font_size, 0, $font_family, $line_text);
			$line_length = $corners[2] - $corners[0];

			// Does the printed line exceed the limits of the text field?
			while ($line_length > $max_length):
				// Reduce the font by 2 points, and retry.
				$font_size -= 2;
				$corners = imagettfbbox($font_size, 0, $font_family, $line_text);
				$line_length = $corners[2] - $corners[0];
			endwhile;

			/*
			* $line_offset_x is set to the center of the line. However,
			* imagettftext works from the top left corner. So, adjust the
			* offest by half the line length.
			*/
			$line_offset_x -= ($line_length / 2);

			// Print the line.
			$corners = imagettftext($this->lam_sheet, $font_size, 0, $line_offset_x,
				$line_offset_y, $line_color, $font_family, $line_text);
		} // foreach ($lines as $line)

	} // function assemble_badge ($position, $data)

	/**
	 * sends the final page of ID badges to a file. Then, finds all
	 * badge pages, and assembles them into a zip file.
	 *
	 * @param void
	 * @return string Zip file name.
	 */
	function close_badges () {
		// Check the last page, and kill it, if necessary.
		if (is_resource($this->lam_sheet)) {
			$result = $this->close_page();
		}

		// Release the background image.
		$result = imagedestroy($this->background);

		// Gather the pages into a zip file, and return the name of the file.
		$datecode = date('dHis');
		$zipfile = $this->sources['work_dir'] . '/' . $this->sources['dc'] .
			'-badges-' . $datecode . '.zip';

		$command = 'cd ' . $this->sources['work_dir'] . '; zip -jq ' . $zipfile .
			' badges/' . $this->sources['dc'] . '-badges*';

		system ($command);

		system ('rm -rf ' . $this->sources['work_dir'] . '/badges/*');

		return $zipfile;
	} // function close_badges()

	/**
	 * Sends an individual badge page to a file.
	 *
	 * @param void
	 * @return string Name of the individual file.
	 */
	function close_page () {
		$page = 0;

		// Set the file name.
		if (is_dir($this->sources['work_dir'] . '/badges/') === FALSE) {
			$result = mkdir($this->sources['work_dir'] . '/badges/', 0777) or
				die ("Couldn't create a badges directory:" .
				$this->sources['work_dir'] . "/badges.");
		}

		$files = array();
		$handle = opendir($this->sources['work_dir'] . '/badges');
		while (false !== ($file = readdir($handle)))
	    	{
		        if ($file != "." && $file != "..")
			{
				$files[] = $file;
			}
		}
		closedir($handle);

		/*
		* Get the largest page number of existing pages, and close the current
		* page with an incremented page number.
		*/
		foreach ($files as $file) {
			if (preg_match('/' . $this->sources['dc'] . '-badges/', $file) > 0) {
				$elements = explode('.', $file);
				if (is_numeric($elements[1]) &&
					$elements[1] > $page) {
					$page = $elements[1];
				}
			}
		}
		$page++;

		// Create the file name.
		$filename = $this->sources['work_dir'] . '/badges/' .
			$this->sources['dc'] . '-badges.' . $page . '.jpg';

		// Save the page
		$result = imagejpeg($this->lam_sheet, $filename, 100);

		// Kill the resource
		$result = imagedestroy($this->lam_sheet);

		return $filename;
	}

	/**
	 * creates a new blank jpg background on which to place 12 badges.
	 *
	 * @param void
	 * @return void
	 */
	function open_page () {
		// Create the sheet
		$this->lam_sheet =
			imagecreatetruecolor($this->page_w, $this->page_h);

		// Give it a white background.
		$white = imagecolorallocate($this->lam_sheet, 255, 255, 255);
		$result = imagefilledrectangle($this->lam_sheet,
			0, 0,
			$this->page_w, $this->page_h,
			$white);
	}

	/**
	 * Assigns the filename of the badge background image.
	 *
	 * @param string File name of the badge background image.
	 * @return void
	 */
	function set_background ($background) {
		$this->background = imagecreatefromjpeg($background);
	}

	/**
	 * Assigns the page width and height.
	 *
	 * @param array $values Associative array of page width and height.
	 * @return void
	 */
	function set_dimensions ($values) {
		$this->page_w = $values['page_w'];
		$this->page_h = $values['page_h'];
	}

	/**
	 * Sets the offset values for all properties of an individual badge.
	 *
	 * @param array $offsets Associative array of badge element offsets.
	 * @return void
	 */
	function set_element_offsets ($offsets) {
		$this->element_offsets = $offsets;
	}

	/**
	 * Sets the top/left positions of the individual badges.
	 *
	 * @param $positions Associative array of individual badge positions.
	 * @return void
	 */
	function set_positions ($positions) {
		$this->positions = $positions;
	}

	/**
	 * Sets the directory name and department code of the badge files.
	 *
	 * @param array $sources Associative array
	 * @return void
	 */
	function set_sources ($sources) {
		$this->sources = $sources;
	}

} // class Badges ()

?>
