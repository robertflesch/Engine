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
	public class Recipe 
	{
		private var _name:String = "INVLAID";
		private var _desc:String = "NONE";
		private var _category:String = "NONE";
		private var _preview:String = "none.jpg";
		private var _materials:Vector.<Material> = new Vector.<Material>();
		private var _bonuses:Vector.<Bonus> = new Vector.<Bonus>();
		
		public function fromJSON( $json:Object ):void 
		{
			if ( $json.name )
				_name = $json.name;
			else
				Log.out("Recipe.fromJSON - Null NAME found in recipe: " + $json.toString(), Log.ERROR );
				
			if ( $json.desc )
				_desc = $json.desc;
				
			if ( $json.category )
				_category = $json.category;
				
			if ( $json.preview )
				_preview = $json.preview;
				
			if ( $json.materials )
			{
				//Log.out( "ModelInfo.init - animations found" );
				var materialObj:Object = $json.materials;
				// i.e. animData = { "name": "Glide", "type": "state OR action", "guid":"Glide.ajson" }
				for each ( var materialData:Object in materialObj )		   
				{
					if ( materialData.material ) {
						var mat:Material = new Material();
						mat.fromJSON( materialData.material );
						_materials.push( mat )
					}
					else 
						Log.out("Recipe.fromJSON - Null material found in recipe: " + _name, Log.ERROR );
				}
			}
			
			if ( $json.bonuses )
			{
				//Log.out( "ModelInfo.init - animations found" );
				var bonusObj:Object = $json.bonuses;
				// i.e. animData = { "name": "Glide", "type": "state OR action", "guid":"Glide.ajson" }
				for each ( var bonusData:Object in bonusObj )		   
				{
					if ( bonusData.bonus ) {
						var bonus:Bonus = new Bonus();
						bonus.fromJSON( bonusData.bonus );
						_bonuses.push( bonus )
					}
					else 
						Log.out("Recipe.fromJSON - Null bonus found in recipe: " + _name, Log.ERROR );
				}
			}
		}
		
		public function toString():String {
			return "name: " + _name + "  desc: " + _desc + "  category: " + _category;
		}
		
		public function get name():String 
		{
			return _name;
		}
		
		public function get desc():String 
		{
			return _desc;
		}
		
		public function get category():String 
		{
			return _category;
		}
		
		public function get materials():Vector.<Material> 
		{
			return _materials;
		}
		
		public function get bonuses():Vector.<Bonus> 
		{
			return _bonuses;
		}
		
		public function get preview():String 
		{
			return _preview;
		}
	}
}