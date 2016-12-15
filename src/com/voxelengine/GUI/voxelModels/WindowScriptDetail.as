/**
 * Created by dev on 12/14/2016.
 */
package com.voxelengine.GUI.voxelModels {
import com.voxelengine.events.ModelInfoEvent;
import com.voxelengine.renderer.Renderer;
import com.voxelengine.worldmodel.Light;
import com.voxelengine.worldmodel.oxel.LightInfo;
import com.voxelengine.worldmodel.scripts.Script;

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
import com.voxelengine.events.ModelBaseEvent;
import com.voxelengine.events.ModelMetadataEvent;
import com.voxelengine.GUI.panels.*;
import com.voxelengine.GUI.*;
import com.voxelengine.GUI.components.*;
import com.voxelengine.worldmodel.Region;
import com.voxelengine.worldmodel.RegionManager;
import com.voxelengine.worldmodel.models.InstanceInfo;
import com.voxelengine.worldmodel.models.types.VoxelModel;
import com.voxelengine.worldmodel.oxel.Oxel;

public class WindowScriptDetail extends VVPopup
{
    static private const WIDTH:int = 330;
    public function WindowScriptDetail( $script:Script )
    {
        super( "Script Details" );
        autoSize = false;
        autoHeight = true;
        width = WIDTH + 10;
        height = 600;
        padding = 0;
        paddingLeft = 5;

        layout.orientation = LayoutOrientation.VERTICAL;

        addElement( new ComponentSpacer( WIDTH ) );
        addElement( new ComponentTextInput( "Parameters: "
                , function ($e:TextEvent):void { $script.fromString( $e.target.text ); }
                , $script.toString()
                , WIDTH ) );

        display( 600, 20 );
    }
}
}
