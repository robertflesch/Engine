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
/**
 * ...
 * @author Robert Flesch - RSF
 * The world model holds the active oxels
 */
public class ModelMetadata
{
	private static const COPY_COUNT_INFINITE:int = -1;
	private var _modelGuid:String			= "";
	private var _name:String			= "";
	private var _description:String		= "";
	private var _owner:String			= "";
	private var _creator:String			= "";
	private var _thumbnail:BitmapData;
	private var _dbo:DatabaseObject;
	private var _createdDate:Date;
	private var _modifiedDate:Date;

	// Permissions
	// http://wiki.secondlife.com/wiki/Permission
	// move is more of a region type permission
	private var _template:Boolean       = false;
	private var _templateGuid:String	= "";
	private var _copy:Boolean			= true;
	private var _copyCount:int 			= COPY_COUNT_INFINITE;
	private var _modify:Boolean 		= true;
	private var _transfer:Boolean 		= true;

	public function get name():String  					{ return _name; }
	public function set name(value:String):void  		{ _name = value; }
	
	public function get description():String  			{ return _description; }
	public function set description(value:String):void  { _description = value; }
	
	public function get owner():String  				{ return _owner; }
	public function set owner(value:String):void  		{ _owner = value; }
	
	public function get template():Boolean  			{ return _template; }
	public function set template(value:Boolean):void  	{ _template = value; }
	
	public function get templateGuid():String  			{ return _templateGuid; }
	public function set templateGuid(value:String):void { _templateGuid = value; }

	public function get copy():Boolean 					{ return _copy; }
	public function set copy(val:Boolean):void			{ _copy = val; }
	
	public function get modify():Boolean 				{ return _modify; }
	public function set modify(value:Boolean):void 		{ _modify = value; }
	
	public function get modelGuid():String 					{ return _modelGuid; }
	public function set modelGuid(value:String):void  		{ _modelGuid = value; }
	
	public function get thumbnail():BitmapData 			{ return _thumbnail; }
	public function set thumbnail(value:BitmapData):void{ _thumbnail = value; }
	
	public function get copyCount():int  				{ return _copyCount; }
	public function set copyCount(value:int):void  		{ _copyCount = value; }
	
	public function get transfer():Boolean  			{ return _transfer; }
	public function set transfer(value:Boolean):void  	{ _transfer = value; }
	
	public function get createdDate():Date 				{ return _createdDate; }
	public function set createdDate(value:Date):void 	{ _createdDate = value; }
	
	public function get modifiedDate():Date 			{ return _modifiedDate; }
	public function set modifiedDate(value:Date):void  	{ _modifiedDate = value; }
	
	public function get dbo():DatabaseObject 			{ return _dbo; }
	public function set dbo(value:DatabaseObject):void 	{ _dbo = value; }
	
	public function get creator():String 				{ return _creator; }
	public function set creator(value:String):void  	{ _creator = value; }
	
	public function toString():String {
		return "name: " + _name + "  description: " + _description + "  guid: " + _modelGuid + "  owner: " + _owner;
	}
	
	public function ModelMetadata( $guid:String ) {
		if ( null == $guid || "" == $guid )
			throw new Error( "ModelMetadata - Missing guid in constructor" );
		_modelGuid = $guid;
		if ( "EditCursor" != $guid )
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
		creator 		= $vmm.creator;
		thumbnail 		= $vmm.thumbnail;
		
		template		= $vmm.template;
		templateGuid	= $vmm.templateGuid;
		copy			= $vmm.copy;
		copyCount		= $vmm.copyCount;
		modify			= $vmm.modify;
		transfer		= $vmm.transfer;
		
	}
	
