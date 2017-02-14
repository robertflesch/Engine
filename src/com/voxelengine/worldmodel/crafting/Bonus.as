/*==============================================================================
  Copyright 2011-2017 Robert Flesch
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
	public class Bonus 
	{
		private var _category:String = "Crafting";
		private var _subCat:String;
		
		private var _optional:Boolean;

		public function fromJSON( $json:Object ):void 
		{
			if ( $json.subCat )
				_subCat = $json.subCat.toLowerCase();
				
			if ( $json.optional )
				_optional = $json.optional;
		}		
		
		public function get category():String 
		{
			return _category;
		}
		
		public function get optional():Boolean 
		{
			return _optional;
		}
		
		public function get subCat():String 
		{
			return _subCat;
		}
		
	}
}