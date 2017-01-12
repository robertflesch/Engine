/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models.types
{
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
				//$dbo.modelGuid = "2C18D274-DE77-6BDD-1E7B-816BFA7286AE"
				$dbo.modelGuid = "Player"
				
				var userName:String = $dbo.key.substring( 6 );
				var firstChar:String = userName.substr(0, 1); 
				var restOfString:String = userName.substr(1, userName.length); 
				$dbo.userName = firstChar.toUpperCase() + restOfString.toLowerCase();
				$dbo.description = "New Player Avatar";
				$dbo.modifiedDate = new Date().toUTCString();
				$dbo.createdDate = new Date().toUTCString();
				$dbo.save();
			}
			
			//var ii:InstanceInfo = new InstanceInfo();
			//ii.modelGuid = "Player";
			//ii.instanceGuid = Network.userId;
			//new ModelMakerLocal( ii );
			//Log.out( "Avatar.onPlayerLoadedAction - START TEMPORARILY CREATING Avatar FROM SCRIPT", Log.WARN );
			createPlayer( "DefaultPlayer", Network.userId )
			//Log.out( "Avatar.onPlayerLoadedAction - END TEMPORARILY CREATING Avatar FROM SCRIPT", Log.WARN );
		}
		else {
			Log.out( "Avatar.onPlayerLoadedAction - ERROR, failed to create new record for ?" );
		}
	}
	
	static public function onPlayerLoadError(error:PlayerIOError):void {
		Log.out("Avatar.onPlayerLoadError", Log.ERROR, error );
	}			
	
	static public function createPlayer( $modelGuid:String = "DefaultPlayer", $instanceGuid:String = "Player" ):void	{
		//Log.out( "Player.createPlayer - creating from LOCAL", Log.DEBUG );
		//var ii:InstanceInfo = new InstanceInfo();
		//ii.modelGuid = "Player";
		//ii.instanceGuid = "Player";
		//// Something is listen for this to generate some event.
		//ModelMakerBase.load( ii );
		
		Log.out( "Avatar.createPlayer - creating from GenerateCube", Log.DEBUG )
		var model:Object = GenerateCube.script()
		model.modelClass = "Player"

		var ii:InstanceInfo = new InstanceInfo()
		ii.modelGuid = $modelGuid;
		ii.instanceGuid = $instanceGuid;
		
		new ModelMakerGenerate( ii, model )
	}
	
}
}