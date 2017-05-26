/**
 * Created by dev on 5/24/2017.
 */
package org.flashapi.swing.wtk {

// -----------------------------------------------------------
// WindowButtonHelp.as
// -----------------------------------------------------------

import org.flashapi.swing.constants.HorizontalAlignment;
import org.flashapi.swing.constants.LabelPlacement;
import org.flashapi.swing.constants.VerticalAlignment;
import org.flashapi.swing.plaf.libs.ButtonHelpUIRef;
import org.flashapi.swing.util.Observer;

/**
 * 	The <code>WindowButtonClose</code> class allows to create buttons that are used
 * 	within windows title bars, to control <code>WTK</code> objects.
 *
 * 	@see org.flashapi.swing.wtk.WTK
 *
 * 	@langversion ActionScript 3.0
 * 	@playerversion Flash Player 9
 * 	@productversion SPAS 3.0 alpha
 */
public class WindowButtonHelp extends WindowButton implements Observer, WTKButton {

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor. Creates a new <code>WindowButtonClose</code> instance.
     */
    public function WindowButtonHelp() {
        super("", 20, 20);
        initObj();
    }

    override public function getUIRef():Class {
        return ButtonHelpUIRef;
    }

    //--------------------------------------------------------------------------
    //
    //  Private methods
    //
    //--------------------------------------------------------------------------

    private function initObj():void {
        $padL = $padR = 0;
        $vAlign = VerticalAlignment.MIDDLE;
        $hAlign = HorizontalAlignment.CENTER;
        $labelPlacement = LabelPlacement.RIGHT;
    }
}
}