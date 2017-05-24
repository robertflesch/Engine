/**
 * Created by dev on 5/23/2017.
 */
package com.voxelengine.GUI {
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.GrainCursor;

import flash.display.BitmapData;

public class PictureImportProperties {
    static public var pictureStyle:int = TypeInfo.CUSTOM_GLASS;
    static public var removeTransPixels:Boolean = true;
    static public var transColor:uint = 0xffffffff;
    static public var grain:uint = 5;
    static public var referenceBitmapData:BitmapData = null;
    static public var finalBitmapData:BitmapData = null;
    static public var url:String = "";
    static public var hasTransparency:Boolean = false;

    public function PictureImportProperties() {
    }

    static public function reset():void {
        pictureStyle = TypeInfo.CUSTOM_GLASS;
        removeTransPixels = true;
        transColor = 0xffffffff;
        grain = 5;
        referenceBitmapData = null;
        finalBitmapData = null;
        url = "";
        hasTransparency = false;
    }

    static public function traceProperties():void {
        trace( "======== PictureProperties =============");
        trace( "pictureStyle = " + pictureStyle );
        trace( "removeTransPixels = " + removeTransPixels );
        trace( "transColor = " + transColor.toString(16) );
        trace( "grain = " + grain );
        trace( "referenceBitmapData w: " + referenceBitmapData.width + " h: " + referenceBitmapData.height);
        trace( "finalBitmapData w: " + finalBitmapData.width + " h: " + finalBitmapData.height);
        trace( "url = " + url );
        trace( "hasTransparency = " + hasTransparency );
    }

    static public function traceBitmapData( $bmd:BitmapData, $pixelsToTrace:int = 64 ):void {
        trace( "referenceBitmapData" );
        var pixelsTraced:int = 0;
        var grains:uint = GrainCursor.get_the_g0_size_for_grain( PictureImportProperties.grain );
        for ( var iw:int = 0; iw < $bmd.width; iw++ ){
            for ( var ih:int = 0; ih < $bmd.height; ih++ ) {
                var pixelColor:uint = $bmd.getPixel32(iw, ih);
                trace(iw + " - " + ih + " " + pixelColor.toString(16));
                pixelsTraced++;
                if ( $pixelsToTrace <= pixelsTraced )
                    return;
            }
        }

    }
}
}
