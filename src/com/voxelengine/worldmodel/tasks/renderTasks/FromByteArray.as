/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/

package com.voxelengine.worldmodel.tasks.renderTasks
{
import com.developmentarc.core.tasks.tasks.AbstractTask

import com.voxelengine.Log
import com.voxelengine.Globals

import com.voxelengine.events.LoadingImageEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.Region;

/**
 * ...
 * @author Robert Flesch
 */
public class FromByteArray extends AbstractTask 
{	
	private var	_guid:String
	private var	_altGuid:String
	
	static public function addTask( $guid:String, $altGuid:String ): void {
		var fba:FromByteArray = new FromByteArray( $guid, $altGuid )
		Globals.g_landscapeTaskController.addTask( fba )
	}
	
	public function FromByteArray( $guid:String, $altGuid:String = null ):void {
		_guid = $guid
		_altGuid = $altGuid
		super("FromByteArray")
		LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) )
	}
	
	override public function start():void {
		super.start()
		
		var vm:VoxelModel = getVoxelModel()
		if ( null == vm )
			return
		
		vm.modelInfo.data.fromByteArray()
				
		if ( "0" == vm.modelInfo.data.dbo.key ) {
			vm.modelInfo.data.changed = true;
			vm.modelInfo.data.guid = _guid;
			// When import objects, we have to update the cache so they have the correct info.
			if ( null != _altGuid )
				OxelDataEvent.dispatch( new OxelDataEvent( ModelBaseEvent.UPDATE_GUID, 0, _altGuid + ":" + _guid, null ) );
			vm.modelInfo.data.save();
		}
		OxelDataEvent.dispatch( new OxelDataEvent( OxelDataEvent.OXEL_READY, 0, _guid, vm.modelInfo.data ) )
					
		LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.DESTROY ) )
		super.complete()
	}
	
	protected function getVoxelModel():VoxelModel {
		return Region.currentRegion.modelCache.getModelFromModelGuid( _guid )			
	}
}
}
