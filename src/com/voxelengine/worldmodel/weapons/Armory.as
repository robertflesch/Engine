/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.weapons
{
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.weapons.Ammo;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class Armory {

	public static const WEAPON_TYPE_HANDGUN:String = "WEAPON_TYPE_HANDGUN";
	public static const WEAPON_TYPE_RIFLE:String = "WEAPON_TYPE_RIFLE";
	public static const WEAPON_TYPE_CANNON:String = "WEAPON_TYPE_CANNON";
	public static const WEAPON_TYPE_BOMB:String = "WEAPON_TYPE_BOMB";
	public static const DEFAULT_WEAPON_TYPE:String = WEAPON_TYPE_HANDGUN;

	private var _selectedAmmoIndex:int;
	private var _ammos:Vector.<Ammo> = new Vector.<Ammo>;

	public function Armory()  {
	}
	
	public function add( $ammo:Ammo ):void {
		_ammos.push( $ammo );
	}

	public function remove( $ammo:Ammo ):void {
		for ( var i:int = 0; i < _ammos.length; i++ ) {
			if ( _ammos[i] && $ammo.name == _ammos[i].name )
				_ammos.splice( i, 1);
		}
	}

	public function currentSelection():Ammo {
		if ( _ammos.length ) {
			if ( _selectedAmmoIndex >= _ammos.length )
				_selectedAmmoIndex = 0;
				
			return _ammos[_selectedAmmoIndex];	
		}
		
		var ammo:Ammo = new Ammo( "blank", null, {} );
		return ammo;
	}
	
	public function getAmmoList():Vector.<Ammo> {
		return _ammos;
	}
	
	public function getAmmoByName( $name:String ):Ammo {
		for ( var i:int = 0; i < _ammos.length; i++ ) {
			if ( _ammos[i] && $name == _ammos[i].name )
				return _ammos[i];
		}
		return currentSelection();
	}
}
}
