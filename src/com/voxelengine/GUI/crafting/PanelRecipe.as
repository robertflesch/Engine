/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.crafting 
{
import com.voxelengine.events.CraftingItemEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.events.ModelLoadingEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.crafting.RecipeCache;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.ModelInfo;
import com.voxelengine.worldmodel.models.ModelStatisics;
import com.voxelengine.worldmodel.models.makers.ModelMaker;
import com.voxelengine.worldmodel.models.makers.ModelMakerClone;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.Oxel;

import org.flashapi.swing.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.panels.PanelBase;
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
    private var _craftButton:Button;

	private var _recipe:Recipe;
	
	public function PanelRecipe( $parent:PanelBase, $widthParam:Number, $heightParam:Number, $recipe:Recipe )
	{
		super( $parent, $widthParam, $heightParam );
        _recipe = $recipe;
		borderStyle = BorderStyle.NONE;
		autoSize = true;
		padding = 0;
		layout.orientation = LayoutOrientation.VERTICAL;
		
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
        CraftingItemEvent.addListener( CraftingItemEvent.REQUIREMENTS_MET, requirementTest );
        _craftButton = new Button( LanguageManager.localizedStringGet( "Craft_Item" ) );
        _craftButton.color = 0xff0000;
		eventCollector.addEvent( _craftButton, UIMouseEvent.CLICK, craft );
		_panelButtons.addElement( _craftButton );
		_panelButtons.addElement( new Label( "Drag Items from Inventory", 200 ) );
	}

	private function requirementTest( $cie:CraftingItemEvent ):void {
		if ( null == $cie.typeInfo ){
            _craftButton.color = 0x00ff00;
		}
		else
        	_craftButton.color = 0xff0000;
    }

	override public function remove():void {
		super.remove();
	}
	
	override public function close():void 
	{
		//super.onRemoved(e);
		_recipe = null;
		_panelForumla.remove();
		_panelBonuses.remove();
		_panelMaterials.remove();
		_panelPreview.remove();
		_panelButtons.remove();
		
	}

    private var _instanceGuid:String;
	private function craft( e:UIMouseEvent ):void {
		// create model using templateID and replace the components with materials
        if ( _recipe ) {
            ModelInfoEvent.addListener( ModelBaseEvent.RESULT, modelInfoReceived );
			ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, _recipe.templateId );
        }
	}

	private function modelInfoReceived( $mie:ModelInfoEvent ):void {
		if ( $mie.modelInfo.guid == _recipe.templateId ){
            ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST, modelInfoReceived );
            var mi:ModelInfo = $mie.modelInfo;
			mi.modelClass = _recipe.className;

            var ii:InstanceInfo 	= new InstanceInfo();
            ii.modelGuid			= _recipe.templateId;
            _instanceGuid 			= ii.instanceGuid		= Globals.getUID();
            ii.name					= _recipe.name;
            OxelDataEvent.addListener( OxelDataEvent.OXEL_BUILD_COMPLETE, templateComplete );
            ModelLoadingEvent.addListener( ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete );
            ModelInfoEvent.addListener( ModelBaseEvent.REQUEST_FAILED, modelInfoFailed );

            new ModelMakerClone( ii, mi );
		}
	}

    private function modelInfoFailed( $mie:ModelInfoEvent ):void {
		if ( _recipe.templateId == $mie.modelInfo.guid ){
			(new Alert("An error has occurred, please try again later")).display();
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_BUILD_COMPLETE, templateComplete);
            ModelLoadingEvent.removeListener(ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete);
            ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, modelInfoFailed );
			_parent.remove();
		}
	}

    private function modelLoadComplete( $mle:ModelLoadingEvent ): void {
        if ( $mle.data.modelGuid == _recipe.templateId ) {
            OxelDataEvent.removeListener(OxelDataEvent.OXEL_BUILD_COMPLETE, templateComplete);
            ModelLoadingEvent.removeListener(ModelLoadingEvent.MODEL_LOAD_COMPLETE, modelLoadComplete);
            ModelInfoEvent.removeListener( ModelBaseEvent.REQUEST_FAILED, modelInfoFailed );

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
		if ( $ode.modelGuid == _recipe.templateId ){
            OxelDataEvent.removeListener( OxelDataEvent.OXEL_BUILD_COMPLETE, templateComplete );
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
	
	public function get recipe():Recipe
	{
		return _recipe;
	}
}
}