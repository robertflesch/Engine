/*==============================================================================
  Copyright 2011-2015 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under United States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.inventory {
	import flash.utils.ByteArray;
	public class InventoryVoxel extends InventoryObject
    {
		private var _id:int;
		private var _count:int;
		
		override public function toByteArray( $ba:ByteArray ):void {
			super.toByteArray( $ba )
			$ba.writeInt( _count );
		}
		
		override public function fromByteArray( $ba:ByteArray ):void {
			super.fromByteArray( $ba );
			_count =    $ba.readInt();
		}
		
		public function get count():int 
		{
			return _count;
		}
		
		public function set count(value:int):void 
		{
			_count = value;
		}
		
		public function get id():int 
		{
			return _id;
		}
		
		public function set id(value:int):void 
		{
			_id = value;
		}
		
	}
}
