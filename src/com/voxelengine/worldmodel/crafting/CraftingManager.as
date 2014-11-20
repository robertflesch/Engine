/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.crafting {
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.net.URLRequest;
import mx.utils.StringUtil;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.list.ListItem;

import com.voxelengine.Globals;
import com.voxelengine.Log;
import com.voxelengine.events.CraftingEvent;
import com.voxelengine.worldmodel.crafting.Recipe;
import com.voxelengine.utils.CustomURLLoader;

	/**
	 * ...
	 * @author Bob
	 */
	
	 
public class CraftingManager 
{
	static private var _initialized:Boolean;
	static private var _recipes:Vector.<Recipe> = new Vector.<Recipe>;
	
	public function CraftingManager() {
		Globals.g_app.addEventListener( CraftingEvent.RECIPE_LOAD_PUBLIC, loadRecipes );
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
				Globals.g_app.dispatchEvent( new CraftingEvent( CraftingEvent.RECIPE_LOADED, recipe.name, recipe ) );	
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
		var jsonString:String = StringUtil.trim(fileData);
		
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
			Globals.g_app.dispatchEvent( new CraftingEvent( CraftingEvent.RECIPE_LOADED, _r.name, _r ) );	
		}
		else	
			Log.out("CraftingManager.onRecipeLoaded - ERROR recipe data not found in fileName: " + fileName + "  data: " + fileData, Log.ERROR );
			
	}       
}
}