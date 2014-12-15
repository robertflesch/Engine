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
		Globals.craftingManager.addEventListener( CraftingItemEvent.MATERIAL_DROPPED, onMaterialDropped );	
		Globals.craftingManager.addEventListener( CraftingItemEvent.MATERIAL_REMOVED, onMaterialRemoved );	
		
		Globals.craftingManager.addEventListener( CraftingItemEvent.BONUS_DROPPED, onBonusDropped );	
		Globals.craftingManager.addEventListener( CraftingItemEvent.BONUS_REMOVED, onBonusRemoved );	
	}
	
	override public function cancel():void {
		Globals.craftingManager.removeEventListener( CraftingItemEvent.MATERIAL_DROPPED, onMaterialDropped );	
		Globals.craftingManager.removeEventListener( CraftingItemEvent.MATERIAL_REMOVED, onMaterialRemoved );	
		Globals.craftingManager.removeEventListener( CraftingItemEvent.BONUS_DROPPED, onBonusDropped );	
		Globals.craftingManager.removeEventListener( CraftingItemEvent.BONUS_REMOVED, onBonusRemoved );	
		_materialsUsed = null;
		_bonusesUsed = null;
		super.cancel();
	}
	
	public function statsGenerate():void {
		
	}
	
	public function hasMetRequirements():Boolean {
		var matFound:Boolean;
		for each ( var matReq:Material in _materialsRequired ) {
			matFound = false;
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
			if ( 1 != bonusUsed[$property] )
				est += bonusUsed[$property];
		return est;
	}
	
	public function estimate( $property:String ):String {
		Log.out( "CraftedItem.estimate for " + $property );
		
		var estimateMats:Number = calculateMaterialsFactor( $property );
		if ( 0 == estimateMats )
			return "requirements not met";
		var estimateBonus:Number = calculateBonusFactor( $property );
		var estTotal:Number = estimateMats + estimateBonus;
		return String ( estTotal - estTotal/10 ) + " - " + ( estTotal + estTotal/10 );
	}
	
	public function bonusAdd( $typeInfo:TypeInfo ):void {
		// replace existing bonus if it already has one of this type
		for ( var i:int = 0; i < _bonusesUsed.length; i++ ) {
			var bonus:TypeInfo = _bonusesUsed[i];
			if ( bonus.subCat == $typeInfo.subCat ) {
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
	
	public function materialRemove( $typeInfo:TypeInfo ):void {
		// replace existing bonus if it already has one of this type
		for ( var i:int = 0; i < _materialsUsed.length; i++ ) {
			var mat:TypeInfo = _materialsUsed[i];
			if ( mat.category == $typeInfo.category ) {
				_materialsUsed.splice( i, 1 );
				Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.STATS_UPDATED, $typeInfo ) );	
				return;
			}
		}
		Log.out( "CraftedItem.materialRemove - material: " + $typeInfo.category + " NOT FOUND" );
	}
	
	private function bonusRemove( $typeInfo:TypeInfo ):void {
		// replace existing bonus if it already has one of this type
		for ( var i:int = 0; i < _bonusesUsed.length; i++ ) {
			var bonus:TypeInfo = _bonusesUsed[i];
			if ( bonus.subCat == $typeInfo.subCat ) {
				_bonusesUsed.splice( i, 1 );
				Globals.craftingManager.dispatchEvent( new CraftingItemEvent( CraftingItemEvent.STATS_UPDATED, $typeInfo ) );	
				return;
			}
		}
		
		Log.out( "CraftedItem.bonusRemove - bonus: " + $typeInfo.category + " NOT FOUND" );
	}
	
	private function onMaterialDropped(e:CraftingItemEvent):void {
		materialAdd( e.typeInfo );
	}
	
	private function onMaterialRemoved(e:CraftingItemEvent):void {
		materialRemove( e.typeInfo );
	}
	
	private function onBonusDropped(e:CraftingItemEvent):void {
		bonusAdd( e.typeInfo );
	}
	
	private function onBonusRemoved(e:CraftingItemEvent):void {
		bonusRemove( e.typeInfo );
	}
}
}