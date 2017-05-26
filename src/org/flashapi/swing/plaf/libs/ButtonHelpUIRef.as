/**
 * Created by dev on 5/25/2017.
 */
package org.flashapi.swing.plaf.libs {

// -----------------------------------------------------------
// ButtonHelpUIRef.as
// -----------------------------------------------------------

/**
 * @author Pascal ECHEMANN
 * @version 1.0.0, 14/03/2010 18:29
 * @see http://www.flashapi.org/
 */

import org.flashapi.swing.plaf.spas.SpasButtonCloseUI;
import org.flashapi.swing.plaf.spas.SpasButtonHelpUI;
import org.flashapi.swing.util.Observable;

/**
 * 	<strong>FOR DEVELOPERS ONLY.</strong>
 *
 * 	The <code>ButtonHelpUIRef</code> is the Library Reference for
 * 	Look And Feel of <code>Button</code> objects.
 *
 * 	@see org.flashapi.swing.Button
 *
 * 	@langversion ActionScript 3.0
 * 	@playerversion Flash Player 9
 * 	@productversion SPAS 3.0 alpha
 */
public class ButtonHelpUIRef implements LafLibRef {

    /**
     * 	<strong>FOR DEVELOPERS ONLY.</strong>
     *
     * 	Returns the default Look And Feel reference for the <code>ButtonHelpUIRef</code>
     * 	Library.
     *
     * 	@return	The default Look And Feel reference for this <code>LafLibRef</code>
     * 			object.
     */
    public static function getDefaultUI():Class {
        return SpasButtonHelpUI;
    }

    //--------------------------------------------------------------------------
    //
    //  Public static properties
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    public static var lafList:Observable;

    /**
     *  @private
     */
    public static var laf:Object;
}
}