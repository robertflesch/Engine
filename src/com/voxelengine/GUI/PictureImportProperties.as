/**
 * Created by dev on 5/23/2017.
 */
package com.voxelengine.GUI {
import com.voxelengine.worldmodel.TypeInfo;
import com.voxelengine.worldmodel.oxel.GrainCursor;

import flash.display.BitmapData;

import org.flashapi.swing.core.DeniedConstructorAccess;

public class PictureImportProperties {
    static public var pictureStyle:int = TypeInfo.CUSTOM_GLASS;
    static public var replaceBlackWithIron:Boolean = true;
    static public var blackColor:uint = 0x11;
    static public var hasTransparency:Boolean = false;
    static public var transColor:uint = 0xf0;
    static public var grain:uint = 5;
    static public var referenceBitmapData:BitmapData = null;
    static public var finalBitmapData:BitmapData = null;
    static public var url:String = "";

    public function PictureImportProperties() {
        new DeniedConstructorAccess(this);
    }

    static public function reset():void {
        pictureStyle = TypeInfo.CUSTOM_GLASS;
        replaceBlackWithIron = true;
        blackColor = 0x11;
        transColor = 0xf0;
        grain = 5;
        referenceBitmapData = null;
        finalBitmapData = null;
        url = "";
        hasTransparency = false;
    }

    static public function traceProperties():void {
        trace( "======== PictureProperties =============");
        trace( "pictureStyle = " + pictureStyle );
        trace( "hasTransparency = " + hasTransparency );
        trace( "replaceBlackWithIron = " + replaceBlackWithIron );
        trace( "blackColor = " + blackColor.toString(16) );
        trace( "transColor = " + transColor.toString(16) );
        trace( "grain = " + grain );
        trace( "referenceBitmapData w: " + referenceBitmapData.width + " h: " + referenceBitmapData.height);
        trace( "finalBitmapData w: " + finalBitmapData.width + " h: " + finalBitmapData.height);
        trace( "url = " + url );
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
