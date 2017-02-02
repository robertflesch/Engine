/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;

import playerio.PlayerIOError;
import playerio.DatabaseObject;

import com.voxelengine.Globals;
import com.voxelengine.Log;

import com.voxelengine.server.Network

import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ControllableVoxelModel;
import com.voxelengine.worldmodel.models.ModelMetadata;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.makers.ModelMakerGenerate;
import com.voxelengine.worldmodel.tasks.landscapetasks.GenerateCube


public class Avatar extends ControllableVoxelModel
{
	public function Avatar( instanceInfo:InstanceInfo ) 
	{ 
		//Log.out( "Avatar CREATED" );
		super( instanceInfo );
	}
	
	override public function init( $mi:ModelInfo, $vmm:ModelMetadata ):void {
		super.init( $mi, $vmm );
	}
	
	static public function buildExportObject( obj:Object ):Object {
		ControllableVoxelModel.buildExportObject( obj );
		return obj;
	}
	
	// This does not belong here
	static public function onPlayerLoadedAction( $dbo:DatabaseObject ):void {
		
		if ( $dbo ) {
			if ( null == $dbo.modelGuid ) {
				// Assign the Avatar the default avatar
				//$dbo.modelGuid = "Player"
				$dbo.modelGuid = "58467A21-E8B2-E558-6778-69AD35AC33A1";

				var userName:String = $dbo.key.substring( 6 );
				var firstChar:String = userName.substr(0, 1); 
				var restOfString:String = userName.substr(1, userName.length); 
				$dbo.userName = firstChar.toUpperCase() + restOfString.toLowerCase();
				$dbo.description = "New Player Avatar";
				$dbo.modifiedDate = new Date().toUTCString();
				$dbo.createdDate = new Date().toUTCString();
				$dbo.save();
			}
			
			createPlayer( "DefaultPlayer", Network.userId );
		}
		else {
			Log.out( "Avatar.onPlayerLoadedAction - ERROR, failed to create new record for ?" );
		}
	}
	
	static public function onPlayerLoadError(error:PlayerIOError):void {
		Log.out("Avatar.onPlayerLoadError", Log.ERROR, error );
	}			
	
	static public function createPlayer( $modelGuid:String = "DefaultPlayer", $instanceGuid:String = "Player" ):void	{
/*
		var ii:InstanceInfo = new InstanceInfo();
		//ii.modelGuid = "Player";
		ii.modelGuid = "58467A21-E8B2-E558-6778-69AD35AC33A1";
		ii.instanceGuid = Network.userId;
		ModelMakerBase.load( ii, false );
*/
		Log.out( "Avatar.createPlayer - creating from GenerateCube", Log.DEBUG )
		var model:Object = GenerateCube.script();
		model.modelClass = "Player";

		var ii:InstanceInfo = new InstanceInfo()
		ii.modelGuid = $modelGuid;
		ii.instanceGuid = $instanceGuid;
		
		new ModelMakerGenerate( ii, model )
	}

	override public function collisionTest( $elapsedTimeMS:Number ):Boolean {

//		if ( this === VoxelModel.controlledModel )
		{
			// check to make sure the ship or object you were on was not destroyed or removed
			//if ( lastCollisionModel && lastCollisionModel.instanceInfo.dead )
			//lastCollisionModelReset();

			if ( false == controlledModelChecks( $elapsedTimeMS ) )
			{
				stateSet( "PlayerAniStand", 1 ); // Should be crash?
				return false;
			}
			else
				setAnimation();
		}

		return true;
	}


	override protected function setAnimation():void	{

		/*if ( EditCursor.toolOrBlockEnabled )
		 {
		 stateSet( "Pick", 1 );
		 }*/

		if ( -0.4 > instanceInfo.velocityGet.y )
		{
			updateAnimations( "Jump", 1 );
		}
		else if ( 0.4 < instanceInfo.velocityGet.y )
		{
			updateAnimations( "Fall", 1 );
		}
		else if ( 0.2 < Math.abs( instanceInfo.velocityGet.z )  )
		{
			updateAnimations( "Walk", 2 );
		}
		else if ( 0.2 < Math.abs( instanceInfo.velocityGet.x )  )
		{
			updateAnimations( "Slide", 1 );
		}
		else
		{
			stateSet( "Stand", 1 );
		}
		//trace( "Player.update - end" );
	}


}
}