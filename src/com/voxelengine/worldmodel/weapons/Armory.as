/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.weapons
{
import com.voxelengine.worldmodel.weapons.Ammo;

/**
 * ...
 * @author Robert Flesch - RSF 
 */
public class Armory 
{
	private var _selectedAmmoIndex:int;
	private var _ammos:Vector.<Ammo> = new Vector.<Ammo>;
	
	public function Armory()  { 
	}
	
	public function add( $ammo:Ammo ):void {
		_ammos.push( $ammo );
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
		for ( var i:int; i < _ammos.length; i++ ) {
			if ( _ammos[i] && $name == _ammos[i].name )
				return _ammos[i];
		}
		return currentSelection();
	}
}
}
