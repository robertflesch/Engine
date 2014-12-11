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
		private var _className:String = "INVLAID";
		private var _desc:String = "NONE";
		private var _subcat:String = "NONE";
		private var _preview:String = "none.jpg";
		private var _templateId:String;
		protected var _materialsRequired:Vector.<Material>;
		protected var _bonusesAllowed:Vector.<Bonus>;
		
		public function fromJSON( $json:Object ):void 
		{
			_materialsRequired = new Vector.<Material>();
			_bonusesAllowed = new Vector.<Bonus>();
			
			if ( $json.name )
				_name = $json.name;
			else
				Log.out("Recipe.fromJSON - Null NAME found in recipe: " + $json.toString(), Log.ERROR );
				
			if ( $json.className )
				_className = $json.className;
			else
				Log.out("Recipe.fromJSON - Null CLASS NAME found in recipe: " + $json.toString(), Log.ERROR );
				
			if ( $json.desc )
				_desc = $json.desc;
				
			if ( $json.subcat )
				_subcat = $json.subcat;
				
			if ( $json.preview )
				_preview = $json.preview;
				
			if ( $json.templateId )
				_templateId = $json.templateId;
				
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
						_materialsRequired.push( mat )
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
						_bonusesAllowed.push( bonus )
					}
					else 
						Log.out("Recipe.fromJSON - Null bonus found in recipe: " + _name, Log.ERROR );
				}
			}
		}
		
		public function copy( $recipe:Recipe ):void {
			_materialsRequired	= $recipe._materialsRequired;
			_bonusesAllowed		= $recipe._bonusesAllowed;
			_name				= $recipe._name;
			_className			= $recipe._className;
			_desc				= $recipe._desc;
			_subcat				= $recipe._subcat;
			_preview			= $recipe._preview;
			_templateId			= $recipe._templateId;
		}
		
		public function cancel():void {
			_materialsRequired = null;
			_bonusesAllowed = null;
		}
		
		public function toString():String {
			return "name: " + _name + "  desc: " + _desc + "  subcat: " + _subcat;
		}
		
		public function get name():String 
		{
			return _name;
		}
		
		public function get desc():String 
		{
			return _desc;
		}
		
		public function get subcat():String 
		{
			return _subcat;
		}
		
		public function get materials():Vector.<Material> 
		{
			return _materialsRequired;
		}
		
		public function get bonuses():Vector.<Bonus> 
		{
			return _bonusesAllowed;
		}
		
		public function get preview():String 
		{
			return _preview;
		}
		
		public function get className():String 
		{
			return _className;
		}
	}
}