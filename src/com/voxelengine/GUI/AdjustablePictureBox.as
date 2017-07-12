/**
 * Created by dev on 5/22/2017.
 */
package com.voxelengine.GUI {
import flash.filters.ColorMatrixFilter;
import flash.geom.Point;
import flash.display.BitmapData;

import org.flashapi.swing.Box;

import org.flashapi.swing.Container;
import org.flashapi.swing.Label;
import org.flashapi.swing.Slider;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.constants.LayoutOrientation;
import org.flashapi.swing.constants.ScrollableOrientation;
import org.flashapi.swing.constants.TextAlign;
import org.flashapi.swing.event.ScrollEvent;
import fl.motion.AdjustColor;

import org.flashapi.swing.layout.AbsoluteLayout;


public class AdjustablePictureBox extends VVBox {
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
        layout = new AbsoluteLayout();
    }

    public function addPicture( $bmd:BitmapData ):void {
        removeUI();
        PictureImportProperties.referenceBitmapData = $bmd.clone();
        PictureImportProperties.finalBitmapData = $bmd.clone();
        _color.brightness = 0;
        _color.contrast = 0;
        _color.hue = 0;
        _color.saturation = 0;
        backgroundTexture = VVBox.drawScaled( $bmd, width, height, PictureImportProperties.hasTransparency );
        addUI();
    }
    private function removeUI():void {
        removeElements();
        _brightnessLabel = null;
        _brightnessHSlider = null;
        _contrastLabel = null;
        _contrastHSlider = null;
        _hueLabel = null;
        _hueHSlider = null;
        _saturationLabel = null;
        _saturationHSlider = null;
    }

    private function addUI():void {
        var container:Box = new Box(width/2, height/2);
        container.y = height / 2;
        container.x = width / 2;
        container.backgroundColor = 0x444444 ;
        container.backgroundAlpha = 0.5;
        container.padding = 0;
        container.layout = new AbsoluteLayout();
        var posY:int = 0;

        var val:Object = addSlider( posY, container, "Brightness: 0", -100, 100 );
        _brightnessLabel = val.label;
        _brightnessHSlider = val.slider;
        posY += height/8;

        val = addSlider( posY, container, "Contrast: 0", -100, 100 );
        _contrastLabel = val.label;
        _contrastHSlider = val.slider;
        posY += height/8;

        val = addSlider( posY, container, "Hue: 0", -180, 180 );
        _hueLabel = val.label;
        _hueHSlider = val.slider;
        posY += height/8;

        val = addSlider( posY, container, "Saturation: 0", -100, 100 );
        _saturationLabel = val.label;
        _saturationHSlider = val.slider;

        addElement( container );
    }

    private function addSlider( $posY:int, $container:Box, $text:String, $min:int, $max:int ):Object {
        var itemWidth:int = $container.width - 8;
        var bContainer:Container = new Container( itemWidth, 40);
        bContainer.y = $posY;
        bContainer.layout = new AbsoluteLayout();
        $container.addElement( bContainer );
        var label:Label = new Label( $text, itemWidth );
        label.x = 4;
        label.y = 0;
        label.textFormat.color = 0xffffff;
        label.textFormat.size = 12;
        label.textAlign = TextAlign.CENTER;
        bContainer.addElement( label );
        var slider:Slider = new Slider(itemWidth, ScrollableOrientation.HORIZONTAL );
        slider.showTicks = false;
        $evtColl.addEvent( slider, ScrollEvent.SCROLL, onBrightness );
        slider.x = 4;
        slider.y = 8;
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

        if ( PictureImportProperties.referenceBitmapData ) {
            PictureImportProperties.finalBitmapData = PictureImportProperties.referenceBitmapData.clone();
            _filter = new ColorMatrixFilter( _color.CalculateFinalFlatArray() );
            PictureImportProperties.finalBitmapData.applyFilter( PictureImportProperties.finalBitmapData
                                                               , PictureImportProperties.finalBitmapData.rect
                                                               , new Point()
                                                               , _filter.clone());
            backgroundTexture = VVBox.drawScaled( PictureImportProperties.finalBitmapData, width, height, PictureImportProperties.hasTransparency );
        }
    }
}
}