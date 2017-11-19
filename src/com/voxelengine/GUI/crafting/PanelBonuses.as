/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.crafting {
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.dnd.DnDFormat;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.CraftingItemEvent;
	import com.voxelengine.GUI.panels.PanelBase;	
	import com.voxelengine.GUI.LanguageManager;
	import com.voxelengine.worldmodel.TypeInfo;
	import com.voxelengine.worldmodel.crafting.Bonus;
	import com.voxelengine.worldmodel.crafting.Recipe;
	
	// all of the keys used in resourceGet are in the file en.xml which is in the assets/language/lang_en/ dir
	public class PanelBonuses extends PanelBase {
        private const BOX_SIZE:int = 32;

        public function PanelBonuses($parent:PanelBase, $widthParam:Number, $heightParam:Number, $recipe:Recipe) {
            super($parent, $widthParam, $heightParam);

            addElement(new Label("Bonuses"));
            padding = 5;
            var optionals:Boolean;
            if ($recipe) {
                for each(var bonus:Bonus in $recipe.bonuses) {
                    optionals = bonus.optional;
                    var lb:Label = new Label(LanguageManager.localizedStringGet(bonus.subCat) + (bonus.optional ? "*" : ""));
                    addElement(lb);
                    var subCat:String = bonus.subCat.toUpperCase();
                    addElement(buildBonusBox(bonus));
                }
                if (optionals)
                    addElement(new Label("*=" + LanguageManager.localizedStringGet("optional")));
            }
        }

        private function doDrag(e:UIMouseEvent):void {
            // reset the material
            var mb:Box = e.target as Box;
            mb.backgroundTexture = null;
            var ti:TypeInfo = TypeInfo.typeInfo[mb.data.type];
            CraftingItemEvent.create(CraftingItemEvent.BONUS_REMOVED, ti);
        }

        private function buildBonusBox(bonus:Bonus):Box {
            var subCat:String = bonus.subCat.toUpperCase();
            var mb:Box = new BoxCraftingBase(BOX_SIZE, bonus.category, bonus.subCat);


            eventCollector.addEvent(mb, UIMouseEvent.PRESS, doDrag);


            return mb;
        }

        override public function remove():void {
            super.remove();
        }
    }
}