/*==============================================================================
  Copyright 2011-2014 Robert Flesch
  All rights reserved.  This product contains computer programs, screen
  displays and printed documentation which are original works of
  authorship protected under uinted States Copyright Act.
  Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.crafting.items {
import com.voxelengine.events.CraftingItemEvent;
import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.worldmodel.crafting.Bonus;
import com.voxelengine.worldmodel.crafting.CraftingManager;
import com.voxelengine.worldmodel.crafting.Material;
import com.voxelengine.worldmodel.crafting.Recipe;
import com.voxelengine.worldmodel.TypeInfo;

/**
 * ...
 * @author Bob
 */
public class CraftedItem extends Recipe
{
	private var _materialsUsed:Vector.<TypeInfo> = new Vector.<TypeInfo>();
	private var _bonusesUsed:Vector.<TypeInfo> = new Vector.<TypeInfo>();
	
	public function CraftedItem( $recipe:Recipe ):void {
		super();
		copy( $recipe );
		Globals.craftingManager.addEventListener( CraftingItemEvent.DROPPED_MATERIAL, onMaterialDropped );	
		Globals.craftingManager.addEventListener( CraftingItemEvent.DROPPED_BONUS, onBonusDropped );	
	}
	
	override public function cancel():void {
		Globals.craftingManager.removeEventListener( CraftingItemEvent.DROPPED_MATERIAL, onMaterialDropped );	
		Globals.craftingManager.removeEventListener( CraftingItemEvent.DROPPED_BONUS, onBonusDropped );	
		_materialsUsed = null;
		_bonusesUsed = null;
		super.cancel();
	}
	
	public function statsGenerate():void {
		
	}
	
	public function hasMetRequirements():Boolean {
		var matFound:Boolean;
		for each ( var matReq:Material in _materialsRequired ) {
			if ( true == matReq.optional )
				continue;
			for each ( var matsUsed:TypeInfo in _materialsUsed ) {
				if ( matReq.category == matsUsed.category ) {
					matFound = true;
					break;
				}
			}
			if ( !matFound )
				return false;
		}
		return true;
	}
	
	private function calculateMaterialsFactor( $property:String ):Number {
		var est:Number = 0;
		for each ( var matReq:Material in _materialsRequired )
			for each ( var matsUsed:TypeInfo in _materialsUsed )
				if ( matReq.category == matsUsed.category )
					est += matReq[$property] * matsUsed[$property];
		return est;
	}
	
	private function calculateBonusFactor( $property:String ):Number {
		var est:Number = 0;
		for each ( var bonusUsed:TypeInfo in _bonusesUsed )
			est += bonusUsed[$property];
		return est;
	}
	
	public function estimate( $property:String ):String {
		var estimateMats:Number = calculateMaterialsFactor( $property );
		if ( 0 == estimateMats )
			return "requirements not met";
		var estimateBonus:Number = calculateBonusFactor( $property );
		var estimate:Number = estimateMats + estimateBonus;
		return String ( estimate - estimate/10 ) + " - " + ( estimate + estimate/10 );
	}
	
	public function bonusAdd( $typeInfo:TypeInfo ):void {
		// replace existing bonus if it already has one of this type
		for ( var i:int = 0; i < _bonusesUsed.length; i++ ) {
			var bonus:TypeInfo = _bonusesUsed[i];
			if ( bonus.category == $typeInfo.category ) {
				_bonusesUsed[i] = $typeInfo;
				Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.STATS_UPDATED, $typeInfo ) );	
				return;
			}
		}
		
		_bonusesUsed.push( $typeInfo );
		Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.STATS_UPDATED, $typeInfo ) );	
	}
	
	public function materialAdd( $typeInfo:TypeInfo ):void {
		// replace existing bonus if it already has one of this type
		for ( var i:int = 0; i < _materialsUsed.length; i++ ) {
			var mat:TypeInfo = _materialsUsed[i];
			if ( mat.category == $typeInfo.category ) {
				_materialsUsed[i] = $typeInfo;
				Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.STATS_UPDATED, $typeInfo ) );	
				return;
			}
		}
		
		_materialsUsed.push( $typeInfo );
		Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.STATS_UPDATED, $typeInfo ) );	
	}
	
	private function onBonusDropped(e:CraftingItemEvent):void {
		bonusAdd( e.typeInfo );
	}
	
	private function onMaterialDropped(e:CraftingItemEvent):void {
		materialAdd( e.typeInfo );
	}
}
}