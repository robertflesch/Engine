package com.voxelengine.worldmodel
{
	
	/**
	 * ...
	 * @author ...
	 */
	public class ObjectInfo 
	{
		protected var _image:String				= "grey64.png";
		protected var _name:String 				= "INVALID";
		protected var _guid:String 				= "INVALID";
		
		public function get image():String 
		{
			return _image;
		}
		
		public function set image(value:String):void 
		{
			_image = value;
		}
		
		public function get name():String 
		{
			return _name;
		}
		
		public function set name(value:String):void 
		{
			_name = value;
		}
		
		public function get guid():String 
		{
			return _guid;
		}
		
		public function set guid(value:String):void 
		{
			_guid = value;
		}
	}
	
}