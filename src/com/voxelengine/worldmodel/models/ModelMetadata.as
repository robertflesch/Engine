/*==============================================================================
Copyright 2011-2015 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.models
{
import com.voxelengine.events.ModelBaseEvent;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.JPEGEncoderOptions;
import flash.display.Loader;
import flash.display.LoaderInfo
import flash.events.Event;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

import playerio.DatabaseObject;
import playerio.PlayerIOError;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.events.PersistanceEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.Permissions;

/**
 * ...
 * @author Robert Flesch - RSF
 * The world model holds the active oxels
 */
public class ModelMetadata
{
	private static const COPY_COUNT_INFINITE:int = -1;
	private var _modelGuid:String		= "";
	private var _parentModelGuid:String;
	private var _name:String			= "";
	private var _description:String		= "";
	private var _owner:String			= "";
	private var _creator:String			= "";
	private var _thumbnail:BitmapData;
	private var _dbo:DatabaseObject;
	private var _modifiedDate:Date;
	private var _permissions:Permissions = new Permissions();

	public function get permissions():Permissions 		{ return _permissions; }
	public function set permissions( val:Permissions):void	{ _permissions = val; }
	
	public function get name():String  					{ return _name; }
	public function set name(value:String):void  		{ _name = value; }
	
	public function get description():String  			{ return _description; }
	public function set description(value:String):void  { _description = value; }
	
	public function get owner():String  				{ return _owner; }
	public function set owner(value:String):void  		{ _owner = value; }
	
	public function get modelGuid():String 				{ return _modelGuid; }
	public function set modelGuid(value:String):void  	{ _modelGuid = value; }
	
	public function get parentModelGuid():String 				{ return _parentModelGuid; }
	public function set parentModelGuid(value:String):void  	{ _parentModelGuid = value; }
	
	public function get thumbnail():BitmapData 			{ return _thumbnail; }
	public function set thumbnail(value:BitmapData):void { _thumbnail = value; }
	
	public function get modifiedDate():Date 			{ return _modifiedDate; }
	public function set modifiedDate(value:Date):void  	{ _modifiedDate = value; }
	
	public function get dbo():DatabaseObject 			{ return _dbo; }
	public function set dbo(value:DatabaseObject):void 	{ _dbo = value; }
	
	public function toString():String {
		return "name: " + _name + "  description: " + _description + "  guid: " + _modelGuid + "  owner: " + _owner;
	}
	
	public function ModelMetadata( $modelGuid:String ) {
		if ( null == $modelGuid || "" == $modelGuid )
			throw new Error( "ModelMetadata - Missing guid in constructor" );
		_modelGuid = $modelGuid;
		if ( "EditCursor" != $modelGuid )
			ModelMetadataEvent.addListener( ModelBaseEvent.SAVE, saveEvent );
	}

	public function release():void {
		ModelMetadataEvent.removeListener( ModelBaseEvent.SAVE, saveEvent );
		//ModelMetadataEvent.removeListener( ModelBaseEvent.LOAD, 		load );
		
	}
	
	public function update( $vmm:ModelMetadata ):void {
		name 			= $vmm.name;
		description 	= $vmm.description;
		owner 			= $vmm.owner;
		thumbnail 		= $vmm.thumbnail;
		parentModelGuid = $vmm.parentModelGuid;
Log.out( "ModelMetadata.update - How do I handle permissions here?", Log.WARN );
		//creator 		= $vmm.creator;
		//template		= $vmm.template;
		//templateGuid	= $vmm.templateGuid;
		//copy			= $vmm.copy;
		//copyCount		= $vmm.copyCount;
		//modify		= $vmm.modify;
		//transfer		= $vmm.transfer;
	}
	
	public function clone():ModelMetadata {
		
		var newVmm:ModelMetadata = new ModelMetadata( modelGuid );	
		newVmm.name 			= new String( _name );
		newVmm.description 		= new String( _description );
		newVmm.owner 			= new String( _owner );
		newVmm.thumbnail		= thumbnail;
		newVmm.parentModelGuid  = parentModelGuid;
		newVmm._dbo				= dbo;
		newVmm.permissions		= _permissions.clone();
		newVmm.modifiedDate		= modifiedDate;
		
		return newVmm;
	}
	

	//////////////////////////////////////////////////////////////////
	// TO Persistance
	//////////////////////////////////////////////////////////////////
	
