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
public class VoxelModelMetadata
{
	private var _topImage:Bitmap;
	[Embed(source='../../../../../../Resources/bin/assets/textures/NoImage128.png')]
	private var _topImageClass:Class;
	
	private static const COPY_COUNT_INFINITE:int = -1;
	private var _guid:String			= "";
	private var _name:String			= "";
	private var _description:String		= "";
	private var _owner:String			= "";
	private var _image:BitmapData;
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
	
	public function get guid():String 					{ return _guid; }
	public function set guid(value:String):void  		{ _guid = value; }
	
	public function get image():BitmapData 				{ return _image; }
	public function set image(value:BitmapData):void  	
	{ 
		_image = value; 
	}
	
	public function get copyCount():int  { return _copyCount; }
	public function set copyCount(value:int):void  { _copyCount = value; }
	
	public function get transfer():Boolean  { return _transfer; }
	public function set transfer(value:Boolean):void  { _transfer = value; }
	
	public function get createdDate():Date { return _createdDate; }
	public function set createdDate(value:Date):void { _createdDate = value; }
	
	public function get modifiedDate():Date { return _modifiedDate; }
	public function set modifiedDate(value:Date):void  { _modifiedDate = value; }
	
	public function toString():String {
		return "name: " + _name + "  description: " + _description + "  guid: " + _guid + "  owner: " + _owner;
	}
	
	public function VoxelModelMetadata() {
		ModelMetadataEvent.addListener( ModelBaseEvent.SAVE, save );
	}

	public function release():void {
		ModelMetadataEvent.removeListener( ModelBaseEvent.SAVE, save );
		
	}
	
	public function initialize( $name:String, $description:String = null ):void {
		guid 			= Globals.getUID();
		name 			= $name
		description 	= $description ? $description: $name;
		owner 			= Network.userId;
		image 			= null;
		
		_dbo			= null;
		createdDate		= new Date();
		modifiedDate	= new Date();
		template		= false
		templateGuid	= null
		copy			= true;
		copyCount		= -1;
		modify			= true;
		transfer		= true;
	}
	
	public function createInstanceOfTemplate():VoxelModelMetadata {
		
		var newVmm:VoxelModelMetadata = new VoxelModelMetadata();	
		newVmm.guid 			= Globals.getUID();
		newVmm.name 			= new String( _name );
		newVmm.description 		= new String( _description );
		newVmm.owner 			= new String( _owner );
		newVmm.image 			= null;
		
		newVmm._dbo				= null;
		newVmm.createdDate		= new Date( _createdDate );
		newVmm.modifiedDate		= new Date();
		newVmm.template			= false
		newVmm.templateGuid		= new String ( _guid );
		newVmm.copy				= copy;
		newVmm.copyCount		= copyCount;
		newVmm.modify			= modify;
		newVmm.transfer			= transfer;
		
		return newVmm;
	}
	
	public function toObject():Object {
		
		return { name: _name
			   , description: _description
			   , owner: _owner
			   , template: _template
			   , templateGuid: _templateGuid
			   , copy: _copy
			   , copyCount: _copyCount
			   , modify: _modify
			   , transfer: _transfer
			   , createdDate: _createdDate
			   , modifiedDate: _modifiedDate
			   , image: image }
	}
	
	public function toJSONString():String {
		
		return JSON.stringify( this );
	}

	static public const DB_TABLE_MODELS:String = "voxelModels";
	static public const DB_TABLE_MODELS_DATA:String = "voxelModelsData";
	static public const DB_INDEX_MODEL_OWNER:String = "voxelModelOwner";
	static public const DB_INDEX_OWNER_TEMPLATE:String = "ownerTemplate"
	

	//////////////////////////////////////////////////////////////////
	// TO Persistance
	//////////////////////////////////////////////////////////////////
	
	private function save( $vmd:ModelMetadataEvent ):void {
		Log.out( "VoxelModelMetadata.save - Saving Model Metadata: " + guid, Log.WARN );
		if ( _dbo )
			toPersistanceMetadata();
		else {
			var obj:Object = toObject();
		}
		PersistanceEvent.dispatch( new PersistanceEvent( PersistanceEvent.SAVE_REQUEST, DB_TABLE_MODELS, guid, _dbo ) );
	}
	
	public function toPersistanceMetadata():void {
		
		_dbo.name 			= _name;
		_dbo.description	= _description;
		_dbo.owner			= _owner;
		_dbo.template		= _template
		_dbo.templateGuid	= _templateGuid
		_dbo.copy			= _copy;
		_dbo.copyCount		= _copyCount;
		_dbo.modify			= _modify;
		_dbo.transfer		= _transfer;
		_dbo.createdDate	= _createdDate;
		_dbo.modifiedDate   = new Date();
		if ( image )
			_dbo.imageData 		= image.encode(new Rectangle(0, 0, 128, 128), new JPEGEncoderOptions() ); 
		else
			_dbo.imageData = null;
	}
	
	////////////////////////////////////////////////////////////////
	// FROM Persistance
	////////////////////////////////////////////////////////////////
	
	public function fromPersistanceMetadata( $dbo:DatabaseObject ):void {
		
		_name 			= $dbo.name;
		_description	= $dbo.description;
		_owner			= $dbo.owner;
		_template		= $dbo.template
		_templateGuid	= $dbo.templateGuid
		_copy			= $dbo.copy;
		_copyCount		= $dbo.copyCount;
		_modify			= $dbo.modify;
		_transfer		= $dbo.transfer;
		_guid 			= $dbo.key;
		_createdDate	= $dbo.createdDate;
		_modifiedDate   = $dbo.modifiedDate;
		_dbo			= $dbo;
		
		if ( $dbo.imageData ) {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.INIT, function(event:Event):void { image = Bitmap( LoaderInfo(event.target).content).bitmapData; } );
			loader.loadBytes( $dbo.imageData );			
		}
		else
			_image 		= null;

	}
	
	//
	
}
}

