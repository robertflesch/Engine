/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{

import flash.events.Event;
import flash.events.EventDispatcher;
import com.voxelengine.worldmodel.models.OxelPersistence;

public class OxelDataEvent extends ModelBaseEvent
{
	static public const OXEL_FBA_COMPLETE:String			= "OXEL_FBA_COMPLETE";
	static public const OXEL_FBA_FAILED:String				= "OXEL_FBA_FAILED";
	static public const OXEL_FACES_BUILT_PARTIAL:String		= "OXEL_FACES_BUILT_PARTIAL";
	static public const OXEL_FACES_BUILT_COMPLETE:String	= "OXEL_FACES_BUILT_COMPLETE";
	static public const OXEL_QUADS_BUILT_PARTIAL:String		= "OXEL_QUADS_BUILT_PARTIAL";
	static public const OXEL_QUADS_BUILT_COMPLETE:String	= "OXEL_QUADS_BUILT_COMPLETE";
	static public const OXEL_BUILD_COMPLETE:String			= "OXEL_BUILD_COMPLETE";
	static public const OXEL_BUILD_FAILED:String			= "OXEL_BUILD_FAILED";

	private var _od:OxelPersistence;
	private var _modelGuid:String;
	private var _fromTables:Boolean;
	private var _generated:Boolean;
	private var _generationData:Object;

	public function get oxelData():OxelPersistence { return _od; }
	public function get modelGuid():String  { return _modelGuid; }
	public function get fromTables():Boolean  { return _fromTables; }
	public function get generated():Boolean  { return _generated; }
	public function get generationData():Object  { return _generationData; }

	public function OxelDataEvent($type:String, $series:int, $guid:String, $vmd:OxelPersistence, $fromTable:Boolean, $generated:Boolean, $generationData:Object ) {
		super( $type, $series );
		_od = $vmd;
		_modelGuid = $guid;
		_fromTables = $fromTable;
		_generated = $generated;
		_generationData = $generationData;
	}
	
	public override function clone():Event {
		return new OxelDataEvent(type, series, modelGuid, oxelData, fromTables, generated, generationData);
	}
   
	public override function toString():String {
		return formatToString( "OxelDataEvent", "series", "modelGuid", "oxelData", "fromTables", "generated", "generationData");
	}
	
	///////////////// Event handler interface /////////////////////////////

	// Used to distribute all persistence messages
	static private var _eventDispatcher:EventDispatcher = new EventDispatcher();

	static public function addListener( $type:String, $listener:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false) : void {
		_eventDispatcher.addEventListener( $type, $listener, $useCapture, $priority, $useWeakReference );
	}

	static public function removeListener( $type:String, $listener:Function, $useCapture:Boolean=false) : void {
		_eventDispatcher.removeEventListener( $type, $listener, $useCapture );
	}

	static public function create($type:String, $series:int, $guid:String, $vmd:OxelPersistence, $fromTable:Boolean = true, $generated:Boolean = false, $generationData:Object = null ) : Boolean {
		//trace( "OxelDataEvent.create type: " + $type );
		return _eventDispatcher.dispatchEvent( new OxelDataEvent( $type, $series, $guid, $vmd, $fromTable, $generated, $generationData ) );
	}
	///////////////// Event handler interface /////////////////////////////
}
}
