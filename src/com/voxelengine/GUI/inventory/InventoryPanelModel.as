/*==============================================================================
Copyright 2011-2017 Robert Flesch
All rights reserved.  This product contains computer programs, screen
displays and printed documentation which are original works of
authorship protected under United States Copyright Act.
Unauthorized reproduction, translation, or display is prohibited.
==============================================================================*/
package com.voxelengine.GUI.inventory {
import flash.display.DisplayObject;
import flash.events.Event;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.net.FileReference;
import flash.net.FileFilter;

import org.flashapi.swing.*
import org.flashapi.swing.core.UIObject;
import org.flashapi.swing.constants.*;
import org.flashapi.swing.event.*;
import org.flashapi.swing.dnd.*;
import org.flashapi.swing.layout.AbsoluteLayout;
import org.flashapi.swing.list.ListItem;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.VVContainer;
import com.voxelengine.GUI.WindowModelChoice;
import com.voxelengine.GUI.LanguageManager;
import com.voxelengine.GUI.VVBox;
import com.voxelengine.GUI.actionBars.QuickInventory;
import com.voxelengine.GUI.crafting.BoxCharacterSlot;
import com.voxelengine.GUI.voxelModels.PopupModelInfo;
import com.voxelengine.GUI.WindowModelDeleteChildrenQuery;
import com.voxelengine.GUI.WindowPictureImport;
import com.voxelengine.GUI.panels.PanelModelsListFromRegion;

import com.voxelengine.events.CharacterSlotEvent;
import com.voxelengine.events.OxelDataEvent;
import com.voxelengine.events.InventorySlotEvent;
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.worldmodel.models.ModelCacheUtils;
import com.voxelengine.worldmodel.models.Role;
import com.voxelengine.worldmodel.models.makers.ModelMaker;
import com.voxelengine.worldmodel.models.makers.ModelMakerClone;
import com.voxelengine.worldmodel.models.makers.ModelMakerImport;
import com.voxelengine.worldmodel.models.types.Player;
import com.voxelengine.server.Network;
import com.voxelengine.worldmodel.oxel.GrainCursor;
import com.voxelengine.worldmodel.inventory.FunctionRegistry;
import com.voxelengine.worldmodel.inventory.ObjectAction;
import com.voxelengine.worldmodel.inventory.ObjectInfo;
import com.voxelengine.worldmodel.inventory.ObjectModel;
import com.voxelengine.worldmodel.models.AssignModelAndChildrenToPublicOwnership;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.models.InstanceInfo;

public class InventoryPanelModel extends VVContainer
{
	// TODO need a more central location for these
	static public const MODEL_CAT_ARCHITECTURE:String = "Architecture";
	static public const MODEL_CAT_CHARACTERS:String = "Avatar";
	static public const MODEL_CAT_PLANTS:String = "Plant";
	static public const MODEL_CAT_FURNITURE:String = "Furniture";
	static public const MODEL_CAT_ISLAND:String = "Island";
	static public const MODEL_CAT_CRAFT:String = "Craft";
	static public const MODEL_CAT_CREATURE:String = "Creature";
	static public const MODEL_CAT_ALL:String = "All";

	static private const MODEL_CONTAINER_WIDTH:int = 512;
	static private const MODEL_IMAGE_WIDTH:int = 128;
	static private const MODEL_IMAGE_HEIGHT:int = 128;

	private var _dragOp:DnDOperation = new DnDOperation();
	private var _barLeft:TabBar;
	// This hold the items to be displayed
	// http://www.flashapi.org/spas-doc/org/flashapi/swing/ScrollPane.html
	private var _itemContainer:ScrollPane;
	private var _currentRow:Container;
    private var _source:String;
	private var _category:String = MODEL_CAT_ALL;

    private var _currentSeries:int;
    private function get currentSeries():int { return _currentSeries; }
    private function set currentSeries( $val:int ):void { _currentSeries = $val; }

	public function InventoryPanelModel( $parent:VVContainer, $source:String ) {
		super( $parent );
		_source = $source;
		layout.orientation = LayoutOrientation.HORIZONTAL;
		
		FunctionRegistry.functionAdd( createNewObjectIPM, "createNewObjectIPM" );
		FunctionRegistry.functionAdd( importObjectIPM, "importObjectIPM" );
		FunctionRegistry.functionAdd( importObjectStainedGlass, "importObjectStainedGlass" );

        ModelInfoEvent.addListener( ModelBaseEvent.CHANGED, modelInfoChanged );
        ModelInfoEvent.addListener( ModelBaseEvent.DELETE, removeModelInfoEvent );
        ModelInfoEvent.addListener( ModelBaseEvent.RESULT_RANGE, resultRangeModelInfoEvent );
        ModelInfoEvent.addListener( ModelInfoEvent.REASSIGN_PUBLIC, reassignPublicModelInfoEvent );

		upperTabsAdd();
		addItemContainer();
		var role:Role = Player.player.role;
		if ( _source == WindowInventoryNew.INVENTORY_OWNED || true == role.modelPublicDelete )
			addTrashCan();

        displaySelectedSource();
		
		// This forces the window into a multiple of MODEL_IMAGE_WIDTH width
		var count:int = width / MODEL_IMAGE_WIDTH;
		width = count * MODEL_IMAGE_WIDTH;
		
		eventCollector.addEvent( _dragOp, DnDEvent.DND_DROP_ACCEPTED, dropMaterial );
		
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_MOUSE_DOWN, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_MOUSE_MOVE, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_ENTER, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_MOVE_OVER, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_EXIT, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_DROP, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_COMPLETE, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_FINISH, dndTest );
		//eventCollector.addEvent( _dragOp, DnDEvent.DND_START, dndTest );
		//function dndTest(e:DnDEvent):void 
		//{
			//Log.out( "InventoryPanelModel.dndTest msg: " + e );
		//}		
	}
	
	private function upperTabsAdd():void {
		_barLeft = new TabBar();
		_barLeft.orientation = ButtonBarOrientation.VERTICAL;
		_barLeft.name = "left";
		// TODO I should really iterate thru the types and collect the categories - RSF
		_barLeft.addItem( LanguageManager.localizedStringGet( MODEL_CAT_ARCHITECTURE ), MODEL_CAT_ARCHITECTURE );
		_barLeft.addItem( LanguageManager.localizedStringGet( MODEL_CAT_CHARACTERS ), MODEL_CAT_CHARACTERS );
		_barLeft.addItem( LanguageManager.localizedStringGet( MODEL_CAT_CRAFT ), MODEL_CAT_CRAFT );
		_barLeft.addItem( LanguageManager.localizedStringGet( MODEL_CAT_CREATURE ), MODEL_CAT_CREATURE );
		_barLeft.addItem( LanguageManager.localizedStringGet( MODEL_CAT_ISLAND ), MODEL_CAT_ISLAND );
		_barLeft.addItem( LanguageManager.localizedStringGet( MODEL_CAT_PLANTS ), MODEL_CAT_PLANTS );


		var li:ListItem = _barLeft.addItem( LanguageManager.localizedStringGet( MODEL_CAT_ALL ), MODEL_CAT_ALL );
		_barLeft.setButtonsWidth( 96, 32 );
		_barLeft.selectedIndex = li.index;
		eventCollector.addEvent( _barLeft, ListEvent.ITEM_CLICKED, selectCategory );
		addGraphicElements( _barLeft );
	}

	private function addItemContainer():void {
		_itemContainer = new ScrollPane();
		_itemContainer.autoSize = false;
		_itemContainer.width = MODEL_CONTAINER_WIDTH + 15;
		_itemContainer.height = MODEL_IMAGE_HEIGHT;
		_itemContainer.scrollPolicy = ScrollPolicy.VERTICAL;
		_itemContainer.layout.orientation = LayoutOrientation.VERTICAL;
		addElement( _itemContainer );
	}
	
	private function addTrashCan():void {
		var infoContainer:Container;
		infoContainer = new Container();
		infoContainer.autoSize = true;
		addElement( infoContainer );

		var b:BoxTrashCan = new BoxTrashCan(100, 100, BorderStyle.RIDGE );
		b.backgroundTexture = "trashCan.png";
		b.dropEnabled = true;
		infoContainer.addElement( b );
	}
	
	private function selectCategory(e:ListEvent):void {
		var newCat:String = e.target.value as String;
		if ( _category != newCat ) {
			_category = newCat;
			while (1 <= _itemContainer.numElements) {
				_itemContainer.removeElementAt(0);
			}
			_barLeft.selectedIndex = -1;
			_currentRow = null;
            _itemContainer.removeElements();
            displaySelectedSource();
		}
	}

    // TODO I see problem here when language is different then what is in TypeInfo RSF - 11.16.14
	// That is if I use the target "Name"
	private function displaySelectedSource():void {
		// The series makes it so that I don't see results from other objects requests
		// This grabs the current series counter which will be used on the REQUEST_TYPE call
		if ( WindowInventoryNew.INVENTORY_OWNED == _source ) {
			addTools();
		}

        currentSeries = ModelBaseEvent.seriesCounter;
		if ( _source == WindowInventoryNew.INVENTORY_PUBLIC )
            ModelInfoEvent.create( ModelBaseEvent.REQUEST_TYPE, currentSeries, Network.PUBLIC, null );
		else if ( _source == WindowInventoryNew.INVENTORY_OWNED )
			ModelInfoEvent.create( ModelBaseEvent.REQUEST_TYPE, currentSeries, Network.userId, null );
		else
            ModelInfoEvent.create( ModelBaseEvent.REQUEST_TYPE, currentSeries, Network.storeId, null );
	}

    private function reassignPublicModelInfoEvent($mie:ModelInfoEvent):void {
        // For this to happen I have to be on the backpack page!
        if ( _source == WindowInventoryNew.INVENTORY_OWNED )
            removeModel( $mie.modelGuid );
    }

    private function removeModelInfoEvent( $mie:ModelInfoEvent ):void {
		removeModel( $mie.modelGuid );
	}

    private function resultRangeModelInfoEvent( $mie:ModelInfoEvent ):void {
        //trace( "IPM.resultRangeModelInfoEvent series: " + currentSeries + "  $mie.series: " + $mie.series );
		if ( $mie.series == currentSeries )
        	addModel( $mie );
		else
        	Log.out( "IPM.resultRangeModelInfoEvent $mie.series: (" + $mie.series + ") != _seriesModelMetadataEvent (" + currentSeries + ")" );
    }

	private function modelInfoChanged( $mie:ModelInfoEvent ):void {
		// I only want the results from the series I asked for, or from models being added outside a series, like a generated or new model
        //Log.out( "IPM.modelInfoChanged series: " + $mme.series +  "  guid: " + $mme.modelGuid );
        var box:BoxInventory = findBoxWithModelGuid( $mie.modelInfo.guid );
		if ( null != box )
            box.updateModelInfo( $mie.modelInfo, true );
	}

    private function addModel( $mie:ModelInfoEvent ):void {
        var om:ObjectModel = new ObjectModel(null, $mie.modelGuid);
        //Log.out( "IPM.addModel guid: " + $mie.modelInfo.guid + "  " + $mie.modelInfo.name + "  hasTags: " + $mie.modelInfo.hashTags + "  found? " + $mie.modelInfo.hashTags.indexOf(cat));
        om.modelInfo = $mie.modelInfo;
        var cat:String = _category.toLowerCase();
        //Log.out( "IPM.addModel cat: " + cat + "  hasTags: " + $mie.modelInfo.hashTags + "  found? " + $mie.modelInfo.hashTags.indexOf(cat));
        if ( "all" == cat )
            qualifyAndPlaceModel(om);
        else if ( 0 <= $mie.modelInfo.hashTags.indexOf(cat))
            qualifyAndPlaceModel(om);
    }

//    private function updateModel( $mie:ModelInfoEvent ):void {
//     //   ModelBaseEvent.UPDATE
//        var box:BoxInventory = findFirstEmpty();
//        if ( box ) {
//            box.updateObjectInfo($oi);
//        }
//    }

	private function qualifyAndPlaceModel( $oi:ObjectInfo, allowDrag:Boolean = true ):BoxInventory {
		//// Add the filled bar to the container and create a new container
		if ( ObjectInfo.OBJECTINFO_MODEL == $oi.objectType ) {
			var om:ObjectModel = $oi as ObjectModel;
			// don't show CURRENT child models
            var pm:VoxelModel = PanelModelsListFromRegion.getLastSelectedModel();
			if ( pm ){
                var bound:int = pm.modelInfo.oxelPersistence.bound;
                if ( null != om.modelInfo.childOf && "" != om.modelInfo.childOf ) {
                    if ( pm.modelInfo.name != om.modelInfo.childOf ) {
                        //Log.out( "InventoryPanelModel.qualifyAndPlaceModel - child model of wrong parent: " + om.modelInfo.name, Log.INFO );
                        return null;
                    }
                } else {
                    if ( om.modelInfo.bound > bound ) {
                        //Log.out("InventoryPanelModel.qualifyAndPlaceModel - NOT child model of: " + om.modelInfo.name + " AND is larger", Log.WARN);
                        return null;
                    }
                }
            } else {
                if ( null != om.modelInfo.childOf && "" != om.modelInfo.childOf ) {
                    //Log.out( "InventoryPanelModel.qualifyAndPlaceModel - NOT adding child model of: " + om.vmm.name, Log.INFO );
                    return null;
                }
            }
//			if ( WindowInventoryNew.parentModel ) {
//				var bound:int = WindowInventoryNew.parentModel.modelInfo.oxelPersistence.bound;
//				if ( null != om.modelInfo.childOf && "" != om.modelInfo.childOf ) {
//					if ( WindowInventoryNew.parentModel.modelInfo.name != om.modelInfo.childOf ) {
//						Log.out( "InventoryPanelModel.qualifyAndPlaceModel - child model of wrong parent: " + om.modelInfo.name, Log.INFO );
//						return null;
//					}
//				} else {
//					if ( om.modelInfo.bound > bound ) {
//						Log.out("InventoryPanelModel.qualifyAndPlaceModel - NOT child model of: " + om.modelInfo.name + " AND is larger", Log.WARN);
//						return null;
//					}
//				}
//			} else {
//				if ( null != om.modelInfo.childOf && "" != om.modelInfo.childOf ) {
//					//Log.out( "InventoryPanelModel.qualifyAndPlaceModel - NOT adding child model of: " + om.vmm.name, Log.INFO );
//					return null;
//				}
//			}
		}
				
		var box:BoxInventory = findFirstEmpty();	
		if ( box ) {
			box.updateObjectInfo( $oi );
			if ( allowDrag )
				eventCollector.addEvent( box, UIMouseEvent.PRESS, doDrag);
			if ( WindowInventoryNew._s_hackSupportClick	)
				eventCollector.addEvent( box, UIMouseEvent.CLICK, instantiateModel );

			return box;
		}
		Log.out( "InventoryPanelModel.qualifyAndPlaceModel - Failed to qualifyAndPlaceModel: " + $oi, Log.ERROR );
		return null
	}

	static private function instantiateModel( e:UIMouseEvent ):void {
		if ( e.target.objectInfo is ObjectAction ) {
			var oa:ObjectAction = e.target.objectInfo as ObjectAction;
			var cb:Function = oa.callBack;
			// just execute the callback here, dont need to do cb(), which calls it twice, interesting
			//noinspection BadExpressionStatementJS
			cb;
		}
		else if ( e.target.objectInfo is ObjectModel ) {
            if ( PopupModelInfo.inExistance ) // They clicked on the edit button
				return;

			var om:ObjectModel = (e.target.objectInfo as ObjectModel);
			
			var ii:InstanceInfo = new InstanceInfo();
			ii.modelGuid = om.modelGuid;
			ii.instanceGuid = Globals.getUID();
			if ( WindowInventoryNew.parentModel ) {
                ii.controllingModel = WindowInventoryNew.parentModel;
                new ModelMakerClone( ii, om.modelInfo );
                om.modelInfo.changed = true;
                WindowInventoryNew.parentModel.modelInfo.changed = true;
            }
			else {
				new ModelMaker( ii );
			}
		}
	}

	private function addEmptyRow( $countMax:int ):void {
		_currentRow = new Container( MODEL_CONTAINER_WIDTH, MODEL_IMAGE_HEIGHT );
		_currentRow.layout = new AbsoluteLayout();
		_itemContainer.addElement( _currentRow );
		_itemContainer.height = _itemContainer.numElements * MODEL_IMAGE_WIDTH;
		for ( var i:int=0; i < $countMax; i++ ) {
			var box:BoxInventory = new BoxInventory(MODEL_IMAGE_WIDTH, MODEL_IMAGE_HEIGHT, BorderStyle.NONE );
			box.updateObjectInfo( new ObjectInfo( box, ObjectInfo.OBJECTINFO_EMPTY, ObjectInfo.DEFAULT_OBJECT_NAME ) );
			box.x = i * MODEL_IMAGE_WIDTH;
			_currentRow.addElement( box );
		}
	}
	
	private function findFirstEmpty():BoxInventory {
		var countMax:int = MODEL_CONTAINER_WIDTH / MODEL_IMAGE_WIDTH;
		if ( null == _currentRow )
			addEmptyRow( countMax );
		for ( var i:int=0; i < countMax; i++ ) {
			var bie:* = _currentRow.getElementAt( i );
			var bi:* = bie.getElement();
			var box:BoxInventory = bi as BoxInventory;
			var oi:ObjectInfo = box.objectInfo;
			if ( ObjectInfo.OBJECTINFO_EMPTY == oi.objectType )
				return box;
		}
		addEmptyRow( countMax );
		return findFirstEmpty();
	}

    private function findBoxWithModelGuid( $guid:String ):BoxInventory {

        var rows:int = _itemContainer.numElements;
        var countMax:int = MODEL_CONTAINER_WIDTH / MODEL_IMAGE_WIDTH;
        var row:Container;
		for ( var i:int = 0; i < rows; i++ ){
            row = (_itemContainer.getElementAt( i ) as Element).getElement() as Container;
            for ( var j:int=0; j < countMax; j++ ) {
                var bie:* = row.getElementAt( j );
                var bi:* = bie.getElement();
                var box:BoxInventory = bi as BoxInventory;
                if ( box.objectInfo && ObjectInfo.OBJECTINFO_MODEL == box.objectInfo.objectType ){
                    var om:ObjectModel = box.objectInfo as ObjectModel;
                    if ( om.modelInfo ) {
						if ( om.modelInfo.guid == $guid )
								return box;
                    }
            	}
			}
		}
		return null;
    }

    private function addTools():void {
		var box:BoxInventory = null;
		box = qualifyAndPlaceModel( new ObjectAction( box, "createNewObjectIPM", "NewModel128.png", "Click to create new model" ), false );
		eventCollector.addEvent( box, UIMouseEvent.CLICK, function( e:UIMouseEvent ):void { (e.target.objectInfo as ObjectAction).callBack(); } );
		
		box = qualifyAndPlaceModel( new ObjectAction( box, "importObjectStainedGlass", "importPicture128.png", "Click to import picture" ), false );
		eventCollector.addEvent( box, UIMouseEvent.CLICK, function( e:UIMouseEvent ):void { (e.target.objectInfo as ObjectAction).callBack(); } );

		if ( Globals.isDebug ) {
			box = qualifyAndPlaceModel( new ObjectAction( box, "importObjectIPM", "import128.png", "Click to import local model" ), false );
			eventCollector.addEvent( box, UIMouseEvent.CLICK, function( e:UIMouseEvent ):void { (e.target.objectInfo as ObjectAction).callBack(); } );
		}
	}
	
	static private function createNewObjectIPM():void {
		new WindowModelChoice();
		WindowInventoryNew._s_instance.remove()
	}
	
	static private function importObjectIPM():void {
		addDesktopModelHandler( null );
	}

	static private function importObjectStainedGlass():void {
		new WindowPictureImport();
	}

	static private function addDesktopModelHandler(event:UIMouseEvent):void {
		var fileRef:FileReference = new FileReference();
		fileRef.addEventListener(Event.SELECT, onDesktopModelFileSelected );
		fileRef.browse([new FileFilter("Model Files","*.mjson")]);
	}

	static public function onDesktopModelFileSelected(e:Event):void {
		Log.out( "onDesktopModelFileSelected : " + e.toString() );
		e.target.removeEventListener(Event.SELECT, onDesktopModelFileSelected );

		var fileName:String = e.currentTarget.name;
		fileName = fileName.substr( 0, fileName.indexOf( "." ) );

		var ii:InstanceInfo = new InstanceInfo();
		ii.modelGuid = fileName;
		new ModelMakerImport( ii );
	}



	private function removeModel( $modelGuid:String ):void {
		var countMax:int = MODEL_CONTAINER_WIDTH / MODEL_IMAGE_WIDTH;
		var column:int = 0;
		var rows:int = _itemContainer.numElements;
		for ( var row:int=0; row < rows; row++ ) {
			var rowElement:Element = _itemContainer.getElementAt( row );
			var rowCont:* = rowElement.getElement();
			for ( column = 0; column < countMax; column++ ) {
				var bie:* = rowCont.getElementAt( column );
				var bi:* = bie.getElement();
				var box:BoxInventory = bi as BoxInventory;
				var oi:ObjectInfo = box.objectInfo;
				if ( oi.objectType != ObjectInfo.OBJECTINFO_MODEL )
					continue;
				var om:ObjectModel = bi.objectInfo as ObjectModel;
				if ( om.modelGuid == $modelGuid ) {
					var newOI:ObjectInfo = new ObjectInfo(null, ObjectInfo.OBJECTINFO_EMPTY, ObjectInfo.DEFAULT_OBJECT_NAME);
					box.updateObjectInfo( newOI );
					//Log.out( "InventoryPanelModels.removeModel found model: " + $modelGuid );
					return;
				}
			}
		}
		Log.out( "InventoryPanelModels.removeModel DID NOT NOT find model: " + $modelGuid, Log.WARN );
	}
	
	private function dropMaterial(e:DnDEvent):void  {
		if ( e.dragOperation.initiator.data is ObjectModel )
		{
			//e.dropTarget.backgroundTexture = e.dragOperation.initiator.backgroundTexture;
			//e.dropTarget.data = e.dragOperation.initiator.data;
			//
			//if ( e.dropTarget.target is PanelMaterials ) {
				//CraftingItemEvent.dispatch( new CraftingItemEvent( CraftingItemEvent.MATERIAL_DROPPED, e.dragOperation.initiator.data as TypeInfo ) );	
			//}
			//else if ( e.dropTarget.target is PanelBonuses ) {
				//CraftingItemEvent.dispatch( new CraftingItemEvent( CraftingItemEvent.BONUS_DROPPED, e.dragOperation.initiator.data as TypeInfo ) );	
				//e.dropTarget.backgroundTextureManager.resize( 32, 32 );
			//}
			//else if ( e.dropTarget.target is QuickInventory ) {
			if ( e.dropTarget is BoxTrashCan ) {
				//var btc:BoxTrashCan = e.dropTarget as BoxTrashCan;
				var droppedItem:ObjectModel = e.dragOperation.initiator.data;
                ModelInfoEvent.addListener( ModelBaseEvent.RESULT, checkModelInfoPermissions );
                ModelInfoEvent.create( ModelBaseEvent.REQUEST, 0, droppedItem.modelGuid );
			}

			if ( e.dropTarget is BoxCharacterSlot ) {
				var bcs:BoxCharacterSlot = e.dropTarget as BoxCharacterSlot;
				var om:ObjectModel = e.dragOperation.initiator.data;
				if ( om.modelInfo && om.modelInfo.thumbnailLoaded && om.modelInfo.thumbnail)
					bcs.backgroundTexture = VVBox.drawScaled(om.modelInfo.thumbnail, bcs.width, bcs.height);

				CharacterSlotEvent.create( CharacterSlotEvent.CHANGE, Network.userId, bcs.data, om.modelGuid );
				Log.out( "InventoryPanelModel.dropMaterial - slot: " + bcs.data + "  guid: " + om.modelGuid, Log.WARN );
			}

			if ( e.dropTarget.target is QuickInventory ) {
				if ( e.dropTarget is BoxInventory ) {
					var bi:BoxInventory = e.dropTarget as BoxInventory;
					var item:ObjectModel = e.dragOperation.initiator.data;
					bi.updateObjectInfo( item, false );
					var slotId:int = int( bi.name );
					InventorySlotEvent.create( InventorySlotEvent.CHANGE, Network.userId, Network.userId, slotId, item );
					// we are going to need the oxelPersistence to build the model for this.
                    Log.out( "InventoryPanelModel.dropMaterial - ", Log.DEBUG );
					OxelDataEvent.create( ModelBaseEvent.REQUEST, 0, item.modelGuid, null );
				}
			}
		}

        function checkModelInfoPermissions( $mi:ModelInfoEvent ):void {
			if ( $mi.modelGuid == droppedItem.modelGuid ) {
                ModelInfoEvent.removeListener(ModelBaseEvent.RESULT, checkModelInfoPermissions);
                var role:Role = Player.player.role;
                if ($mi.modelInfo.owner == Network.PUBLIC && role.modelPublicDelete) {
                    new WindowModelDeleteChildrenQuery(droppedItem.modelGuid, removeModel);
                }
                else if ($mi.modelInfo.owner == Network.userId && role.modelPrivateDelete) {
                    new AssignModelAndChildrenToPublicOwnership( droppedItem.modelGuid, true );
                    //new WindowModelDeleteChildrenQuery(droppedItem.modelGuid, removeModel);
                }
                else {
                    (new Alert("You (" + Network.userId + " as a " + role.name + " do not have required permissions to delete this object owned by " + $mi.modelInfo.owner).display(600));
                }
            }

        }
	}


	private function doDrag(e:UIMouseEvent):void {
		_dragOp.initiator = e.target as UIObject;
		_dragOp.dragImage = e.target as DisplayObject;
		// this adds a drop format, which is checked again what the target is expecting
//		_dragOp.resetDropFormat();
//		var dndFmt:DnDFormat = new DnDFormat( e.target.data.category, e.target.data.subCat );
//		_dragOp.addDropFormat( dndFmt );
		
		UIManager.dragManager.startDragDrop(_dragOp);
	}			
	
	override protected function onRemoved( event:UIOEvent ):void {
        ModelInfoEvent.removeListener( ModelBaseEvent.CHANGED, modelInfoChanged );
        ModelInfoEvent.removeListener( ModelBaseEvent.DELETE, removeModelInfoEvent );
        ModelInfoEvent.removeListener( ModelBaseEvent.RESULT_RANGE, resultRangeModelInfoEvent );
        ModelInfoEvent.removeListener( ModelInfoEvent.REASSIGN_PUBLIC, reassignPublicModelInfoEvent );
	}
}
}