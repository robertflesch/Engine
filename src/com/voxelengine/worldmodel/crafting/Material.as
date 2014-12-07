/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.crafting {
	import com.voxelengine.Log;
	import com.voxelengine.Globals;

	/**
	 * ...
	 * @author Bob
	 */
	public class Material 
	{
		private var _category:String;
		private var _quantity:int;
		private var _optional:Boolean;

		private var _damage:int;
		private var _speed:int;
		private var _durability:int;
		private var _weight:int;
		
		public function fromJSON( $json:Object ):void 
		{
			if ( $json.category )
				_category = $json.category.toUpperCase();
			else
				Log.out( "Material.fromJSON - category not found in material:" + $json.toString(), Log.ERROR );
				
			if ( $json.quantity )
				_quantity = $json.quantity;
				
			if ( $json.speed )
				_speed = $json.speed;
			else
				Log.out( "Material.fromJSON - speed not found in material:" + $json.toString(), Log.ERROR );
			
			if ( $json.damage )
				_damage = $json.damage;
			if ( $json.durability )
				_durability = $json.durability;
			if ( $json.weight )
				_weight = $json.weight;
				
			if ( $json.optional )
				_optional = $json.optional;
			}		
		
		public function get category():String 
		{
			return _category;
		}
		
		public function get quantity():int 
		{
			return _quantity;
		}
		
		public function get optional():Boolean 
		{
			return _optional;
		}
		
		public function get damage():int 
		{
			return _damage;
		}
		
		public function get speed():int 
		{
			return _speed;
		}
		
		public function get durability():int 
		{
			return _durability;
		}
		
		public function get weight():int 
		{
			return _weight;
		}
	}
}