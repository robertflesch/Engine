/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/

package com.voxelengine.GUI.voxelModels {

import org.flashapi.swing.Button;
import org.flashapi.swing.event.*;
import org.flashapi.swing.constants.*;

import com.voxelengine.Log;
import com.voxelengine.Globals;
import com.voxelengine.GUI.*;
import com.voxelengine.GUI.components.*;
import com.voxelengine.worldmodel.scripts.Script;


public class WindowScriptDetail extends VVPopup
{
    static private const WIDTH:int = 330;
    private var _text:ComponentTextInput;
    private var _script:Script;
    public function WindowScriptDetail( $script:Script )
    {
        super( "Script Details" );
        _script = $script;
        autoSize = false;
        autoHeight = true;
        width = WIDTH + 10;
        height = 600;
        padding = 0;
        paddingLeft = 5;

        layout.orientation = LayoutOrientation.VERTICAL;

        addElement( new ComponentSpacer( WIDTH ) );
        _text = new ComponentTextInput( "Parameters: "
                , function ($e:TextEvent):void {  }
                , $script.paramsString()
                , WIDTH );
        addElement( _text );

        var ok:Button = new Button( "Save", 200, 30 );
        ok.addEventListener( UIMouseEvent.PRESS, saveHandler );
        addElement( ok );

        display( 600, 20 );
    }

    private function saveHandler( e:UIMouseEvent ):void {
        _script.fromString( _text.text() );
        remove();
    }
}
}
