/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.crafting {
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.worldmodel.crafting.Bonus;

import org.as3commons.collections.Set;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;

import com.voxelengine.Log;
import com.voxelengine.GUI.panels.PanelBase;
import com.voxelengine.GUI.LanguageManager;
import com.voxelengine.events.CraftingItemEvent;
import com.voxelengine.worldmodel.crafting.Material;
import com.voxelengine.worldmodel.crafting.Recipe;
import com.voxelengine.worldmodel.TypeInfo;

// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
public class PanelMaterials extends PanelBase
{
	private var boxArray:Array = [];
	private const BOX_SIZE:int = 64;
	private var _recipe:Recipe;
	public function PanelMaterials( $parent:PanelBase, $widthParam:Number, $heightParam:Number, $recipe:Recipe )
	{
		super( $parent, $widthParam, $heightParam );
		_recipe = $recipe;

		addElement( new Label( LanguageManager.localizedStringGet( "Materials" ) ) );
		padding = 5;
		var optionals:Boolean;
		if ( $recipe ) {
			for each( var mat:Material in $recipe.materials ) {
				optionals = mat.optional;
				var lb:Label = new Label( "(" + mat.quantity + ") " + LanguageManager.localizedStringGet( mat.category ) + (mat.optional ? "*" : "") );
				addElement( lb );

				var category:String = mat.category.toUpperCase();
				addElement( buildMaterialBox( category ) );
			}
			if ( optionals )
				addElement( new Label( "*=" + LanguageManager.localizedStringGet( "optional") ) );
		}
		CraftingItemEvent.addListener( CraftingItemEvent.MATERIAL_DROPPED, onMaterialDropped );
		CraftingItemEvent.addListener( CraftingItemEvent.MATERIAL_REMOVED, onMaterialRemoved );
	}

	public function askForFilter():void {
		var categories:Set = new Set();
		for each( var mat:Material in _recipe.materials )
			categories.add( mat.category.toUpperCase() );
		for each( var bonus:Bonus in _recipe.bonuses )
			categories.add( bonus.category.toUpperCase() );

		InventoryVoxelEvent.create( InventoryVoxelEvent.TYPES_FILTER, "", 0, categories );
	}

	private function onMaterialDropped(e:CraftingItemEvent):void {
		(_parent as PanelRecipe).recipe.materialAdd( e.typeInfo );
	}

	private function onMaterialRemoved(e:CraftingItemEvent):void {
		(_parent as PanelRecipe).recipe.materialRemove( e.typeInfo );
	}


	private function doDrag(e:UIMouseEvent):void
	{
		// reset the material
		var mb:Box = e.target as Box;
		mb.backgroundTexture = null;
		var ti:TypeInfo = TypeInfo.typeInfo[ mb.data.type ];
		CraftingItemEvent.create( CraftingItemEvent.MATERIAL_REMOVED, ti );
	}

	private function onDrop(e:DnDEvent):void
	{
		Log.out( "PanelMaterials.onDrop" );
	}

	private function buildMaterialBox( category:String ):Box
	{
		var mb:Box = new BoxCraftingBase( BOX_SIZE, category );
		mb.addEventListener( DnDEvent.DND_DROP, onDrop );
		eventCollector.addEvent( mb, UIMouseEvent.PRESS, doDrag);
		boxArray.push( mb );
		return mb;
	}

	override public function remove():void {
		super.remove();
		_recipe = null;
		CraftingItemEvent.removeListener( CraftingItemEvent.MATERIAL_DROPPED, onMaterialDropped );
		CraftingItemEvent.removeListener( CraftingItemEvent.MATERIAL_REMOVED, onMaterialRemoved );
		for each ( var mb:BoxCraftingBase in boxArray ){
			mb.remove();
		}
		boxArray.push( mb );
	}

}
}