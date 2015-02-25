/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.crafting {
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.net.URLRequest;
import flash.utils.getDefinitionByName;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.CraftingEvent;
import com.voxelengine.worldmodel.crafting.Recipe;
import com.voxelengine.utils.CustomURLLoader;
import com.voxelengine.utils.StringUtils;
import com.voxelengine.worldmodel.crafting.items.*;

	/**
	 * ...
	 * @author Bob
	 */
	
	 
public class CraftingManager extends EventDispatcher
{
	// Adding these makes the event available in MXML
	// http://help.adobe.com/en_US/flex/using/WS2db454920e96a9e51e63e3d11c0bf69084-7ab2.html
	// [Event(name = "complete", type = "com.voxelengine.events.CraftingEvent")]
	
	static private var _initialized:Boolean;
	static private var _recipes:Vector.<Recipe> = new Vector.<Recipe>;
	
	public function CraftingManager() {
		addEventListener( CraftingEvent.RECIPE_LOAD_PUBLIC, loadRecipes );
	}
	
	static private function loadRecipes(e:CraftingEvent):void 
	{
		if ( !_initialized ) {
			loadRecipeLocal( "basic_pick.cjson" );		
			loadRecipeLocal( "pick.cjson" );		
			loadRecipeLocal( "shovel.cjson" );		
		}
		else {
			for each ( var recipe:Recipe in _recipes ) {
				Globals.craftingManager.dispatchEvent( new CraftingEvent( CraftingEvent.RECIPE_LOADED, recipe.name, recipe ) );	
			}
		}
		
		_initialized = true;
	}
	
	static private function loadRecipeLocal( $Recipe:String ):void {
		var loader:CustomURLLoader = new CustomURLLoader( new URLRequest( Globals.appPath + "assets/crafting/" + $Recipe ) );
		loader.addEventListener(Event.COMPLETE, onRecipeLoaded);
		loader.addEventListener(IOErrorEvent.IO_ERROR, onRecipeError);
	}
	
	static private function onRecipeError(event:IOErrorEvent):void {
		Log.out("CraftingManager.onRecipeError: ERROR: " + event.formatToString, Log.ERROR );
	}	
				
	static private function onRecipeLoaded(event:Event):void {
		var fileName:String = CustomURLLoader(event.target).fileName;			
		var fileData:String = String(event.target.data);
		var jsonString:String = StringUtils.trim(fileData);
		
		try {
			var jsonResult:Object = JSON.parse(jsonString);
		}
		catch ( error:Error ) {
			Log.out("----------------------------------------------------------------------------------" );
			Log.out("CraftingManager.onRecipeLoaded - ERROR PARSING: fileName: " + fileName + "  data: " + fileData, Log.ERROR );
			Log.out("----------------------------------------------------------------------------------" );
			return;
		}

		var _r:Recipe = new Recipe();
		if ( jsonResult.recipe ) {
			_r.fromJSON( jsonResult.recipe );
			_recipes.push( _r );
			Globals.craftingManager.dispatchEvent( new CraftingEvent( CraftingEvent.RECIPE_LOADED, _r.name, _r ) );	
		}
		else	
			Log.out("CraftingManager.onRecipeLoaded - ERROR recipe data not found in fileName: " + fileName + "  data: " + fileData, Log.ERROR );
			
	}       
	
	public static function getClass( $className : String ) : Class
	{
		Pick;
		try 
		{
			var asset:Class = Class ( getDefinitionByName ( "com.voxelengine.worldmodel.crafting.items." + $className ) );
		}
		catch ( error:Error )
		{
			Log.out( "CraftingManager.getClass - ERROR - getDefinitionByName failed to find: com.voxelengine.worldmodel.crafting.items." + $className + " ERROR: " + error, Log.ERROR );
		}
		
		return asset;
	}

}
}