	public function createInstanceOfTemplate():ModelMetadata {
		
		var newVmm:ModelMetadata = new ModelMetadata( Globals.getUID() );	
		newVmm.name 			= new String( _name );
		newVmm.description 		= new String( _description );
		newVmm.owner 			= new String( _owner );
		newVmm.creator			= creator
		newVmm.thumbnail		= thumbnail;
		
		newVmm._dbo				= null;
		newVmm.createdDate		= new Date( _createdDate );
		newVmm.modifiedDate		= new Date();
		newVmm.template			= false
		newVmm.templateGuid		= new String ( _modelGuid );
		newVmm.copy				= copy;
		newVmm.copyCount		= copyCount;
		newVmm.modify			= modify;
		newVmm.transfer			= transfer;
		
		return newVmm;
	}
	

	//////////////////////////////////////////////////////////////////
	// TO Persistance
	//////////////////////////////////////////////////////////////////
	
	public function toObject():Object {
		
		return { name: _name
			   , description: _description
			   , owner: _owner
			   , creator: _creator
			   , template: _template
			   , templateGuid: _templateGuid
			   , copy: _copy
			   , copyCount: _copyCount
			   , modify: _modify
			   , transfer: _transfer
			   , createdDate: _createdDate
			   , modifiedDate: _modifiedDate
			   , thumbnail: thumbnail }
	}
	
	//public function toJSONString():String {
		//
		//return JSON.stringify( this );
	//}

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
			else {
				var obj:Object = toObject();
			}
			PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, 0, Globals.DB_TABLE_MODELS, modelGuid, _dbo, obj ) );
		}
		else
			Log.out( "ModelMetadata.save - Not saving metadata, either offline or NOT changed or locked - guid: " + modelGuid + "  name: " + name, Log.WARN );
	}
	
	private function addSaveEvents():void {
		PersistanceEvent.addListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
		PersistanceEvent.addListener( PersistanceEvent.SAVE_FAILED, 	saveFail );
	}
	
	private function removeSaveEvents():void {
		PersistanceEvent.removeListener( PersistanceEvent.CREATE_SUCCEED, 	createSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_SUCCEED, 	saveSucceed );
		PersistanceEvent.removeListener( PersistanceEvent.SAVE_FAILED, 		saveFail );
	}
	
	private function saveSucceed( $pe:PersistanceEvent ):void { 
		if ( Globals.DB_TABLE_MODELS != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "ModelMetadata.saveSucceed - created: " + modelGuid, Log.DEBUG ); 
	}	
	
	private function createSucceed( $pe:PersistanceEvent ):void { 
		if ( Globals.DB_TABLE_MODELS != $pe.table )
			return;
		if ( $pe.dbo )
			_dbo = $pe.dbo;
		removeSaveEvents();
		Log.out( "ModelMetadata.createSuccess - created: " + modelGuid, Log.DEBUG ); 
	}	
	
	private function saveFail( $pe:PersistanceEvent ):void { 
		if ( Globals.DB_TABLE_MODELS != $pe.table )
			return;
		removeSaveEvents();
		Log.out( "ModelMetadata.saveFail - ", Log.ERROR ); 
	}	

	
	public function toPersistance():void {
		
		_dbo.name 			= _name;
		_dbo.description	= _description;
		_dbo.owner			= _owner;
		_dbo.creator		= _creator;
		_dbo.template		= _template;
		_dbo.templateGuid	= _templateGuid;
		_dbo.copy			= _copy;
		_dbo.copyCount		= _copyCount;
		_dbo.modify			= _modify;
		_dbo.transfer		= _transfer;
		_dbo.createdDate	= _createdDate;
		_dbo.modifiedDate   = new Date();
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
		_template		= $dbo.template;
		_templateGuid	= $dbo.templateGuid;
		_copy			= $dbo.copy;
		_copyCount		= $dbo.copyCount;
		_modify			= $dbo.modify;
		_transfer		= $dbo.transfer;
		_modelGuid 			= $dbo.key;
		_createdDate	= $dbo.createdDate;
		_modifiedDate   = $dbo.modifiedDate;
		_dbo			= $dbo;
		
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

