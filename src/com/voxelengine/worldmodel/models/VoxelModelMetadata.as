/*==============================================================================
   Copyright 2011-2013 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models
{
	import com.voxelengine.server.Persistance;
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
		private var _guid:String;
		private var _name:String;
		private var _description:String;
		private var _owner:String;
		private var _data:ByteArray;
		private var _dbo:DatabaseObject;

		// Permissions
		// http://wiki.secondlife.com/wiki/Permission
		// move is more of a region type permission
		private var _copy:Boolean;
		private var _copyCount:int = COPY_COUNT_INFINITE;
		private var _modify:Boolean = true;
		private var _transfer:Boolean = true;

		public function toString():String {
			return "name: " + _name + "  description: " + _description + "  guid: " + _guid + "  owner: " + _owner;
		}
		
		public function toObject():Object {
			return { guid: _guid
				   , name: _name
			       , description: _description
				   , owner: _owner
				   , copy: _copy
				   , copyCount: _copyCount
				   , modify: _modify
				   , transfer: _transfer
				   , data: data } 			
		}
		
		public function fromPersistance( $dbo:DatabaseObject ):void {
			_name 			= $dbo.name;
			_description	= $dbo.description;
			_owner			= $dbo.owner;
			_copy			= $dbo.copy;
			_copyCount		= $dbo.copyCount;
			_modify			= $dbo.modify;
			_transfer		= $dbo.transfer;
			_guid 			= $dbo.key;
			_data 			= $dbo.data;
			_dbo 			= $dbo;
		}
		
		public function save( $save:Function, $fail:Function, $created:Function ):void {
						 
						 
			if ( _dbo )
			{
				Log.out("VoxelModelMetadata.save - saving object back to BigDB: " + name );
				_dbo.save( false
					     , false
						 , $save
						 , $fail );
			}
			else
			{
				var obj:Object = toObject();
				
				Log.out("VoxelModelMetadata.save - creating new object: " + name );
				Persistance.createObject( Persistance.DB_TABLE_OBJECTS
								        , guid
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
		
		public function get copy():Boolean 					{ return _copy; }
		public function set copy(val:Boolean):void			{ _copy = val; }
		
		public function get modify():Boolean 				{ return _modify; }
		public function set modify(value:Boolean):void 		{ _modify = value; }
		
		public function get guid():String 					{ return _guid; }
		public function set guid(value:String):void  		{ _guid = value; }
		
		public function get data():ByteArray 				{ return _data; }
		public function set data(value:ByteArray):void  	{ _data = value; }
		
		public function get databaseObject():DatabaseObject 		{ return _dbo; }
		public function set databaseObject(val:DatabaseObject):void { _dbo = val; }
		
		
	}
}

