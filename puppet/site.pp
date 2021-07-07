## Setup for setting NOOP mode via Hiera. In hiera this can be applied to
## an environment or node.

if $::enable_noop == true {
  noop()
}


##--------------------------------------------------------------------
## Provides for ensuring that dns domain names are lowercase for Hiera
## Lookups.
##
## $domain_hiera is only intended for hiera.yaml, use requires
## puppetlabs/stdlib.
##
## Must be set before the "include classification" call
##--------------------------------------------------------------------

$domain_hiera = downcase($::domain)
$domain_short = regsubst($domain_hiera,'^(\w+)\.(\w+)\.(\w+)$','\1')
$forest_short = $domain_short ? {
  'sub1' => 'for1',
  'sub2' => 'for1',
  'sub3' => 'for2',
  'sub4' => 'for3',
  'sub5' => 'for4',
}

##------------------------------------------------------------------------
## Providing the coding for doing role assignments from vRO/Trusted_fact
##  or from hiera/nodes assignment.
##------------------------------------------------------------------------

## -- vRO trusted_role assignment
##    Array trusted_roles  -- needs to be array to "merge" below with classes
##    String trusted_role_hiera  -- needs to be a string to work for hiera role
##
### first - determine if this host HAS a `::trusted[extensions][pp_role]`

if has_key($::trusted['extensions'], 'pp_role') {
  $trusted_roles = [ $::trusted['extensions']['pp_role'], ]

  ## Since hiera roles are filename references, in combined environments
  ## we need to avoid restricted characters in Windows pathrefs.

  $trusted_role_hiera = regsubst($::trusted['extensions']['pp_role'], '::', '_', 'G')
  $role_app_type = regsubst($trusted_role_hiera, 'role_', '', 'G')

} else {

  ## default role
  $trusted_roles = [ 'role::srv', ]
  $trusted_role_hiera = 'role_srv'

}

## -- The following two lines provide Hiera lookup methods for assignment
##      or exclusion of specific classes

$classes = lookup('classes', Array[String], 'unique')
$class_exclusions = lookup('class_exclusions', Array[String], 'unique')

## -- this ties it all together

$classification = $trusted_roles + $classes - $class_exclusions
include $classification
