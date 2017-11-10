/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.crafting 
{
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.crafting.CraftingManager;
import com.voxelengine.worldmodel.crafting.items.CraftedItem;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelStatisics;
import com.voxelengine.worldmodel.models.makers.ModelMaker;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.Oxel;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.panels.PanelBase;
import com.voxelengine.GUI.VoxelVerseGUI;
import com.voxelengine.worldmodel.crafting.Recipe;
import com.voxelengine.GUI.LanguageManager;

public class PanelRecipe extends PanelBase
{
	private var _panelForumla:PanelBase;
	private var _panelButtons:PanelBase;
	private var _panelMaterials:PanelMaterials;
	private var _panelBonuses:PanelBonuses;
	private var _panelPreview:PanelPreview;
	private var _recipeDesc:Label;
    private var _recipe:Label;
	
	private var _craftedItem:CraftedItem;
	
	public function PanelRecipe( $parent:PanelBase, $widthParam:Number, $heightParam:Number, $recipe:Recipe )
	{
		super( $parent, $widthParam, $heightParam );
		borderStyle = BorderStyle.NONE;
		autoSize = true;
		padding = 0;
		layout.orientation = LayoutOrientation.VERTICAL;
		
		var craftedClass:Class = CraftingManager.getClass( $recipe.className );
		if ( craftedClass )
			_craftedItem = new craftedClass( $recipe );
		
		_recipeDesc = new Label( "", 300 );
		addElement( _recipeDesc );
		if ( $recipe )
			_recipeDesc.text = $recipe.desc;
		
		_panelForumla = new PanelBase( this, $widthParam, $heightParam - 30 );
		_panelForumla.layout.orientation = LayoutOrientation.HORIZONTAL;
		addElement( _panelForumla );
		
		_panelBonuses = new PanelBonuses( this, $widthParam / 2, $height, $recipe );
		_panelBonuses.borderStyle = BorderStyle.NONE;

		_panelForumla.addElement( _panelBonuses );
		
		_panelMaterials = new PanelMaterials( this, $widthParam / 2, $height, $recipe );
		_panelForumla.addElement( _panelMaterials );
		
		_panelPreview = new PanelPreview( this, $widthParam / 2, $height, $recipe );
		_panelPreview.borderStyle = BorderStyle.NONE;
		_panelForumla.addElement( _panelPreview );
		
		_panelButtons = new PanelBase( this, $width, 30 );
		_panelButtons.layout.orientation = LayoutOrientation.HORIZONTAL;
		_panelButtons.borderStyle = BorderStyle.NONE;
		_panelButtons.padding = 5;
		addElement( _panelButtons );
		var craftButton:Button = new Button( LanguageManager.localizedStringGet( "Craft_Item" ) );
		craftButton.color = 0x333333;
		eventCollector.addEvent( craftButton, UIMouseEvent.CLICK, craft );
		_panelButtons.addElement( craftButton );
		_panelButtons.addElement( new Label( "Drag Items from Inventory", 200 ) );
	}
	
	override public function remove():void {
		super.remove();
	}
	
	override public function close():void 
	{
		//super.onRemoved(e);
		_craftedItem.cancel();
		_craftedItem = null;
		_panelForumla.remove();
		_panelBonuses.remove();
		_panelMaterials.remove();
		_panelPreview.remove();
		_panelButtons.remove();
		
	}

    private var _instanceGuid:String;
	private function craft( e:UIMouseEvent ):void {
		// create model using templateID and replace the components with materials
        if ( _craftedItem ) {
            var craftItemII:InstanceInfo 	= new InstanceInfo();
            craftItemII.modelGuid			= _craftedItem.templateId;
//            craftItemII.positionSet 		= point;
            _instanceGuid = craftItemII.instanceGuid		= Globals.getUID();
            craftItemII.name				= _craftedItem.name;
            OxelDataEvent.addListener( OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, templateComplete );
            ModelLoadingEvent.addListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete );
            new ModelMaker( craftItemII, true , false );
        }
		
	}

    private function modelLoadComplete( $mle:ModelLoadingEvent ): void {
        if ( $mle.data.modelGuid == _craftedItem.templateId ) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, templateComplete);
            ModelLoadingEvent.removeListener(ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete);

            var ms:ModelStatisics = $mle.vm.modelInfo.oxelPersistence.statistics;
            var stats:Array = ms.stats;
            for ( var key:* in stats ) {
                if ( !isNaN( key ) ) {
                    var ti:TypeInfo = TypeInfo.typeInfo[key];
                    if ( ti )
                        Log.out( "Contains " + stats[key]/(16*16*16) + " cubic meters of " + ti.name);
                }
            }
        }
	}


	// its built and ready to have its materials replaced
	private function templateComplete(  $ode:OxelDataEvent ): void {
		if ( $ode.modelGuid == _craftedItem.templateId ){
            OxelDataEvent.removeListener( OxelDataEvent.OXEL_QUADS_BUILT_COMPLETE, templateComplete );
            ModelLoadingEvent.removeListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete );

            var oxel:Oxel = $ode.oxelPersistence.oxel;
			// I have the ToType, where do I get the from type?
			// could I use the oxel statistics?
			// should be able to find category from there, and the id
            var vm:VoxelModel =  Region.currentRegion.modelCache.instanceOfModelWithInstanceGuid( $ode.modelGuid, _instanceGuid );
            var ms:ModelStatisics = vm.modelInfo.oxelPersistence.statistics;
			var stats:Array = ms.stats;
            for ( var key:* in stats ) {
                if ( !isNaN( key ) ) {
                    var ti:TypeInfo = TypeInfo.typeInfo[key]
                    if ( ti )
                        Log.out( "Contains " + stats[key]/16*16*16 + " cubic meters of " + ti.name);
                }
            }

//            oxel.changeTypeFromTo( fromType, toType );
//            _vm.modelInfo.oxelPersistence.changed = true;
//            _vm.modelInfo.oxelPersistence.save()

		}
	}
	
	public function get craftedItem():CraftedItem 
	{
		return _craftedItem;
	}
}
}