/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import mx.utils.StringUtil;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.PersistanceEvent;

/**
 * ...
 * @author Bob
 */
public class ModelInfoManager
{
	// this acts as a holding spot for all model objects loaded from persistance
	// dont use weak keys since this is THE spot that holds things.
	static private var _modelInfo:Dictionary = new Dictionary(false);
	
	public function ModelInfoManager() {
		
	}
	
	static public function init():void {
		ModelInfoEvent.addListener( ModelInfoEvent.REQUEST, modelInfoRequest );
		
		PersistanceEvent.addListener( PersistanceEvent.LOAD_SUCCEED, modelInfoLoadSucceed );
		PersistanceEvent.addListener( PersistanceEvent.LOAD_FAILED, modelInfoLoadFailed );
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	//  modelInfo
	/////////////////////////////////////////////////////////////////////////////////////////////
	static private function modelInfoRequest( $mie:ModelInfoEvent ):void 
	{   
		if ( null == $mie.guid ) {
			Log.out( "ModelInfoManager.modelInfoRequest guid rquested is NULL: ", Log.WARN );
			return;
		}
		Log.out( "ModelInfoManager.modelInfoRequest guid: " + $mie.guid, Log.WARN );
		var mi:ModelInfo = _modelInfo[$mie.guid]; 
		if ( null == mi )
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.LOAD_REQUEST, Globals.MODEL_INFO_EXT, $mie.guid ) );
		else
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelInfoEvent.ADDED, $mie.guid, mi ) );
	}
	
	static private function modelInfoAdd( $guid:String, $mi:ModelInfo ):void 
	{ 
		if ( null == $mi || null == $guid ) {
			Log.out( "ModelInfoManager.modelInfoAdd trying to add NULL modelInfo or guid", Log.WARN );
			return;
		}
		// check to make sure is not already there
		if ( null ==  _modelInfo[$guid] ) {
			//Log.out( "ModelInfoManager.modelInfoAdd vmm: " + $vmm.toString(), Log.WARN );
			_modelInfo[$guid] = $mi; 
			
			var result:Boolean = ModelInfoEvent.hasEventListener( ModelInfoEvent.ADDED );
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelInfoEvent.ADDED, $guid, $mi ) );
		}
	}
	
	static private function modelInfoLoadSucceed( $pe:PersistanceEvent):void 
	{
		if ( Globals.MODEL_INFO_EXT != $pe.table )
			return;
		Log.out( "ModelInfoManager.modelInfoLoadSucceed $pe: " + $pe.guid, Log.WARN );
		if ( $pe.data ) {
				var fileData:String = String( $pe.data );
				var jsonString:String = StringUtil.trim(fileData);
				
				try {
					var jsonResult:Object = JSON.parse(jsonString);
				}
				catch ( error:Error ) {
					Log.out("----------------------------------------------------------------------------------" );
					Log.out("ModelInfoManager.modelInfoLoadSucceed - ERROR PARSING: fileName: " + $pe.guid + "  data: " + fileData, Log.ERROR, error );
					Log.out("----------------------------------------------------------------------------------" );
					return;
				}
				var mi:ModelInfo = new ModelInfo();
				
				mi.initJSON( $pe.guid, jsonResult );
				//Globals.g_app.dispatchEvent( new ModelEvent( ModelEvent.INFO_LOADED, guid ) );
				modelInfoAdd( $pe.guid, mi );
		}
		else {
			ModelInfoEvent.dispatch( new ModelInfoEvent( ModelInfoEvent.FAILED, null, null ) );
		}
	}
	
	static private function modelInfoLoadFailed( $pe:PersistanceEvent ):void 
	{
		if ( Globals.MODEL_INFO_EXT != $pe.table )
			return;
		Log.out( "ModelInfoManager.modelInfoLoadFailed vmm: ", Log.ERROR );
	}
	}
}