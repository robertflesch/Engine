
package com.voxelengine.GUI 
{
import org.flashapi.swing.Box;
import org.flashapi.swing.event.ButtonsGroupEvent;
import org.flashapi.swing.constants.BorderStyle;
import org.flashapi.swing.button.RadioButtonGroup;
import org.flashapi.swing.databinding.DataProvider;

public class ComponentRadioButtonGroup extends Box
{
	public function ComponentRadioButtonGroup( $label:String, $buttonArray:Array, $changeHandler:Function, $initialValue:int, $width:int, $height:int = 40, $padding:int = 10 )
	{
		super( $width, $height );
		
		padding = $padding;
		backgroundColor = 0xCCCCCC;
		title = $label;
		borderStyle = BorderStyle.GROOVE;

		var rbg:RadioButtonGroup = new RadioButtonGroup( this );
		var dp:DataProvider = new DataProvider();
		for each ( var o:Object in $buttonArray )
			dp.add( o );

		eventCollector.addEvent( rbg, ButtonsGroupEvent.GROUP_CHANGED, $changeHandler );
		rbg.dataProvider = dp;
		rbg.index = $initialValue;
	}
}
}