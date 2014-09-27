/*==============================================================================
   Copyright 2011-2013 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models
{
	import com.voxelengine.server.PersistModel;
	import flash.utils.ByteArray;
	import playerio.DatabaseObject;
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * The world model holds the active oxels
	 */
	public class VoxelModelMetadata
	{
		private static const COPY_COUNT_INFINITE:int = -1;
		private var _guid:String			= "";
		private var _name:String			= "";
		private var _description:String		= "";
		private var _owner:String			= "";
		private var _data:ByteArray
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
				   , data: data } 			
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
			_data 			= $dbo.data;
			_createdDate	= $dbo.createdDate;
			_modifiedDate   = $dbo.modifiedDate;
			_dbo 			= $dbo;
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
			_dbo.guid 			= _guid;
			_dbo.createdDate	= _createdDate;
			_dbo.modifiedDate   = new Date();
			_dbo.data 			= _data;
		}
		
		public function save( $save:Function, $fail:Function, $created:Function ):void {
						 
			if ( _dbo )
			{
				Log.out("VoxelModelMetadata.save - saving object back to BigDB: " + name );
				toPersistance();
				_dbo.save( false
					     , false
						 , $save
						 , $fail );
			}
			else
			{
				var obj:Object = toObject();
				Log.out("VoxelModelMetadata.save - creating new object: " + name );
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

