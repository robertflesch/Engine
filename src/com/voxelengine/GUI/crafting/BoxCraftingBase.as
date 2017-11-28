/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package com.voxelengine.GUI.crafting {

import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.dnd.DnDFormat;

import com.voxelengine.GUI.inventory.BoxInventory;
import com.voxelengine.events.CraftingItemEvent;
import com.voxelengine.events.InventoryVoxelEvent;
import com.voxelengine.server.Network;


public class BoxCraftingBase extends BoxInventory {

    private var _acceptsCategory:String;
    private var _acceptsSubCat:String;
    private var _dndFmt:DnDFormat;
    public function BoxCraftingBase( $size:Number, $acceptsCategory:String, $acceptsSubCat:String = "", $borderStyle:String = BorderStyle.INSET ) {
        super($size, $size, borderStyle);
        _acceptsCategory = $acceptsCategory;
        _acceptsSubCat = $acceptsSubCat;

        dropEnabled = true;
        dragEnabled = true;
        borderStyle = $borderStyle;
        _dndFmt = new DnDFormat( _acceptsCategory, _acceptsSubCat );
        addDropFormat( _dndFmt );

        CraftingItemEvent.addListener( CraftingItemEvent.MATERIAL_DROPPED, onMaterialDropped );
        CraftingItemEvent.addListener( CraftingItemEvent.MATERIAL_REMOVED, onMaterialRemoved );
        _countLabel.text = "";
    }

    private function onMaterialRemoved(e:CraftingItemEvent):void {
        trace( "BoxCraftingBase.onMaterialDropped" + e.typeInfo.category + " " + _acceptsCategory + " " + e.typeInfo.subCat + " " + _acceptsSubCat);
        if ( _acceptsCategory == e.typeInfo.category && ( _acceptsSubCat == e.typeInfo.subCat || _acceptsSubCat == "" ) ) {
            _type = 0;
            _countLabel.text = "";
            trace("BoxCraftingBase.onMaterialRemoved" + e.typeInfo);
        }
    }

    private function onMaterialDropped(e:CraftingItemEvent):void {
        trace( "BoxCraftingBase.onMaterialDropped category: " + e.typeInfo.category + " " + _acceptsCategory + "   subcat: " + e.typeInfo.subCat + " " + _acceptsSubCat);
        if ( _acceptsCategory == e.typeInfo.category && ( _acceptsSubCat == e.typeInfo.subCat || _acceptsSubCat == "" ) ) {
            var bi:BoxInventory = e.data as BoxInventory;
            _type = e.typeInfo.type;
            InventoryVoxelEvent.create(InventoryVoxelEvent.COUNT_REQUEST, Network.userId, e.typeInfo.type, null);
            _countLabel.text = bi.count;
        }
        //backgroundTexture = bi.backgroundTexture;
    }

    override public function remove():void {
        super.remove();
        _type = 0;
        removeDropFormat( _dndFmt );
    }
}
}