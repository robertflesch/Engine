/*==============================================================================
   Copyright 2011-2015 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models
{
	import com.voxelengine.server.Network;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.JPEGEncoderOptions;
	import flash.display.Loader;
	import flash.display.LoaderInfo
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import playerio.DatabaseObject;
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.server.PersistModel;
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
		private var _data:ByteArray
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

		public function toString():String {
			return "name: " + _name + "  description: " + _description + "  guid: " + _guid + "  owner: " + _owner;
		}
		
		public function VoxelModelMetadata() {
			//var rect:Rectangle = new Rectangle(0,0,128,128);
			//var bmp:Bitmap = (new _topImageClass() as Bitmap);
			//_image = bmp.bitmapData; // .getPixels(rect);
		}
		/*
		public function clone():VoxelModelMetadata {
			
			var newVmm:VoxelModelMetadata = new VoxelModelMetadata();	
			newVmm.guid 			= new String( _guid );
			newVmm.name 			= new String( _name );
			newVmm.description 		= new String( _description );
			newVmm.owner 			= new String( _owner );
			
			// is this stored compressed? probably should be.
			var buffer:ByteArray = new ByteArray();
			buffer.writeObject( _data );
			buffer.position = 0;
			
			newVmm.data				= buffer.readObject() as ByteArray;
			
			// how to copy this?
			newVmm._dbo				= null;
			newVmm.createdDate		= new Date();
			newVmm.modifiedDate		= new Date();
			newVmm.template			= false
			newVmm.templateGuid		= new String ( newVmm.copyCount );
			newVmm.copy				= copy;
			newVmm.copyCount		= copyCount;
			newVmm.modify			= modify;
			newVmm.transfer			= transfer;
			
			return newVmm;
		}
		*/
		public function initialize( $name:String, $description:String = null ):void {
			guid 			= Globals.getUID();
			name 			= $name
			description 	= $description ? $description: $name;
			owner 			= Network.userId;
			image 			= null;
			data			= null;
			
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
			newVmm.data				= null;
			
			// how to copy this?
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
				   , data: data
				   , image: image }
		}
		
		public function toJSONString():String {
			
			return JSON.stringify( this );
		}

		public function fromPersistance( $dbo:DatabaseObject ):void {
			
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
			_dbo 			= $dbo;
			
			if ( $dbo.data ) {
				var ba:ByteArray= $dbo.data 
				ba.uncompress();
				_data 		= ba;
			}
			else
				_data 		= null;
				
			if ( $dbo.imageData ) {
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.INIT, function(event:Event):void { image = Bitmap( LoaderInfo(event.target).content).bitmapData; } );
				loader.loadBytes( $dbo.imageData );			
			}
			else
				_image 		= null;
	
		}
		
		public function toPersistance():void {
			
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
			_dbo.data 			= _data;
			if ( image )
				_dbo.imageData 		= image.encode(new Rectangle(0, 0, 128, 128), new JPEGEncoderOptions() ); 
			else
				_dbo.imageData = null;
		}
		
		public function save( $save:Function, $fail:Function, $created:Function ):void {
						 
			if ( _dbo )
			{
				Log.out("VoxelModelMetadata.save - saving changes to: " + name + "  guid: " + guid  );

				toPersistance();
				_dbo.save( false
					     , false
						 , $save
						 , $fail );
			}
			else
			{
				var obj:Object = toObject();
				Log.out("VoxelModelMetadata.save - creating new object: " + name + "  guid: " + guid  );
				PersistModel.createModel( guid
								        , obj
								        , $created
								        , $fail );
			}
		}
		
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
		
		public function get data():ByteArray 				{ return _data; }
		public function set data(value:ByteArray):void  	
		{ 
			_data = value; 
			if ( _dbo )
				_dbo.data = _data;
		}
		
		//public function get image():ByteArray 				{ return _image; }
		//public function set image(value:ByteArray):void  	
		//{ 
			//_image = value; 
			//if ( _dbo )
				//_dbo.image = _image;
		//}
		
		public function get image():BitmapData 				{ return _image; }
		public function set image(value:BitmapData):void  	
		{ 
			_image = value; 
		}
		
		public function get databaseObject():DatabaseObject 		{ return _dbo; }
		public function set databaseObject(val:DatabaseObject):void { _dbo = val; }
		
		public function get copyCount():int 
		{
			return _copyCount;
		}
		
		public function set copyCount(value:int):void 
		{
			_copyCount = value;
		}
		
		public function get transfer():Boolean 
		{
			return _transfer;
		}
		
		public function set transfer(value:Boolean):void 
		{
			_transfer = value;
		}
		
		public function get createdDate():Date 
		{
			return _createdDate;
		}
		
		public function set createdDate(value:Date):void 
		{
			_createdDate = value;
		}
		
		public function get modifiedDate():Date 
		{
			return _modifiedDate;
		}
		
		public function set modifiedDate(value:Date):void 
		{
			_modifiedDate = value;
		}
		
		
	}
}

