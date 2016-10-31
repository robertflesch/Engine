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
import com.voxelengine.worldmodel.models.OxelPersistance;

import flash.utils.getTimer;

/**
 * ...
 * @author Robert Flesch
 */
public class FromByteArray extends AbstractTask 
{	
	private var	_guid:String;
	private var	_altGuid:String;
	private var	_parent:OxelPersistance;
    //private static const TASK_PRIORITY:int = 64000;

	static public function addTask( $guid:String, $taskPriority:int, $parent:OxelPersistance, $altGuid:String ): void {
		var fba:FromByteArray = new FromByteArray( $guid, $taskPriority, $parent, $altGuid );
		Globals.g_landscapeTaskController.addTask( fba )
	}
	
//public function AbstractTask(type:String, priority:int = 5, uid:Object = null, selfOverride:Boolean = false, blocking:Boolean = false)	
	public function FromByteArray( $guid:String, $taskPriority:int, $parent:OxelPersistance, $altGuid:String ):void {
		_guid = $guid;
		_parent = $parent;
		_altGuid = $altGuid;
		super("FromByteArray", $taskPriority );
		LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );
	}
	
	override public function start():void {
		super.start()

		Log.out( "FromByteArray.start: guid: " + _guid );
		var time:int = getTimer();
		_parent.fromByteArray();

		if ("0" == _parent.dbo.key) {
			_parent.changed = true;
			_parent.guid = _guid;
			// When import objects, we have to update the cache so they have the correct info.
			if (null != _altGuid)
				OxelDataEvent.dispatch(new OxelDataEvent(ModelBaseEvent.UPDATE_GUID, 0, _altGuid + ":" + _guid, null));
			_parent.save();
		}
		OxelDataEvent.dispatch(new OxelDataEvent(OxelDataEvent.OXEL_READY, 0, _guid, _parent));

		LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.DESTROY ) );
		super.complete()
		Log.out( "FromByteArray.start: took: " + (getTimer() - time) + "  guid: " + _guid );
	}
}
}
