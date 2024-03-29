/*==============================================================================
 Copyright 2011-2017 Robert Flesch
 All rights reserved.  This product contains computer programs, screen
 displays and printed documentation which are original works of
 authorship protected under United States Copyright Act.
 Unauthorized reproduction, translation, or display is prohibited.
 ==============================================================================*/
package org.flashapi.swing.plaf.spas {

// -----------------------------------------------------------
// VVButtonUI.as
// -----------------------------------------------------------

/**
 * @author Pascal ECHEMANN
 * @version 1.0.3, 20/05/2009 02:08
 * @see http://www.flashapi.org/
 */

import flash.display.GradientType;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Transform;
import org.flashapi.swing.color.RGB;
import org.flashapi.swing.constants.ButtonState;
import org.flashapi.swing.constants.StateObjectValue;
import org.flashapi.swing.constants.TextureType;
import org.flashapi.swing.draw.Figure;
import org.flashapi.swing.draw.MatrixUtil;
import org.flashapi.swing.managers.TextureManager;
import org.flashapi.swing.plaf.ButtonUI;
import org.flashapi.swing.plaf.core.LafDTO;
import org.flashapi.swing.plaf.core.LafDTOCornerUtil;
import org.flashapi.swing.text.FontFormat;

/**
 * 	The <code>VVButtonUI</code> class is the SPAS 3.0 default look and feel
 * 	for <code>Button</code> instances.
 *
 * 	@see org.flashapi.swing.Button
 * 	@see org.flashapi.swing.plaf.ButtonUI
 *
 * 	@langversion ActionScript 3.0
 * 	@playerversion Flash Player 9
 * 	@productversion SPAS 3.0 alpha
 */
public class VVButtonUI extends SpasIconColorsUI implements ButtonUI {

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     * 	@copy org.flashapi.swing.plaf.spas.SpasBoxHelpUI#SpasBoxHelpUI()
     */
    public function VVButtonUI(dto:LafDTO) {
        super(dto);
        _fontFormat.letterSpacing = DEFAULT_LETTER_SPACING;
    }

    //--------------------------------------------------------------------------
    //
    //  Public methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @inheritDoc
     *  @copy http://www.google.com/design/spec/components/buttons.html#buttons-flat-raised-buttons
     */
    public function drawOutState():void {
        var bntColor:uint = (dto.colors.up != StateObjectValue.NONE) ? dto.colors.up : dto.color;
        //var bntColor:uint = 0xe0e0e0;
        //var bntColor:uint = VVUI.DEFAULT_COLOR;
        var lineColor1:uint = 0x888888;//0x969696
        var lineColor2:int = 0x505050;//0x505050
        if (dto.borderColors.up != StateObjectValue.NONE){
            lineColor1 = dto.borderColors.up;
            lineColor2 = -1;
        }
        drawButtonShape(ButtonState.UP, bntColor, lineColor1, lineColor2);
    }

    /**
     *  @inheritDoc
     *  AKA Hover
     */
    public function drawOverState():void {
        var bntColor:uint = (dto.colors.over != StateObjectValue.NONE) ? dto.colors.over : dto.color;
        //var bntColor:uint = 0xe0e0e0;
        var lineColor:uint = (dto.borderColors.over != StateObjectValue.NONE) ? dto.borderColors.over : 0xFFFFFF;
        drawButtonShape(ButtonState.OVER, bntColor, lineColor);
    }

    /**
     *  @inheritDoc
     */
    public function drawPressedState():void {
        var bntColor:uint = (dto.colors.down != StateObjectValue.NONE) ? dto.colors.down : new RGB(dto.color).darker();
        //var bntColor:uint = 0xd6d6d6;
        var lineColor:uint = (dto.borderColors.down != StateObjectValue.NONE) ? dto.borderColors.down : 0x505050;
        drawButtonShape(ButtonState.DOWN, bntColor, lineColor);
    }

    /**
     *  @inheritDoc
     */
    public function drawSelectedState():void {
        var bntColor:uint = (dto.colors.selected != StateObjectValue.NONE) ? dto.colors.selected : new RGB(dto.color).darker();
        var lineColor:uint = (dto.borderColors.selected != StateObjectValue.NONE) ? dto.borderColors.selected : 0x505050;
        drawButtonShape(ButtonState.SELECTED, bntColor, lineColor);
    }

    /**
     *  @inheritDoc
     */
    public function drawInactiveState():void {
        var bntColor:uint = (dto.colors.disabled != StateObjectValue.NONE) ? dto.colors.disabled : new RGB(dto.color).brighter(0.99);
//			var bntColor:uint = 0xdfdfdf //0x0b0d0e //0xACA899;
        //var bntColor:uint = VVUI.DEFAULT_COLOR;
        var lineColor:uint = (dto.borderColors.disabled != StateObjectValue.NONE) ? dto.borderColors.disabled : getGrayTintColor();
        drawButtonShape(ButtonState.DISABLED, bntColor, lineColor);
    }

    /**
     *  @inheritDoc
     */
    public function drawInactiveIcon():void {
        var it:Transform = dto.icon.transform;
        it.colorTransform = new ColorTransform(.2, .2, .2, .2);
    }

    /**
     *  @inheritDoc
     */
    public function drawActiveIcon():void {
        var it:Transform = dto.icon.transform;
        it.colorTransform = new ColorTransform(1, 1, 1, 1);
    }

    /**
     *  @inheritDoc
     */
    public function drawDottedLine():void {
        /*if(dashedLine==null) dashedLine = new DashedLine(dto, 1, 2);
         dashedLine.lineStyle(0, 0x777777, 1, true);
         dashedLine.drawRectangle(new Point(2, 2), new Point(dto.width-2, dto.height-2));
         dashedLine.endFill();*/
    }

    /**
     *  @inheritDoc
     */
    public function getColor():uint {
        return DEFAULT_BUTTON_COLOR;
    }

    /**
     *  @inheritDoc
     */
    public function getBorderColor():uint {
        return 0xFFFFFF;
    }

    /**
     *  @inheritDoc
     */
    public function getUpFontFormat():FontFormat {
        return _fontFormat;
    }

    /**
     *  @inheritDoc
     */
    public function getOverFontFormat():FontFormat {
        return _fontFormat;
    }

    /**
     *  @inheritDoc
     */
    public function getDownFontFormat():FontFormat {
        return _fontFormat;
    }

    /**
     *  @inheritDoc
     */
    public function getSelectedFontFormat():FontFormat {
        return _fontFormat;
    }

    /**
     *  @inheritDoc
     */
    public function getDisabledFontFormat():FontFormat {
        return _disabledFontFormat;
    }

    /**
     *  @inheritDoc
     */
    public function getGrayTintColor():uint {
        return 0xACA899;
    }

    /**
     *  @inheritDoc
     */
    public function getIconDelay():Number {
        return 2;
    }

    /**
     *  @inheritDoc
     */
    public function getTopOffset():Number {
        return 2;
    }

    /**
     *  @inheritDoc
     */
    public function getLeftOffset():Number {
        return 2;
    }

    /**
     *  @inheritDoc
     */
    public function getRightOffset():Number {
        return 2;
    }

    /**
     *  @inheritDoc
     */
    public function getBottomOffset():Number {
        return 2;
    }

    /**
     * 	@private
     */
    override public function drawBackFace():void {
        drawOutState();
    }

    //--------------------------------------------------------------------------
    //
    //  Private properties
    //
    //--------------------------------------------------------------------------

    protected var _fontFormat:FontFormat =
            new FontFormat(DEFAULT_FONT_FACE, DEFAULT_FONT_SIZE, DEFAULT_BUTTON_FONT_COLOR, true);
    private var _disabledFontFormat:FontFormat =
            new FontFormat(DEFAULT_FONT_FACE, DEFAULT_FONT_SIZE, getGrayTintColor(), true);

    //private var dashedLine:DashedLine;
    protected const BUTTON_CURVE_HEIGHT:Number = 1;

    //--------------------------------------------------------------------------
    //
    //  Private methods
    //
    //--------------------------------------------------------------------------

    protected function drawButtonShape(state:String, buttonColor:uint, lineColor1:uint, lineColor2:int = -1):void {
        var w:Number = dto.width;
        var h:Number = dto.height;
        var bch:Number = BUTTON_CURVE_HEIGHT;
        var middle:Number = h/2;
        var cu:LafDTOCornerUtil = new LafDTOCornerUtil(dto, 6);
        var bw:Number = dto.borderWidth;
        var tgt:Sprite = dto.currentTarget;
        var manager:TextureManager = dto.textureManager;
        var m:Matrix = MatrixUtil.getMatrix(w, h);
        var bga:Number = dto.backgroundAlpha;
        var bdra:Number = dto.borderAlpha;
        if (manager.texture) {
            var ct:ColorTransform;
            switch(state) {
                case ButtonState.UP :
                    break;
                case ButtonState.OVER :
                    ct = new ColorTransform();
                    ct.redOffset = ct.blueOffset = ct.greenOffset = 50;
                    break;
                case ButtonState.DISABLED :
                    ct = new ColorTransform();
                    ct.redOffset = ct.blueOffset = ct.greenOffset = 150;
                    break;
                case ButtonState.DOWN :
                case ButtonState.SELECTED:
                    ct = new ColorTransform();
                    ct.redOffset = ct.blueOffset = ct.greenOffset = -50;
                    break;
            }
            manager.colorTransform = ct;
            manager.setShape = function():void {
                with(manager.figure) {
                    lineStyle(bw, lineColor1, bdra, true);
                    if (lineColor2 != -1) lineGradientStyle(GradientType.LINEAR, [lineColor1, lineColor2], [bdra, bdra], [0, 250], m);
                    drawRoundedBox(0, 0, w, h, cu.topLeft, cu.topRight, cu.bottomRight, cu.bottomLeft);
                    drawSpasEffect(tgt, w, lineColor1, cu, middle, bch);
                }
            }
            manager.draw(TextureType.TEXTURE);
        } else {
            var f:Figure = Figure.setFigure(tgt);
            f.clear();
            switch(state) {
                case ButtonState.UP :
                case ButtonState.OVER :
                case ButtonState.DOWN :
                case ButtonState.SELECTED:
                    //f.lineStyle(bw, lineColor1, bdra, true);
                    f.beginFill( buttonColor, 1 );
                    f.drawRoundedBox(0, 0, w, h, cu.topLeft, cu.topRight, cu.bottomRight, cu.bottomLeft);
                    f.endFill();
            }
            //if (lineColor2 != -1)
            //f.lineGradientStyle(GradientType.LINEAR, [lineColor1, lineColor2], [bdra, bdra], [0, 250], m);

            //var color2:RGB = new RGB(buttonColor);
            //f.beginGradientFill(GradientType.LINEAR, [color2.darker(), buttonColor], [bga, bga], [0, 250], m);
            //drawSpasEffect(tgt, w, lineColor1, cu, middle, bch);
        }
    }

    private function drawSpasEffect(tgt:Sprite, w:Number, lineColor1:uint, cu:LafDTOCornerUtil, middle:Number, bch:Number):void {
        // This draws a VERY annoying line down the middle of the panel
        return;

        with(tgt.graphics) {
            moveTo(cu.topLeft, 0);
            lineStyle(0, lineColor1, 0);
            beginFill(0xFFFFFF, .2);
            lineTo(w-cu.topRight, 0);
            curveTo(w, 0, w, cu.topRight);
            lineTo(w, middle);
            curveTo(3*w/4, middle+bch, w/2, middle);
            curveTo(w/4, middle-bch, 0, middle);
            lineTo(0, cu.topLeft);
            curveTo(0, 0, cu.topLeft, 0);
            endFill();
        }
    }
}
}