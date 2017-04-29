////////////////////////////////////////////////////////////////////////////////
//    
//    Swing Package for Actionscript 3.0 (SPAS 3.0)
//    Copyright (C) 2004-2011 BANANA TREE DESIGN & Pascal ECHEMANN.
//    
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//    
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//    GNU General Public License for more details.
//    
//    You should have received a copy of the GNU General Public License
//    along with this program. If not, see <http://www.gnu.org/licenses/>.
//    
////////////////////////////////////////////////////////////////////////////////

package org.flashapi.swing.plaf.spas {

// -----------------------------------------------------------
// VVUI.as
// -----------------------------------------------------------

/**
 * @author Pascal ECHEMANN
 * @version 2.0.0, 09/11/2010 09:31
 * @see http://www.flashapi.org/
 */

import flash.display.Sprite;
import flash.filters.DropShadowFilter;
import flash.filters.GlowFilter;
import flash.text.TextFormat;
import org.flashapi.swing.constants.WebFonts;
import org.flashapi.swing.plaf.core.LafDTO;
import org.flashapi.swing.plaf.LookAndFeel;

/**
 * 	The <code>VVUI</code> class is the base class for the VoxelVerse 1.0 default
 * 	pluggable look and feel.
 *
 * 	@see org.flashapi.swing.plaf.LookAndFeel
 *
 * 	@langversion ActionScript 3.0
 * 	@playerversion Flash Player 9
 * 	@productversion SPAS 3.0 alpha
 */
public class VVUI implements LookAndFeel {

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * 	Constructor.  A Look and Feel object must not be directly instantiated.
     *
     * 	@param	dto		A reference to the <code>LafDTO</code> object that
     * 					instantiates this look and feel.
     */
    public function VVUI(dto:LafDTO, format:TextFormat = null):void {
        super();
        initObj(dto, format);
    }

    //--------------------------------------------------------------------------
    //
    //  Public methods
    //
    //--------------------------------------------------------------------------

    /**
     *  A constant integer that defines the default color value for the SPAS 3.0
     * 	default look and feel. This color correpsonds to the <code>"silver"</code>
     * 	color defined by the default SPAS 3.0 color module (SVGCK).
     */
            // http://www.google.com/design/spec/style/color.html
    //public static const DEFAULT_COLOR:uint = 0xC0C0C0;
    //public static const DEFAULT_COLOR:uint = 0xE1F5FE;
    public static const DEFAULT_COLOR:uint = 0xbed8f1;
//    public static const DEFAULT_BUTTON_COLOR:uint = 0x0277BD;
    public static const DEFAULT_BUTTON_COLOR:uint = 0x83a6cc;
    public static const DEFAULT_CLOSE_BUTTON_COLOR:uint = 0xF44336;

    /**
     *  A constant integer that defines the default background color value.
     */
    public static const DEFAULT_BACKGROUND_COLOR:uint = 0xFFFFFF;

    /**
     *  A constant integer that defines the default dark color value.
     */
    public static const DEFAULT_DARK_COLOR:uint = 0x333333;

    /**
     *  A constant integer that defines the default color value.
     */
    public static const DEFAULT_FONT_COLOR:uint = 0x333333;

    /**
     *  A constant integer that defines the default size value.
     */
            //public static const DEFAULT_FONT_SIZE:uint = 12;
    public static const DEFAULT_FONT_SIZE:uint = 11;
    public static const LABEL_FONT_COLOR:uint = 0x8c8c8c;

    /**
     *  A constant string that defines the default font face value.
     */
    public static const DEFAULT_FONT_FACE:String = WebFonts.ARIAL; // ORIGINAL
    //public static const DEFAULT_FONT_FACE:String = WebFonts.VERDANA; // too wide
    //public static const DEFAULT_FONT_FACE:String = WebFonts.TREBUCHET_MS;


    /**
     *  A constant string that defines the default font color value for button
     * 	objects.
     */
            //public static const DEFAULT_BUTTON_FONT_COLOR:uint = 0xFFFFFF;
    public static const DEFAULT_BUTTON_FONT_COLOR:uint = 0x000000;

    public static const DISABLED_BUTTON_FONT_COLOR:uint = 0xBDB9aa;
    public static const UP_BUTTON_FONT_COLOR:uint = 0x8A8677;

    /**
     *  A constant string that defines the default color color value.
     */
    public static const DEFAULT_BORDER_COLOR:uint = 0x777777;

    /**
     *  A constant string that defines the default font letter spacing value.
     */
    public static const DEFAULT_LETTER_SPACING:Number = .2;

    //--------------------------------------------------------------------------
    //
    //  Public methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @inheritDoc
     */
    public function addRaiseEffect():void {
        var s:Sprite = dto.container;
        s.scaleX = s.scaleY = 1.02;
        s.x -= 3;
        s.y -= 3;
        s.filters = [_raiseEffect];
    }

    /**
     *  @inheritDoc
     */
    public function clearEmphasizedState():void {
        dto.container.filters = [];
    }

    /**
     *  @inheritDoc
     */
    public function drawBackFace():void { }

    /**
     *  @inheritDoc
     */
    public function drawEmphasizedState():void {
        if (!isNaN(dto.focusColor)) _focusGlowFilter.color = dto.focusColor;
        var f:Array = [_focusGlowFilter];
        dto.container.filters = f;
    }

    /**
     *  @inheritDoc
     */
    public function getGlowFilter():GlowFilter {
        return _glowFilter;
    }

    /**
     *  @inheritDoc
     */
    public function getFocusFilter():GlowFilter {
        return _focusGlowFilter;
    }

    /**
     *  @inheritDoc
     */
    public function getShadowFilter():DropShadowFilter {
        return _dropShadowFilter;
    }

    /**
     *  @inheritDoc
     */
    public function onChange():void { }

    /**
     *  @inheritDoc
     */
    public function removeRaiseEffect():void {
        var s:Sprite = dto.container;
        s.scaleX = s.scaleY = 1;
        s.x += 3;
        s.y += 3;
        s.filters = [];
    }

    //--------------------------------------------------------------------------
    //
    //  Protected properties
    //
    //--------------------------------------------------------------------------

    /**
     * 	@private
     */
    protected var dto:LafDTO;

    //--------------------------------------------------------------------------
    //
    //  Protected methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    protected function fixLetterSpacing(fmt:TextFormat):void {
        fmt.letterSpacing = DEFAULT_LETTER_SPACING;
    }

    //--------------------------------------------------------------------------
    //
    //  Private properties
    //
    //--------------------------------------------------------------------------

    private var _dropShadowFilter:DropShadowFilter = new DropShadowFilter(1.5, 90, 0, .5);
    private var _glowFilter:GlowFilter =  new GlowFilter (0xCC99FF, .5, 10, 10);
    private var _focusGlowFilter:GlowFilter = new GlowFilter(0xCC99FF, .6, 7, 7, 5);
    private var _raiseEffect:DropShadowFilter = new DropShadowFilter(4, 90, 0xCC99FF, 1, 15, 15);

    //--------------------------------------------------------------------------
    //
    //  Private methods
    //
    //--------------------------------------------------------------------------

    private function initObj(dto:LafDTO, format:TextFormat):void {
        this.dto = dto;
        if (format) fixLetterSpacing(format);
    }
}
}