/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.scripts
{
import com.voxelengine.worldmodel.models.ControllableVoxelModel;
import com.voxelengine.worldmodel.models.types.Beast;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.models.types.Zeppelin;
import com.voxelengine.worldmodel.weapons.Gun;
import com.voxelengine.worldmodel.weapons.Projectile;

import flash.utils.getDefinitionByName;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.worldmodel.scripts.*;

public class ScriptLibrary
{
	public function ScriptLibrary() {}

	public static function getScripts( $vm:VoxelModel ):Vector.<String> {

		var _scriptList:Vector.<String> = new Vector.<String>();
		if ( $vm is Gun ) {
			_scriptList.push("FireProjectileScript");
			_scriptList.push("BombScript");
			_scriptList.push("AutoFireProjectileScript");
			_scriptList.push("ExplosionScript");
		}
		else if ( $vm is Projectile ) {
			_scriptList.push("ExplosionScript");
		}
		else if ( $vm is Beast ) {
			_scriptList.push("ControlBeastScript");
		}
		else if ( $vm is Zeppelin || $vm is ControllableVoxelModel ) {
			_scriptList.push("ControlObjectScript");
			_scriptList.push("AutoControlObjectScript");
		}
		else {
			_scriptList.push( RotateAroundYScript.ROTATE_AROUND_Y_SCRIPT );
			_scriptList.push( RotateScript.ROTATE_SCRIPT );
			_scriptList.push( BobbleScript.BOBBLE_SCRIPT );
			_scriptList.push( ComeToMeScript.COME_TO_ME_SCRIPT );
		}
		return _scriptList;
	}

	public static function getAsset ( assetLinkageID : String ) : Class {
		// placeholder class declarations
		ControlObjectScript;
		AutoControlObjectScript;
		ControlBeastScript;
		DefaultScript;
		FireProjectileScript;
		BombScript;
		AutoFireProjectileScript;
		ExplosionScript;
		AcidScript;
		IceScript;
		FireScript;
		DragonFireScript;
		RotateAroundYScript;
		RotateScript;
		BobbleScript;


		var asset:Class;
		try {
			asset = Class ( getDefinitionByName ( "com.voxelengine.worldmodel.scripts." + assetLinkageID ) );
		} catch ( error:Error ) {
			asset = Class ( getDefinitionByName ( "com.voxelengine.worldmodel.scripts.DefaultScript" ) );
			Log.out( "ScriptLibrary.getAsset - ERROR - ERROR - ERROR: " + error + " not found: " + assetLinkageID, Log.ERROR );
		}

		return asset;
	}
}
}

