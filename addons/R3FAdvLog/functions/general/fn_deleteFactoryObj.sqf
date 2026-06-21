private ["_object"];

_object = cursorTarget;

if (isNull _object) exitWith {false};

if (_object getVariable ["R3F_LOG_CF_depuis_factory", false] == true) then
{
	deleteVehicle _object;
	true
}
else
{
	false
};
