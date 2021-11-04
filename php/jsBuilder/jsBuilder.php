<?php

$elements = array(
	'userName'	=> 'validateText',
	'password1'	=> 'validatePasswords',
	'password2'	=> 'validatePasswords',
	'firstName'	=> 'validateText',
	'lastName'	=> 'validateText',
	'birthdate'	=> 'validateDOB',
	'street1'	=> 'validateText',
	'street2'	=> 'validateText',
	'city'		=> 'validateText',
	'state'		=> 'validateText',
	'zip'		=> 'validateZip',
	'phone'		=> 'validatePhone',
	'email'		=> 'validateEmail'
);

$phpSetElements = "var formName = document.getElementById['formName'];\n";
$phpAddEventListeners =
	"\tformName.addEventListener('submit', validateForm, false);\n";
$phpAttachEvents = "\tformName.attachEvent('onsubmit', validateForm);\n";
$phpEvents = "\tformName.onsubmit = validateForm;\n";
$phpValidateForm = '';

foreach ($elements as $element => $action) {
	$phpSetElements .= "var " . $element .
		" = document.getElementById['" .
		$element .
		"'];\n";
	
	$phpAddEventListeners .= "\t" .
		$element .
		".addEventListener('focus', clean(" .
		$element .
		"), false);\n";
		
	$phpAddEventListeners .= "\t" .
		$element .
		".addEventListener('blur', " .
		$action .
		"(" .
		$element .
		"), false);\n";
	
	$phpAttachEvents .= "\t" .
		$element .
		".attachEvent('onfocus', clean(" .
		$element .
		");\n";
	
	$phpAttachEvents .= "\t" .
		$element .
		".attachEvent('onblur', " .
		$action .
		"(" .
		$element .
		");\n";
	
	$phpEvents .= "\t" .
		$element .
		".onfocus = clean(" .
		$element .
		");\n";
	
	$phpEvents .= "\t" .
		$element .
		".onblur = " .
		$action .
		"(" .
		$element .
		");\n";
	
	$phpValidateForm .= "\t" .
		"isValid = " .
		$action .
		"(" .
		$element .
		") ? isValid : false;\n";
}

$template = file_get_contents('jsTemplate.txt');

$template = str_replace('/* phpSetElements */', rtrim($phpSetElements), $template);
$template = str_replace('/* phpAddEventListeners */', rtrim($phpAddEventListeners), $template);
$template = str_replace('/* phpAttachEvents */', rtrim($phpAttachEvents), $template);
$template = str_replace('/* phpEvents */', rtrim($phpEvents), $template);
$template = str_replace('/* phpValidateForm */',rtrim($phpValidateForm), $template);

header ('Content-type: text/javascript');
echo $template;

?>

