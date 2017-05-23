/**
 * Created by dev on 5/22/2017.
 */
package com.voxelengine.GUI {
import flash.filters.ColorMatrixFilter;
import flash.geom.Point;
import flash.display.Bitmap;
import flash.display.BitmapData;

import org.flashapi.swing.Container;
import org.flashapi.swing.Label;
import org.flashapi.swing.Slider;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.constants.LayoutOrientation;
import org.flashapi.swing.constants.ScrollableOrientation;
import org.flashapi.swing.constants.TextAlign;
import org.flashapi.swing.event.ScrollEvent;
import fl.motion.AdjustColor;
import fl.motion.ColorMatrix;

import org.flashapi.swing.text.UITextFormat;


public class AdjustablePictureBox extends VVBox {
    private var _bitmap:Bitmap;
    private var _referenceBitmapData:BitmapData;
    private var _workingBitmapData:BitmapData;
    private var _brightnessHSlider:Slider;
    private var _contrastHSlider:Slider;
    private var _hueHSlider:Slider;
    private var _saturationHSlider:Slider;
    private var _brightnessLabel:Label;
    private var _contrastLabel:Label;
    private var _hueLabel:Label;
    private var _saturationLabel:Label;
    private var _color:AdjustColor = new AdjustColor();
    private var _filter:ColorMatrixFilter;
    public function AdjustablePictureBox($widthParam:Number, $heightParam:Number, $borderStyle:String = BorderStyle.GROOVE) {
        super($widthParam, $heightParam, $borderStyle);
        addUI();
        layout.orientation = LayoutOrientation.VERTICAL;

//        onBrightness(null);
    }

    public function addPicture( $bmd:BitmapData ):void {
        _referenceBitmapData = $bmd.clone();
        _workingBitmapData = $bmd.clone();
        _color.brightness = 0;
        _color.contrast = 0;
        _color.hue = 0;
        _color.saturation = 0;
        backgroundTexture = VVBox.drawScaled( $bmd,width, height);
    }

    private function addUI():void {
        var val:Object = addSlider( "Brightness: 0", -100, 100 );
        _brightnessLabel = val.label;
        _brightnessHSlider = val.slider;

        val = addSlider( "Contrast: 0", -100, 100 );
        _contrastLabel = val.label;
        _contrastHSlider = val.slider;

        val = addSlider( "Hue: 0", -180, 180 );
        _hueLabel = val.label;
        _hueHSlider = val.slider;

        val = addSlider( "Saturation: 0", -100, 100 );
        _saturationLabel = val.label;
        _saturationHSlider = val.slider;
    }

    private function addSlider( $text:String, $min:int, $max:int ):Object {
        var bContainer:Container = new Container(width, 40);
        bContainer.layout.orientation = LayoutOrientation.VERTICAL;
        var label:Label = new Label( $text, width );
        label.textFormat.color = 0xffffff;
        label.textFormat.size = 18;
        label.textAlign = TextAlign.CENTER;
        bContainer.addElement( label );
        var slider:Slider = new Slider(width-20, ScrollableOrientation.HORIZONTAL );
        $evtColl.addEvent( slider, ScrollEvent.SCROLL, onBrightness );
        slider.maximum = $max;
        slider.minimum = $min;
        slider.value = 0;
        bContainer.addElement( slider );
        addElement(bContainer);
        return { label:label, slider:slider };
    }

    private function onBrightness( $se:ScrollEvent):void {
        _color.brightness = _brightnessHSlider.value;
        _color.contrast = _contrastHSlider.value;
        _color.hue = _hueHSlider.value;
        _color.saturation = _saturationHSlider.value;
        _brightnessLabel.text = "Brightness: " + _brightnessHSlider.value;
        _contrastLabel.text = "Contrast: " + _contrastHSlider.value;
        _hueLabel.text = "Hue: " + _hueHSlider.value;
        _saturationLabel.text = "Saturation: " + _saturationHSlider.value;

        if ( _workingBitmapData ) {
            _filter = new ColorMatrixFilter( _color.CalculateFinalFlatArray() );
            _workingBitmapData.applyFilter(_referenceBitmapData, _referenceBitmapData.rect, new Point(), _filter.clone());
            backgroundTexture = VVBox.drawScaled( _workingBitmapData, width, height);
        }
    }
}
}