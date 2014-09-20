
package com.voxelengine.GUI
{
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.worldmodel.animation.Animation;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.Region;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import org.flashapi.collector.EventCollector;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
import org.flashapi.swing.button.RadioButtonGroup;
import org.flashapi.swing.databinding.DataProvider;
import flash.events.Event;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.worldmodel.models.VoxelModel;
	
public class WindowAnimationEdit extends VVPopup
{
	static private var _s_currentInstance:WindowAnimationEdit = null;
	
	private var _eventCollector:EventCollector = new EventCollector();
	private var _panelAdvanced:Panel;
	
	private var _anim:Animation;
	
	private static const BORDER_WIDTH:int = 4;
	private static const BORDER_WIDTH_2:int = BORDER_WIDTH * 2;
	private static const BORDER_WIDTH_3:int = BORDER_WIDTH * 3;
	private static const BORDER_WIDTH_4:int = BORDER_WIDTH * 4;
	private static const PANEL_HEIGHT:int = 115;
	
	private var _calculatedWidth:int = 300;
	private var _calculatedHeight:int = 20;

	private var _name:String;
	private var _desc:LabelInput;
	private var _animCombo:ComboBox
	
	static public function get currentInstance():WindowAnimationEdit { return _s_currentInstance; }
	
	public function WindowAnimationEdit( $anim:Animation )
	{
		super( "Animation Editor" );
		_s_currentInstance = this;
		
		_anim = $anim;
		//onCloseFunction = closeFunction;
		defaultCloseOperation = ClosableProperties.CALL_CLOSE_FUNCTION;
		layout.orientation = LayoutOrientation.VERTICAL;
		autoSize = true;
		shadow = true;
		
		
		addElement( new Label( "Animation Type: " + _anim.name ) );
		
		_desc = new LabelInput( "Description: ", _anim.desc );
		addElement( _desc );
		
		var saveMetadata:Button = new Button( "Save" );
		eventCollector.addEvent( saveMetadata, UIMouseEvent.CLICK, save );
		addElement( saveMetadata );
		
		var cancelButton:Button = new Button( "Cancel" );
		eventCollector.addEvent( cancelButton , UIMouseEvent.CLICK
							   , function( e:UIMouseEvent ):void { remove(); } );
		addElement( cancelButton );

		eventCollector.addEvent( this, Event.RESIZE, onResize );
		eventCollector.addEvent( this, UIOEvent.REMOVED, onRemoved );
		
		//LocationGroup();
		//RotationGroup();
		//Advanced();
		//CenterGroup();
		display( 600, 20 );
	}
	private function save( e:UIMouseEvent ):void { 
//		Globals.g_app.dispatchEvent( new AnimationMetadataEvent( AnimationMetadataEvent.ANIMATION_INFO_COLLECTED, _name, _desc.label, _guid, Persistance.PUBLIC ) );
		remove();
	}
	
	private function animationSelected( e:ListEvent ):void { 
		//var li:ListItem = _animCombo.getItemAt( _animCombo.selectedIndex );
		//_name = li.value;
	}
	protected function onResize(event:Event):void
	{
		move( Globals.g_renderer.width / 2 - (width + 10) / 2, Globals.g_renderer.height / 2 - (height + 10) / 2 );
		//display( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
	}
	
	private function onRemoved( event:UIOEvent ):void
	{
		eventCollector.removeAllEvents();
	}
	
		/*
		private function addSpinLabel( parentPanel:Panel, label:String, clickHandler:Function, textChanged:Function, initialValue:String ):TextInput
		{
			var lbl:Label = new Label(label);
			lbl.width = 80;
			lbl.height = 20;
			
			var src:TextInput = new TextInput(initialValue);
			src.width = 80;
			src.height = 20;
			src.x = 100;
			src.addEventListener( TextEvent.EDITED, textChanged );
			
			var sb:SpinButton = new SpinButton( 20, 20 );
			sb.addEventListener( SpinButtonEvent.CLICK_DOWN, clickHandler );
			sb.addEventListener( SpinButtonEvent.CLICK_UP, clickHandler );
			sb.data = src;

			//var myWidth:int = li.width + sb.width + BORDER_WIDTH_4 + BORDER_WIDTH_2;
			//var myHeight:int = sb.height + BORDER_WIDTH_4;
			
			var panel:Panel = new Panel( 300, 100 );
			panel.layout.orientation = LayoutOrientation.HORIZONTAL;
			
			panel.addElement( lbl );
			panel.addElement( src );
			panel.addElement( sb );
			panel.width = lbl.width + src.width + sb.width + BORDER_WIDTH_4 + BORDER_WIDTH_2;
			panel.height = sb.height + BORDER_WIDTH_4;
			panel.borderWidth = BORDER_WIDTH;
			parentPanel.addElement( panel );
			
			//_calculatedWidth = Math.max( panel.width, _calculatedWidth );
			//_calculatedHeight += panel.height;
			
			return src;
		}
		
		private function addLabel( parentPanel:Panel, label:String, changeHandler:Function, initialValue:String, inputEnabled:Boolean = false ):LabelInput
		{
			var li:LabelInput = new LabelInput( label, initialValue );
			li.labelControl.width = 120;
			if ( null != changeHandler )
				li.editableText.addEventListener( TextEvent.EDITED, changeHandler );
			else
			{
				li.editableText.editable = false;
				li.editableText.fontColor = 0x888888;
			}

			var myWidth:int = li.width + BORDER_WIDTH_4 + BORDER_WIDTH_2;
			var myHeight:int = li.height + BORDER_WIDTH_4;
			var panel:Panel = new Panel( myWidth, myHeight );
			panel.addElement( li );
			panel.borderWidth = BORDER_WIDTH;
			parentPanel.addElement( panel );
			_calculatedWidth = Math.max( myWidth, _calculatedWidth );
			
			return li;
		}

		private function LocationGroup():void
		{
			var panel:Panel = new Panel( 300, 20 );
			panel.padding = 0;
			var label:Text = new Text( 300, 20 );
			label.text = "Location";
			label.textAlign = TextAlign.CENTER;
			label.fontSize = 16;
			label.fixToParentWidth = true;
			panel.addElement( label );
			
			addSpinLabel( panel, "X:"
						, function($e:SpinButtonEvent):void { _ii.positionSetComp( updateVal($e), _ii.positionGet.y, _ii.positionGet.z ); }
						, function($e:TextEvent):void       { _ii.positionSetComp( int( $e.target.text ), _ii.positionGet.y, _ii.positionGet.z ); }
						, _ii.positionGet.x.toFixed(0) );
			addSpinLabel( panel, "Y:"
						, function($e:SpinButtonEvent):void { _ii.positionSetComp( _ii.positionGet.x, updateVal($e), _ii.positionGet.z ); }
						, function($e:TextEvent):void       { _ii.positionSetComp( _ii.positionGet.x, int( $e.target.text ), _ii.positionGet.z ); }
						, _ii.positionGet.y.toFixed(0) );
			addSpinLabel( panel, "Z:"
						, function($e:SpinButtonEvent):void { _ii.positionSetComp( _ii.positionGet.x, _ii.positionGet.y, updateVal($e) ); }
						, function($e:TextEvent):void       { _ii.positionSetComp( _ii.positionGet.x, _ii.positionGet.y, int( $e.target.text ) ); }
						, _ii.positionGet.z.toFixed(0) );
						
			panel.layout.orientation = LayoutOrientation.VERTICAL;
			panel.width = _calculatedWidth;
			panel.height = label.height + PANEL_HEIGHT + BORDER_WIDTH_4;
			addElement( panel );
		}
		
		private function CenterGroup():void
		{
			var panel:Panel = new Panel( 300, 20 );
			panel.padding = 0;
			
			var label:Text = new Text( 300, 20 );
			label.text = "Center";
			label.textAlign = TextAlign.CENTER;
			label.fontSize = 16;
			label.fixToParentWidth = true;
			panel.addElement( label );
			
			addSpinLabel( panel, "X:"
						, function($e:SpinButtonEvent):void { _ii.centerSetComp( updateVal($e), _ii.center.y, _ii.center.z ); }
						, function($e:TextEvent):void       { _ii.centerSetComp( int( $e.target.text ), _ii.center.y, _ii.center.z ); }
						, _ii.center.x.toFixed(0) );
			addSpinLabel( panel, "Y:"
						, function($e:SpinButtonEvent):void { _ii.centerSetComp( _ii.center.x, updateVal($e), _ii.center.z ); }
						, function($e:TextEvent):void       { _ii.centerSetComp( _ii.center.x, int( $e.target.text ), _ii.center.z ); }
						, _ii.center.y.toFixed(0) );
			addSpinLabel( panel, "Z:"
						, function($e:SpinButtonEvent):void { _ii.centerSetComp( _ii.center.x, _ii.center.y, updateVal($e) ); }
						, function($e:TextEvent):void       { _ii.centerSetComp( _ii.center.x, _ii.center.y, int( $e.target.text ) ); }
						, _ii.center.z.toFixed(0) );
			
			panel.layout.orientation = LayoutOrientation.VERTICAL;
			panel.width = _calculatedWidth;
			panel.height = label.height + PANEL_HEIGHT + BORDER_WIDTH_4;
			panel.layout.autoSizeAnimated = true;
			addElement( panel );
		}

		private function RotationGroup():void
		{
			var label:Text = new Text( 300, 20 );
			label.text = "Rotation";
			label.textAlign = TextAlign.CENTER;
			label.fontSize = 16;
			label.fixToParentWidth = true;
			var panel:Panel = new Panel( 300, 20 );
			panel.padding = 0;
			panel.addElement( label );
			
			addSpinLabel( panel, "X:"
						, function($e:SpinButtonEvent):void { _ii.rotationSetComp( updateVal($e), _ii.rotationGet.y, _ii.rotationGet.z ); }
						, function($e:TextEvent):void       { _ii.rotationSetComp( int( $e.target.text ), _ii.rotationGet.y, _ii.rotationGet.z ); }
						, _ii.rotationGet.x.toFixed(0) );
			addSpinLabel( panel, "Y:"
						, function($e:SpinButtonEvent):void { _ii.rotationSetComp( _ii.rotationGet.x, updateVal($e), _ii.rotationGet.z ); }
						, function($e:TextEvent):void       { _ii.rotationSetComp( _ii.rotationGet.x, int( $e.target.text ), _ii.rotationGet.z ); }
						, _ii.rotationGet.y.toFixed(0) );
			addSpinLabel( panel, "Z:"
						, function($e:SpinButtonEvent):void { _ii.rotationSetComp( _ii.rotationGet.x, _ii.rotationGet.y, updateVal($e) ); }
						, function($e:TextEvent):void       { _ii.rotationSetComp( _ii.rotationGet.x, _ii.rotationGet.y, int( $e.target.text ) ); }
						, _ii.rotationGet.z.toFixed(0) );

			panel.layout.orientation = LayoutOrientation.VERTICAL;
			panel.width = _calculatedWidth;
			panel.height = label.height + PANEL_HEIGHT + BORDER_WIDTH_4;
			panel.layout.autoSizeAnimated = true;
			addElement( panel );
		}
		
		private function Advanced():void
		{
			var label:Text = new Text( 300, 20 );
			label.text = "Advanced";
			label.textAlign = TextAlign.CENTER;
			label.fontSize = 16;
			label.fixToParentWidth = true;
			//label.addEventListener(MouseEvent.CLICK, close );
			_panelAdvanced = new Panel( 300, 20 );
            _panelAdvanced.autoSize = true;
			_panelAdvanced.padding = 0;
			_panelAdvanced.layout.orientation = LayoutOrientation.VERTICAL;
           //_panelAdvanced.layout.autoSizeAnimated = true;
			_panelAdvanced.addElement( label );
			
			var parentModel:VoxelModel = _ii.controllingModel;
			var vm:VoxelModel;
			if ( parentModel )
				vm = parentModel.childModelFind( _ii.guid );
			else	
				vm = Globals.getModelInstance( _ii.guid );
				
							addLabel( _panelAdvanced, "State:", changeStateHandler, vm.anim ? vm.anim.name : "" );
							addLabel( _panelAdvanced, "Name:", changeNameHandler, _ii.name );
			//_GrainSize = 	addLabel( _panelAdvanced, "GrainSize:", null, _vm.oxel.gc.grain.toString() );
							addLabel( _panelAdvanced, "GrainSize:", null, String( _ii.grainSize ) );
			addLabel( _panelAdvanced, "Instance GUID:", null, _ii.guid );
			addLabel( _panelAdvanced, "Model GUID:", null, _ii.guid );
			addLabel( _panelAdvanced, "Parent:", null, _ii.controllingModel ? _ii.controllingModel.instanceInfo.guid : "" );
			//addLabel( _panelAdvanced, "Script:", null, _ii.scriptName );
			//_Texture = 		addLabel( _panelAdvanced, "Texture:", null, _ii.textureName );
			//_TextureScale =	addLabel( _panelAdvanced, "TextureScale:", null, _ii.textureScale.toString() );
			
			addElement( _panelAdvanced );
		}
		
		private function closeFunction():void
		{
			_s_inExistance--;
			_s_currentInstance = null;
			
			Globals.g_app.dispatchEvent( new ModelEvent( ModelEvent.MODEL_MODIFIED, _ii.guid ) );
			Globals.g_app.dispatchEvent( new RegionEvent( RegionEvent.REGION_MODIFIED, "" ) );
		}
		

		private function changeNameHandler(event:TextEvent):void { _ii.name = event.target.text; }
		
		private function changeStateHandler(event:TextEvent):void {
			var vm:VoxelModel = Globals.getModelInstance( _ii.guid )
			var state:String = event.target.text;
			vm.stateLock( false );
			vm.stateSet( state );
			vm.stateLock( true );
		}

		private function updateVal( $e:SpinButtonEvent ):int {
			var ival:int = int( $e.target.data.text );
			if ( "clickDown" == $e.type ) 	ival--;
			else 								ival++;
			$e.target.data.text = ival.toString();
			return ival;
		}

        private function close(e:MouseEvent):void { setHeight(0); }
        private function open():void { setHeight(20); }
  
        private function setHeight(height:Number):void {
			
			//_GrainSize.height = height;
			//_InstanceGUID.height = height;
			//_ModelGUID.height = height;
			//_Parent.height = height;
			//_Script.height = height;
			//_Texture.height = height;
			//_TextureScale.height = height;
			//_ModelClass.height = height;
			_panelAdvanced.height = 20;
            //_image.height = height;
            //_.label = height == 0 ? "Double click to open" : "Double click to close";
        }		
		*/
	}
}