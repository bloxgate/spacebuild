$modelname      "n3x15/motor/electric_motor.mdl"
$scale          10
$staticprop
$surfaceprop    "metal"
$cdmaterials    "models/n3x15/motor"
$body motor     "electric_motor_ref.dmx"
$sequence idle  "electric_motor_ref.dmx" // no animation wanted, so re-using the reference mesh
//$renamematerial "materials/models/n3x15/motor/Material" "electric_motor"

$collisionmodel	"electric_motor_phys.dmx" { $concave }