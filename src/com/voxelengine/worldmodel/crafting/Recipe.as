/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under uinted States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.worldmodel.crafting {
import playerio.DatabaseObject;

import com.voxelengine.Log;
import com.voxelengine.events.CraftingItemEvent;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.models.PersistenceObject;

public class Recipe extends PersistenceObject
{
	static public const RECIPE_EXT:String = ".cjson";
	static public const BIGDB_TABLE_RECIPE:String = "recipe";

    private var _bonusesAllowed:Vector.<Bonus> = new Vector.<Bonus>();
    public function get bonuses():Vector.<Bonus> { return _bonusesAllowed; }
    private var _bonusesUsed:Vector.<TypeInfo> = new Vector.<TypeInfo>();
    public function get bonusesUsed():Vector.<TypeInfo> { return _bonusesUsed; }

    private var _materialsUsed:Vector.<TypeInfo> = new Vector.<TypeInfo>();
    public function get materialsUsed():Vector.<TypeInfo> { return _materialsUsed; }
    private var _materialsRequired:Vector.<Material> = new Vector.<Material>();
    public function get materials():Vector.<Material> { return _materialsRequired; }

	public function get name():String 			{ return dbo.recipe.name; }
	public function get className():String 		{ return dbo.recipe.className; }
	public function get desc():String 			{ return dbo.recipe.desc; }
	public function get subcat():String 		{ return dbo.recipe.subcat; }
	public function get preview():String 		{ return dbo.recipe.preview; }
	public function get templateId():String 	{ return dbo.recipe.templateId; }
	//////////////////
	public function Recipe( $guid:String, $dbo:DatabaseObject, $newData:Object ):void  {
		super( $guid, BIGDB_TABLE_RECIPE );

		if ( null == $dbo)
			assignNewDatabaseObject();
		else
			dbo = $dbo;

		if ( $newData )
			mergeOverwrite( $newData );

		init();

        CraftingItemEvent.addListener( CraftingItemEvent.MATERIAL_DROPPED, onMaterialDropped );
        CraftingItemEvent.addListener( CraftingItemEvent.MATERIAL_REMOVED, onMaterialRemoved );

        CraftingItemEvent.addListener( CraftingItemEvent.BONUS_DROPPED, onBonusDropped );
        CraftingItemEvent.addListener( CraftingItemEvent.BONUS_REMOVED, onBonusRemoved );
	}

	override protected function assignNewDatabaseObject():void {
        super.assignNewDatabaseObject();
		dbo.recipe = {};
        dbo.recipe.name			= "Invalid";
        dbo.recipe.className	= "Invalid";
        dbo.recipe.desc 		= "Invalid";
		dbo.recipe.subcat		= "Invalid";
        dbo.recipe.preview		= "none.jpg";
        dbo.recipe.templateId	= "";
    }

	public function init():void {
		if ( dbo.recipe.materials ) {
			var materialObj:Object = dbo.recipe.materials;
			for each ( var materialData:Object in materialObj ) {
				if ( materialData.material ) {
					var mat:Material = new Material();
					mat.fromJSON( materialData.material );
					_materialsRequired.push( mat )
				} else
					Log.out("Recipe.fromJSON - Null material found in recipe: " + name, Log.ERROR );
			}
		}

		if ( dbo.recipe.bonuses ) {
			var bonusObj:Object = dbo.recipe.bonuses;
			for each ( var bonusData:Object in bonusObj ) {
				if ( bonusData.bonus ) {
					var bonus:Bonus = new Bonus();
					bonus.fromJSON( bonusData.bonus );
					_bonusesAllowed.push( bonus )
				} else
					Log.out("Recipe.fromJSON - Null bonus found in recipe: " + name, Log.ERROR );
			}
		}
	}

//	public function copy( $recipe:Recipe ):void {
//		materialsRequired	= $recipe.materialsRequired;
//		bonusesAllowed		= $recipe.bonusesAllowed;
//		name				= $recipe.name;
//		className			= $recipe.className;
//		desc				= $recipe.desc;
//		subcat				= $recipe.subcat;
//		preview				= $recipe.preview;
//		templateId			= $recipe.templateId;
//	}

//	public function cancel():void {
//		materialsRequired = null;
//		bonusesAllowed = null;
//	}

	public function toString():String {
		return "name: " + name + "  desc: " + desc + "  subcat: " + subcat;
	}




//    override public function cancel():void {
//        CraftingItemEvent.removeListener( CraftingItemEvent.MATERIAL_DROPPED, onMaterialDropped );
//        CraftingItemEvent.removeListener( CraftingItemEvent.MATERIAL_REMOVED, onMaterialRemoved );
//        CraftingItemEvent.removeListener( CraftingItemEvent.BONUS_DROPPED, onBonusDropped );
//        CraftingItemEvent.removeListener( CraftingItemEvent.BONUS_REMOVED, onBonusRemoved );
//        _materialsUsed = null;
//        _bonusesUsed = null;
//        super.cancel();
//    }

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
                CraftingItemEvent.create( CraftingItemEvent.STATS_UPDATED, $typeInfo );
                return;
            }
        }

        _bonusesUsed.push( $typeInfo );
        CraftingItemEvent.create( CraftingItemEvent.STATS_UPDATED, $typeInfo );
    }

    public function materialAdd( $typeInfo:TypeInfo ):void {
        // replace existing bonus if it already has one of this type
        for ( var i:int = 0; i < _materialsUsed.length; i++ ) {
            var mat:TypeInfo = _materialsUsed[i];
            if ( mat.category == $typeInfo.category ) {
                _materialsUsed[i] = $typeInfo;
                CraftingItemEvent.create( CraftingItemEvent.STATS_UPDATED, $typeInfo );
                return;
            }
        }

        _materialsUsed.push( $typeInfo );
        CraftingItemEvent.create( CraftingItemEvent.STATS_UPDATED, $typeInfo );
    }

    public function materialRemove( $typeInfo:TypeInfo ):void {
        // replace existing bonus if it already has one of this type
        for ( var i:int = 0; i < _materialsUsed.length; i++ ) {
            var mat:TypeInfo = _materialsUsed[i];
            if ( mat.category == $typeInfo.category ) {
                _materialsUsed.splice( i, 1 );
                CraftingItemEvent.create( CraftingItemEvent.STATS_UPDATED, $typeInfo );
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
                CraftingItemEvent.create( CraftingItemEvent.STATS_UPDATED, $typeInfo );
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