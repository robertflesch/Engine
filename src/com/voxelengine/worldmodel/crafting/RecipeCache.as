/*==============================================================================
  Copyright 2011-2017 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.crafting {
import com.voxelengine.events.CraftingEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.PersistenceEvent;
import com.voxelengine.utils.JSONUtil;
import com.voxelengine.worldmodel.models.makers.ModelMakerBase;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.net.URLRequest;
import flash.utils.Dictionary;
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
	
	 
public class RecipeCache
{
	// Adding these makes the event available in MXML
	// http://help.adobe.com/en_US/flex/using/WS2db454920e96a9e51e63e3d11c0bf69084-7ab2.html
	// [Event(name = "complete", type = "com.voxelengine.events.CraftingEvent")]
	
	static private var _initialized:Boolean;
	static private var _recipes:Dictionary = new Dictionary(false);

	public function RecipeCache() {;}

	static public function init():void {
        PersistenceEvent.addListener( PersistenceEvent.LOAD_SUCCEED, 	loadSucceed );
        PersistenceEvent.addListener( PersistenceEvent.LOAD_FAILED, 	loadFailed );
        PersistenceEvent.addListener( PersistenceEvent.LOAD_NOT_FOUND, 	loadNotFound );
		CraftingEvent.addListener( ModelBaseEvent.REQUEST_TYPE, 		loadRecipes );
	}
	
	static private function loadRecipes(e:CraftingEvent):void 
	{
		if ( !_initialized ) {
            PersistenceEvent.create(PersistenceEvent.LOAD_REQUEST, 0, Recipe.RECIPE_EXT, "basicPick");
            PersistenceEvent.create(PersistenceEvent.LOAD_REQUEST, 0, Recipe.RECIPE_EXT, "pick");
            PersistenceEvent.create(PersistenceEvent.LOAD_REQUEST, 0, Recipe.RECIPE_EXT, "shovel");
		}
		else {
			for each ( var recipe:Recipe in _recipes ) {
				CraftingEvent.create( ModelBaseEvent.RESULT, recipe.name, recipe );
			}
		}
		_initialized = true;
	}

	static private function loadSucceed( $pe:PersistenceEvent):void {
		if ( Recipe.BIGDB_TABLE_RECIPE != $pe.table && Recipe.RECIPE_EXT != $pe.table )
			return;

        var rec:Recipe = _recipes[$pe.guid];
        if ( null != rec ) {
            // we already have it, publishing this results in duplicate items being sent to inventory window.
            CraftingEvent.create( ModelBaseEvent.RESULT, $pe.guid, rec );
            return;
        }

        if ( $pe.dbo ) {
            rec = new Recipe( $pe.guid, $pe.dbo, null );
            add( rec );
        } else if ( $pe.data ) {
            var fileData:String = String( $pe.data );
            var jsonString:String = StringUtils.trim(fileData);
            var newObjData:Object = JSONUtil.parse( jsonString, $pe.guid + $pe.table, "RecipeCache.loadSucceed" );
            if ( null == newObjData ) {
                Log.out( "RecipeCache.loadSucceed - error parsing modelInfo on import. guid: " + $pe.guid, Log.ERROR );
                CraftingEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.guid, null );
                return;
            } else {
                rec = new Recipe( $pe.guid, null, newObjData );
            }
            rec.save();
            add( rec );
        } else
			Log.out("RecipeCache.onRecipeLoaded - ERROR recipe data not found in fileName: " + $pe.guid + "  data: " + fileData, Log.ERROR );
	}

	static private function add( $rec:Recipe ):void {
		// check to make sure is not already there
		if ( null ==  _recipes[$rec.guid] ) {
			//Log.out( "RecipeCache.add modelInfo: " + $mi.toString(), Log.DEBUG );
			_recipes[$rec.guid] = $rec;
			CraftingEvent.create( ModelBaseEvent.RESULT, $rec.guid, $rec );
		} else {
			Log.out( "RecipeCache.add - Recipe already exists", Log.ERROR );
		}
	}

	static private function loadFailed( $pe:PersistenceEvent ):void {
        if ( Recipe.BIGDB_TABLE_RECIPE != $pe.table && Recipe.RECIPE_EXT != $pe.table )
			return;
		Log.out( "RecipeCache.loadFailed PersistenceEvent: " + $pe.toString(), Log.WARN );
        CraftingEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.guid, null );
	}

	static private function loadNotFound( $pe:PersistenceEvent):void {
        if ( Recipe.BIGDB_TABLE_RECIPE != $pe.table && Recipe.RECIPE_EXT != $pe.table )
			return;
		Log.out( "RecipeCache.loadNotFound PersistenceEvent: " + $pe.toString(), Log.WARN );
        CraftingEvent.create( ModelBaseEvent.REQUEST_FAILED, $pe.guid, null );
	}

	public static function getClass( $className : String ) : Class
	{
		//noinspection BadExpressionStatementJS
		Pick;
		try 
		{
			var asset:Class = Class ( getDefinitionByName ( "com.voxelengine.worldmodel.crafting.items." + $className ) );
		}
		catch ( error:Error )
		{
			Log.out( "RecipeCache.getClass - ERROR - getDefinitionByName failed to find: com.voxelengine.worldmodel.crafting.items." + $className + " ERROR: " + error, Log.ERROR );
		}
		
		return asset;
	}

}
}