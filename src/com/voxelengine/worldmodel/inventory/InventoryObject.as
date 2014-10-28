/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	import flash.utils.ByteArray;
	public class InventoryObject
    {
		static public const ITEM_INVALID:int = 0;
		static public const ITEM_OXEL:int = 1;
		static public const ITEM_MODEL:int = 2;
		
		// FIXME: These should be attributes too, so user cant hack in new items.
		public var _version:int = 0;
		private var _type:int
		private var _item:String;
		
		public function toByteArray( $ba:ByteArray ):void {
			$ba.writeByte( _version );
			$ba.writeInt( _type );
			$ba.writeUTF( _item );
		}
		
		public function fromByteArray( $ba:ByteArray ):void {
			_version = $ba.readByte();
			if ( 0 == _version ) {
				_type =    $ba.readInt();
				_item =    $ba.readUTF();
			}
		}
		
		public function get item():String 
		{
			return _item;
		}
		
		public function set item(value:String):void 
		{
			_item = value;
		}
		
		public function get type():int 
		{
			return _type;
		}
		
		public function set type(value:int):void 
		{
			_type = value;
		}
		
	}
}
