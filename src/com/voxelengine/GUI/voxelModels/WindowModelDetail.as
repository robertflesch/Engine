
package com.voxelengine.GUI.voxelModels
{
	import com.voxelengine.events.ModelBaseEvent;
	import com.voxelengine.events.ModelMetadataEvent;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.geom.Matrix;
	
	import org.flashapi.collector.EventCollector;
	import org.flashapi.swing.*;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.ModelEvent;
	import com.voxelengine.events.RegionEvent;
	import com.voxelengine.GUI.*;
	import com.voxelengine.GUI.components.*;
	import com.voxelengine.worldmodel.Region;
	import com.voxelengine.worldmodel.RegionManager;
	import com.voxelengine.worldmodel.models.InstanceInfo;
	import com.voxelengine.worldmodel.models.types.VoxelModel;

	
	public class WindowModelDetail extends VVPopup
	{
		static private var _s_inExistance:int = 0;
		static private var _s_currentInstance:WindowModelDetail = null;
		
		private var _eventCollector:EventCollector = new EventCollector();
		private var _panelAdvanced:Panel;
		private var _pic:Image;
		private var _photoContainer:Container
		private var _vm:VoxelModel = null;
		
		private static const BORDER_WIDTH:int = 4;
		private static const BORDER_WIDTH_2:int = BORDER_WIDTH * 2;
		private static const BORDER_WIDTH_3:int = BORDER_WIDTH * 3;
		private static const BORDER_WIDTH_4:int = BORDER_WIDTH * 4;
		private static const PANEL_HEIGHT:int = 115;
		
		private var _calculatedWidth:int = 300;
		private var _calculatedHeight:int = 20;

		static public function get inExistance():int { return _s_inExistance; }
		static public function get currentInstance():WindowModelDetail { return _s_currentInstance; }
		
		public function WindowModelDetail( $vm:VoxelModel )
		{
			super( "Model Details" );
			width = 300;
			padding = 0;

			_s_inExistance++;
			_s_currentInstance = this;
			
			_vm = $vm;
			var ii:InstanceInfo = _vm.instanceInfo; // short cut for brevity
			
			onCloseFunction = closeFunction;
			defaultCloseOperation = ClosableProperties.CALL_CLOSE_FUNCTION;
			layout.orientation = LayoutOrientation.VERTICAL;
            autoSize = true;
			shadow = true;
			
			addElement( new ComponentSpacer( width ) );
			addElement( new ComponentTextInput( "Name"
			                                  , function ($e:TextEvent):void { _vm.metadata.name = $e.target.text; setChanged(); }
											  , _vm.metadata.name ? _vm.metadata.name : "No Name"
											  , width ) );
			addElement( new ComponentTextArea( "Desc"
											 , function ($e:TextEvent):void { _vm.metadata.description = $e.target.text; setChanged(); }
											 , _vm.metadata.description ? _vm.metadata.description : "No Description"
											 , width ) );

			// TODO need to be able to handle an array of scipts.
			//addElement( new ComponentTextInput( "Script",  function ($e:TextEvent):void { ii.scriptName = $e.target.text; }, ii.scriptName, width ) );
			const GRAINS_PER_METER:int = 16;
			addElement( new ComponentLabel( "Size in Meters", String( $vm.modelInfo.data.oxel.gc.size()/GRAINS_PER_METER ), width ) );
			if ( Globals.g_debug ) {
				addElement( new ComponentLabel( "Model GUID",  ii.modelGuid, width ) );
				addElement( new ComponentLabel( "Instance GUID",  ii.instanceGuid, width ) );
			}
			if ( _vm.anim )
				// TODO add a drop down of available states
				addElement( new ComponentLabel( "State", _vm.anim ? _vm.anim.name : "", width ) );
				
			if ( ii.controllingModel )
				addElement( new ComponentLabel( "Parent GUID",  ii.controllingModel ? ii.controllingModel.instanceInfo.instanceGuid : "", width ) );
//
			addElement( new ComponentVector3D( setChanged, "Position", "X: ", "Y: ", "Z: ",  ii.positionGet, updateVal ) );
			addElement( new ComponentVector3D( setChanged, "Rotation", "X: ", "Y: ", "Z: ",  ii.rotationGet, updateVal ) );
			addElement( new ComponentVector3D( setChanged, "Center", "X: ", "Y: ", "Z: ",  ii.center, updateVal ) );
			addElement( new ComponentVector3D( setChanged, "Scale", "X: ", "Y: ", "Z: ",  ii.scale, updateScaleVal, 5 ) );
			addPhoto()
			
			if ( Globals.g_debug )
			{
				var oxelUtils:Button = new Button( LanguageManager.localizedStringGet( "Oxel_Utils" ) );
				oxelUtils.addEventListener(UIMouseEvent.CLICK, oxelUtilsHandler );
				//oxelUtils.width = pbWidth - 2 * pbPadding;
				addElement( oxelUtils );
			}
			
			display( 600, 20 );
        }
		
		private function newPhoto( $me:UIMouseEvent ):void {
			var bmpd:BitmapData = Globals.g_renderer.modelShot();
			_vm.metadata.thumbnail = drawScaled( bmpd, 128, 128 );
			ModelMetadataEvent.dispatch( new ModelMetadataEvent( ModelBaseEvent.CHANGED, 0, _vm.metadata.guid, null ) );
			updatePhoto();
			
			function drawScaled(obj:BitmapData, destWidth:int, destHeight:int ):BitmapData {
				var m:Matrix = new Matrix();
				m.scale(destWidth/obj.width, destHeight/obj.height);
				var bmpd:BitmapData = new BitmapData(destWidth, destHeight, false);
				bmpd.draw(obj, m);
				return bmpd;
			}	
		}
		
		private function addPhoto():void {
			_photoContainer = new Container( width, 128 );
			_photoContainer.name = "pc";
			addElement(_photoContainer);
			
			var btn:Button = new Button( "Take New Picture", width - 128 , 128 );
			$evtColl.addEvent( btn, UIMouseEvent.CLICK, newPhoto );
			_photoContainer.addElement(btn);
			
			_pic = new Image( new Bitmap( _vm.metadata.thumbnail ), 128, 128 );
			_photoContainer.addElement( _pic );
			setChanged();
		}
		
		private function updatePhoto():void {
			_photoContainer.removeElementAt( 1 );
			_pic = new Image( new Bitmap( _vm.metadata.thumbnail ), 128, 128 );
			_photoContainer.addElementAt( _pic, 1 );
		}

		private function updateScaleVal( $e:SpinButtonEvent ):Number {
			var ival:Number = Number( $e.target.data.text );
			if ( SpinButtonEvent.CLICK_DOWN == $e.type ) 	ival = ival/2;
			else 											ival = ival*2;
			$e.target.data.text = ival.toString();
			setChanged();
			return ival;
		}
		
		private function updateVal( $e:SpinButtonEvent ):int {
			var ival:int = int( $e.target.data.text );
			if ( SpinButtonEvent.CLICK_DOWN == $e.type ) 	ival--;
			else 											ival++;
			setChanged();
			$e.target.data.text = ival.toString();
			return ival;
		}
		
		private function setChanged():void {
			_vm.changed = true;
			_vm.instanceInfo.changed = true;
			if ( _vm.instanceInfo.controllingModel )
				_vm.instanceInfo.controllingModel.changed = true;
		}
		
		private function oxelUtilsHandler(event:UIMouseEvent):void  {

			if ( _vm )
				new WindowOxelUtils( _vm );
		}
		
		private function closeFunction():void
		{
			_s_inExistance--;
			_s_currentInstance = null;
			
			ModelEvent.dispatch( new ModelEvent( ModelEvent.MODEL_MODIFIED, _vm.instanceInfo.instanceGuid ) );
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.CHANGED, 0, null ) );
			RegionEvent.dispatch( new RegionEvent( ModelBaseEvent.SAVE, 0, Region.currentRegion.guid ) );
		}
		

		private function changeStateHandler(event:TextEvent):void {
			var vm:VoxelModel = Region.currentRegion.modelCache.instanceGet( _vm.instanceInfo.instanceGuid )
			var state:String = event.target.text;
			vm.stateLock( false );
			vm.stateSet( state );
			vm.stateLock( true );
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
		
	}
}