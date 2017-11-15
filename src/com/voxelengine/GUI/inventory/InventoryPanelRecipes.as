/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.inventory {

import com.voxelengine.events.CraftingEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.crafting.Bonus;
import com.voxelengine.worldmodel.crafting.Material;
import com.voxelengine.worldmodel.crafting.Recipe;
import com.voxelengine.worldmodel.crafting.RecipeCache;

import org.flashapi.swing.*
	import org.flashapi.swing.core.UIObject;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.list.ListItem;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.GUI.*;
	
	public class InventoryPanelRecipes extends VVContainer {
        // TODO need a more central location for these
        static public const MODEL_CAT_1:String = "GOD KNOWS 1";
        static public const MODEL_CAT_2:String = "GOD KNOWS 2";
        static public const MODEL_CAT_3:String = "GOD KNOWS 3";
        static public const MODEL_CAT_4:String = "GOD KNOWS 4";

        private var _barUpper:TabBar = new TabBar();
        // This hold the items to be displayed
        private var _itemContainer:Container;
        private var _listbox1:ListBox;

        public function InventoryPanelRecipes($parent:VVContainer, $dataSource:String) {
            super($parent);
            width = $parent.width;
            layout.orientation = LayoutOrientation.VERTICAL;

            addItemContainer();
            CraftingEvent.addListener(ModelBaseEvent.RESULT, recipeLoadedEvent);
            CraftingEvent.addListener(ModelBaseEvent.RESULT_RANGE, recipeLoadedEvent);


            displaySelectedSource($dataSource);
        }

        private function addItemContainer():void {
            _itemContainer = new Container(width, height);
            _itemContainer.autoSize = true;
            _itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
            addElement(_itemContainer);
            _listbox1 = new ListBox(width, 15);
            _itemContainer.addElement(_listbox1);
//            eventCollector.addEvent( _listbox1, UIMouseEvent.CLICK, editThisRecipe );
        }


//        private function editThisRecipe(event:UIMouseEvent):void  {
//            if ( -1 == _listbox1.selectedIndex )
//                return;
//
//            var li:ListItem = _listbox1.getItemAt( _listbox1.selectedIndex );
//            if ( li ) {
//                //RegionEvent.removeListener( ModelBaseEvent.RESULT, regionLoadedEvent );
//                //new WindowRegionDetail( li.data, null );
//            }
//        }
//
    private function displaySelectedSource($dataSource:String):void {
        _listbox1.removeAll();

        CraftingEvent.create(ModelBaseEvent.REQUEST_TYPE, Network.userId, null);
//            if ( $dataSource == WindowInventoryNew.INVENTORY_OWNED )
//                CraftingEvent.create( ModelBaseEvent.REQUEST_TYPE, Network.userId, null );
//            else
//                CraftingEvent.create( ModelBaseEvent.REQUEST_TYPE, Network.storeId, null );
    }

    private function recipeLoadedEvent($ce:CraftingEvent):void {
        var recipe:Recipe = $ce.recipe;
        var nameString:String = recipe.name;
        nameString = padStringToLength(nameString, 20);

        var bonusString:String = "Bonuses: ";
        for each (var bonus:Bonus in recipe.bonuses) {
            bonusString += " " + bonus.subCat.charAt(0).toUpperCase() + bonus.subCat.substr(1).toLowerCase(); // + "\u263a" smiley face
        }
        bonusString = padStringToLength(bonusString, 52);
        var matString:String = "Materials: ";
        for each (var mat:Material in recipe.materials) {
            matString += " " + mat.category.charAt(0).toUpperCase() + mat.category.substr(1).toLowerCase();
        }
        _listbox1.addItem(nameString+bonusString+matString);
    }

    private function padStringToLength($toBePadded, $len:int):String {
        var tabsToAdd:int = ($len - $toBePadded.length -1)/4;
        for (var i:int = 0; i < tabsToAdd; i++) {
            $toBePadded += "\t";
        }
        $toBePadded += "\t";
        return $toBePadded;
    }
}
}