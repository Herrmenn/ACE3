/*
 * Author: commy2
 * Calculate light intensity object 1 recieves from object 2
 *
 * Arguments:
 * 0: Object that recieves light <OBJECT>
 * 1: Object that emits light <OBJECT>
 *
 * Return Value:
 * Brightest light level
 *
 * Public: Yes
 */
#include "script_component.hpp"

params ["_unit", "_lightSource"];

private _unitPos = _unit modelToWorld (_unit selectionPosition "spine3");
private _lightLevel = 0;

if (_lightSource isKindOf "CAManBase") then {
    // handle persons with flashlights

    private _weapon = currentWeapon _lightSource;

    if !(_lightSource isFlashlightOn _weapon) exitWith {};

    private _flashlight = (_lightSource weaponAccessories _weapon) select 1;

    if (getNumber (configFile >> "CfgWeapons" >> _flashlight >> "ACE_laserpointer") == 1) exitWith {_lightLevel = 0};

    private _properties = [[_flashlight], FUNC(getLightPropertiesWeapon), uiNamespace, format [QEGVAR(cache,%1_%2), QUOTE(DFUNC(getLightPropertiesWeapon)), _flashlight], 1E11] call FUNC(cachedCall);
    //_properties = [_flashlight] call FUNC(getLightPropertiesWeapon);

    private _innerAngle = (_properties select 3) / 2;
    private _outerAngle = (_properties select 4) / 2;

    private _position = _lightSource modelToWorld (_lightSource selectionPosition "rightHand");
    private _direction = _lightSource weaponDirection _weapon;

    private _directionToUnit = _position vectorFromTo _unitPos;

    private _distance = _unitPos distance _position;
    private _angle = acos (_direction vectorDotProduct _directionToUnit);

    _lightLevel = (linearConversion [0, 30, _distance, 1, 0, true]) * (linearConversion [_innerAngle, _outerAngle, _angle, 1, 0, true]);

} else {
    // handle any object, strcutures, cars, tanks, etc. @todo campfires, burning vehicles

    private _lights = _lightSource call FUNC(getTurnedOnLights);

    {
        private _properties = [[_lightSource, _x], FUNC(getLightProperties), uiNamespace, format [QEGVAR(cache,%1_%2_%3), QUOTE(DFUNC(getLightProperties)), typeOf _lightSource, _x], 1E11] call FUNC(cachedCall);
        //_properties = [_lightSource, _x] call FUNC(getLightProperties);

        // @todo intensity affects range?
        //_properties params ["_intensity"];

        private _innerAngle = (_properties select 3) / 2;
        private _outerAngle = (_properties select 4) / 2;

        // get world position and direction
        private _position = _lightSource modelToWorld (_lightSource selectionPosition (_properties select 1));
        private _direction = _lightSource modelToWorld (_lightSource selectionPosition (_properties select 2));

        _direction = _position vectorFromTo _direction;
        private _directionToUnit = _position vectorFromTo _unitPos;

        private _distance = _unitPos distance _position;
        private _angle = acos (_direction vectorDotProduct _directionToUnit);

        _lightLevel = _lightLevel max ((linearConversion [0, 30, _distance, 1, 0, true]) * (linearConversion [_innerAngle, _outerAngle, _angle, 1, 0, true]));

        //systemChat  format ["%1 %2", (linearConversion [0, 30, _distance, 1, 0, true]), (linearConversion [_innerAngle, _outerAngle, _angle, 1, 0, true])];

    } forEach _lights;

    // handle campfires
    if (inflamed _lightSource) then {
        private _distance = _unitPos distance position _lightSource;

        _lightLevel = _lightLevel max linearConversion [0, 30, _distance, 0.5, 0, true];
    };

};

_lightLevel
