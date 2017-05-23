/**
 * Created by dev on 5/23/2017.
 */
package com.voxelengine.GUI {
import com.voxelengine.worldmodel.TypeInfo;

import flash.display.BitmapData;

public class PictureImportProperties {
    static public var pictureStyle:int = TypeInfo.GLASS;
    static public var removeTransPixels:Boolean = true;
    static public var transColor:uint = 0x000000;
    static public var oxelSize:uint = 4;
    static public var finalBitmapData:BitmapData = null;

    public function PictureImportProperties() {
    }
}
}
