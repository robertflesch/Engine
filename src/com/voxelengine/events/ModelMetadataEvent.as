/*==============================================================================
  Copyright 2011-2013 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.events
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	import playerio.DatabaseObject;
	
	/**
	 * ...
	 * @author Robert Flesch - RSF 
	 */
	public class ModelMetadataEvent extends Event
	{
		static public const INFO_LOADED_PERSISTANCE:String  = "INFO_LOADED_PERSISTANCE";
		static public const INFO_COLLECTED:String  = "INFO_COLLECTED";
		
		private var _name:String;
		private var _key:String;
		private var _description:String;
		private var _owner:String;
		private var _template:String;
		private var _ba:ByteArray; // Do I need to copy this? RSF - 9.4.14
		private var _dbo:DatabaseObject;
		
		public function get name():String { return _name; }
		public function get key():String { return _key; }
		public function get description():String { return _description; }
		public function get owner():String { return _owner; }
		public function get template():String { return _template; }
		public function get ba():ByteArray { return _ba; }
		public function get dbo():DatabaseObject { return _dbo; }

		public function ModelMetadataEvent( $type:String, $name:String, $description:String, $key:String = "", $owner:String = "", $template:String = "", $ba:ByteArray = null, $dbo:DatabaseObject = null, $bubbles:Boolean = true, $cancellable:Boolean = false )
		{
			super( $type, $bubbles, $cancellable );
			_name = $name;
			_key = $key;
			_description = $description;
			_owner = $owner;
			_template = _template;
			_ba = $ba;
			_dbo = $dbo;
		}
		
		public override function clone():Event
		{
			return new ModelMetadataEvent(type, _name, _description, _key, _owner, _template, _ba, _dbo, bubbles, cancelable);
		}
	   
		public override function toString():String
		{
			return formatToString("ModelMetadataEvent", "bubbles", "cancelable") + " _name: " + _name + " _description: " + _description + "  key: " + key + "  owner: " + _owner + "  template: " + _template;
		}
		
		
	}
}