	public function toObject():Object {
		
		var metadataObj:Object =  { name: _name
								  , description: _description
								  , owner: _owner
								  , creator: _creator
								  , modifiedDate: _modifiedDate
								  , parentModelGuid: parentModelGuid
								  , thumbnail: thumbnail }
								  
		metadataObj = _permissions.addToObject( metadataObj );
		return metadataObj;						   
	}
	

	// This was private, force a message to be sent to it. 
	// But the voxelModel has a handle to it, seems silly to have to propgate it every where, so its public
	private function saveEvent( $vmd:ModelMetadataEvent ):void {
		if ( modelGuid != $vmd.modelGuid ) {
			Log.out( "ModelMetadata.saveEvent - Ignoring save meant for other model my guid: " + modelGuid + " target guid: " + $vmd.modelGuid, Log.WARN );
			return;
		}
		save();
	}
	
	public function save():void {
		if ( Globals.online ) {
			Log.out( "ModelMetadata.save - Saving Model Metadata: " + modelGuid ); // + " vmd: " + $vmd.toString(), Log.WARN );
			addSaveEvents();
			if ( _dbo )
				toPersistance();
			else
				var obj:Object = toObject();

			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, Globals.BIGDB_TABLE_MODEL_METADATA, modelGuid, _dbo, obj ) );
		}
		else
			Log.out( "ModelMetadata.save - Not saving metadata, either offline or NOT changed or locked - guid: " + modelGuid + "  name: " + name, Log.WARN );
	}
	
	private function addSaveEvents():void {
		PersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
		PersistanceEvent.addListener( PersistanceEvent.CREATE_FAILED, 	createFailed );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_FAILED, 	saveFail );
	}
	
	private function removeSaveEvents():void {
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_FAILED, 	createFailed );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_FAILED, 		saveFail );
	}
	
	private function saveSucceed( $pe:PersistanceEvent ):void { 
		if ( Globals.BIGDB_TABLE_MODEL_METADATA != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "ModelMetadata.saveSucceed - modelGuid: " + modelGuid + "  name: " + name, Log.DEBUG ); 
	}	
	
	private function saveFail( $pe:PersistanceEvent ):void { 
		if ( Globals.BIGDB_TABLE_MODEL_METADATA != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "ModelMetadata.saveFail - modelGuid: " + modelGuid, Log.ERROR ); 
	}	

	private function createSucceed( $pe:PersistanceEvent ):void { 
		if ( Globals.BIGDB_TABLE_MODEL_METADATA != $pe.table )
			return;
		if ( $pe.dbo )
			_dbo = $pe.dbo;
		removeSaveEvents();
		Log.out( "ModelMetadata.createSuccess - modelGuid: " + modelGuid, Log.DEBUG ); 
	}	
	
	private function createFailed( $pe:PersistanceEvent ):void  {
		if ( Globals.BIGDB_TABLE_MODEL_AND_OXEL_DATA != $pe.table )
			return;
		removeSaveEvents();
		// TODO How do I handle the metadata for failed object?
		Log.out( "ModelData.createFailed  - modelGuid: " + modelGuid, Log.ERROR ); 
		
	}
	
	public function toPersistance():void {
		
		_dbo.name 			= _name;
		_dbo.description	= _description;
		_dbo.owner			= _owner;
		_dbo.creator		= _creator;
		_dbo.modifiedDate   = new Date();
		_dbo.parentModelGuid= parentModelGuid;
		_permissions.toPersistance( _dbo );
		if ( thumbnail )
			_dbo.thumbnail 		= thumbnail.encode(new Rectangle(0, 0, 128, 128), new JPEGEncoderOptions() ); 
		else
			_dbo.thumbnail = null;
	}
	
	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	
	public function fromPersistance( $dbo:DatabaseObject ):void {
		
		_name 			= $dbo.name;
		_description	= $dbo.description;
		_owner			= $dbo.owner;
		_creator		= $dbo.creator;
		_modelGuid 		= $dbo.key;
		_modifiedDate   = $dbo.modifiedDate;
		_parentModelGuid = $dbo.parentModelGuid;
		_dbo			= $dbo;
		_permissions.fromPersistance( $dbo );
		
		if ( $dbo.thumbnail ) {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.INIT, function(event:Event):void { thumbnail = Bitmap( LoaderInfo(event.target).content).bitmapData; } );
			loader.loadBytes( $dbo.thumbnail );			
		}
		else
			thumbnail 		= null;
	}
}
}

