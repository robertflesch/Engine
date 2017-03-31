/*==============================================================================
  Copyright 2011-2017 Robert Flesch
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
import com.voxelengine.worldmodel.models.OxelPersistence;

import flash.utils.getTimer;

/**
 * ...
 * @author Robert Flesch
 */
public class FromByteArray extends AbstractTask 
{	
	private var	_guid:String;
	private var	_op:OxelPersistence;

	static public function addTask( $guid:String, $taskPriority:int, $parent:OxelPersistence ): void {
		//Log.out( "FromByteArray.addTask: guid: " + $guid + "  taskPriority: " + $taskPriority + "  op: " + $parent, Log.WARN );
		var fba:FromByteArray = new FromByteArray( $guid, $taskPriority, $parent );
		Globals.g_landscapeTaskController.addTask( fba )
	}
	
	public function FromByteArray( $guid:String, $taskPriority:int, $parent:OxelPersistence ):void {
		_guid = $guid;
		_op = $parent;
		super("FromByteArray", $taskPriority );
		LoadingImageEvent.dispatch( new LoadingImageEvent( LoadingImageEvent.CREATE ) );
	}
	
	override public function start():void {
		super.start();
		//var time:int = getTimer();

		try {
			// The ModelMakerImporter tries to double load the byte array.
			// Rather then mess with importer, this work around was added RSF.
			Log.out("FromByteArray.start: guid: " + _guid, Log.WARN);
			if ( 0 == _op.oxelCount) {
				_op.ba.position = 0;
				_op.loadFromByteArray();

				if ("0" == _op.dbo.key) {
					_op.changed = true;
				}
			}
			OxelDataEvent.create( OxelDataEvent.OXEL_READY, 0, _guid, _op );
		}
		catch ( e:Error ) {
			Log.out( "FromByteArray.start: ERROR: " + e.toString(), Log.ERROR, e );
			OxelDataEvent.create( OxelDataEvent.OXEL_FAILED, 0, _guid, _op );
		}
		LoadingImageEvent.dispatch(new LoadingImageEvent(LoadingImageEvent.DESTROY));
		super.complete();
		//Log.out( "FromByteArray.start: took: " + (getTimer() - time) + "  guid: " + _guid );
	}
}
}
