/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	import flash.utils.ByteArray;
	public class InventoryModel extends InventoryObject
    {
		private var _guid:String;
		
		override public function toByteArray( $ba:ByteArray ):void {
			super.toByteArray( $ba )
			$ba.writeUTF( _guid );
		}
		
		override public function fromByteArray( $ba:ByteArray ):void {
			super.fromByteArray( $ba );
			_guid =    $ba.readUTF();
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
