/*==============================================================================
   Copyright 2011-2013 Robert Flesch
   All rights reserved.  This product contains computer programs, screen
   displays and printed documentation which are original works of
   authorship protected under United States Copyright Act.
   Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.worldmodel.models
{
	/**
	 * ...
	 * @author Robert Flesch - RSF
	 * The world model holds the active oxels
	 */
	public class VoxelModelMetadata
	{
//		public function get editable():Boolean 					{ return _editable; }
//		public function set editable(val:Boolean):void			{ _editable = val; }
//		public function get template():Boolean 					{ return _template; }
//		public function set template(val:Boolean):void	 		{ _template = val; }
		
		private var _name:String;
		private var _description:String;
		private var _owner:String;
		private var _template:Boolean;
		private var _editable:Boolean = true;
		
		public function get toObject():Object {
			return { name: _name
			       , description: _description
				   , owner: _owner
				   , template: _template
				   , editable: _editable
				   , data: null } 			
		}
		
		public function get name():String 
		{
			return _name;
		}
		
		public function set name(value:String):void 
		{
			_name = value;
		}
		
		public function get description():String 
		{
			return _description;
		}
		
		public function set description(value:String):void 
		{
			_description = value;
		}
		
		public function get owner():String 
		{
			return _owner;
		}
		
		public function set owner(value:String):void 
		{
			_owner = value;
		}
		
		public function get template():Boolean 
		{
			return _template;
		}
		
		public function set template(value:Boolean):void 
		{
			_template = value;
		}
		
		public function get editable():Boolean 
		{
			return _editable;
		}
		
		public function set editable(value:Boolean):void 
		{
			_editable = value;
		}
	}
}

