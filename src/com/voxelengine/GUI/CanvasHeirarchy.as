
package com.voxelengine.GUI
{
import org.flashapi.swing.Canvas;
import com.voxelengine.Globals;
import org.flashapi.swing.containers.UIContainer;
	
public class CanvasHeirarchy extends Canvas
{
	private var _parent:WindowRegionModels;
	public function CanvasHeirarchy( $parent:WindowRegionModels, $width:Number = 100, $height:Number = 100)
	{
		_parent = $parent;
		super($width,$height);
		this.$parent = $parent;
	}
	
	public function topLevelGet():* {
		return this;
	}
	
	public function recalc( $width:Number, $height:Number ):void {
		if ( width < $width || height < $height ) {
			resize( $width, $height );
			_parent.recalc( $width, $height );
		}
	}
}
}