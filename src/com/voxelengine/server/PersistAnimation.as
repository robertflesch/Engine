package com.voxelengine.server 
{
	import com.voxelengine.events.AnimationLoadedEvent;
	import com.voxelengine.events.LoadingEvent;
	import com.voxelengine.worldmodel.animation.Animation;
	import flash.utils.ByteArray;
	
	import playerio.BigDB;
	import playerio.PlayerIOError;
	import playerio.DatabaseObject;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.PersistanceEvent;
	
	public class PersistAnimation extends Persistance
	{
		static public const DB_TABLE_ANIMATIONS:String = "animations";
		

		static public function loadAnims( $userName:String ):void {
			
			loadRange( PersistAnimation.DB_TABLE_ANIMATIONS
						 , "owner"
						 , [$userName]
						 , null
						 , null
						 , 100
						, loadAnimationSuccessHandler
						, function (e:PlayerIOError):void {  Log.out( "PersistAnimation.errorHandler - e: " + e ); } );
		}
		
		static private function loadAnimationSuccessHandler( dba:Array ):void {
			
			trace( "PersistAnimation.loadAnimationSuccessHandler - Anims loaded: " + dba.length );
			for each ( var dbo:DatabaseObject in dba )
			{
				loadAnimFromDBO( dbo );
			}
		}
		
		static private function loadAnimFromDBO( dbo:DatabaseObject ):void
		{
			var anim:Animation = new Animation( dbo.name, dbo.owner );
//			anim.admin = cvsToVector( dbo.admin );
//			anim.editors = cvsToVector( dbo.editors );
			anim.databaseObject = dbo;
			anim.desc = dbo.description;
			//anim.name = ;
			//anim.owner = 
			anim.world = dbo.world;
			anim.model = dbo.model;  // Parent model
			anim.created = dbo.created;
			anim.modified = dbo.modified;
			var $ba:ByteArray = dbo.data as ByteArray;
			
//			Log.out( "PersistAnimation.loadFromDBO - AnimJson: " + anim.name + "  owner: " + newAnim.owner );
			
			$ba.uncompress();
			$ba.position = 0;
			// how many bytes is the animationInfo
			var strLen:int = $ba.readInt();
			// read off that many bytes
			var animJson:String = $ba.readUTFBytes( strLen );
			//AnimJson = decodeURI(AnimJson);
			anim.initJSON( animJson );
			
			// Now that we have a fully formed Anim, inform the Anim manager
			Globals.g_app.dispatchEvent( new AnimationLoadedEvent( AnimationLoadedEvent.ANIMATION_CREATED, anim ) );
		}

		static public function saveAnim( $metadata:Object, $dbo:DatabaseObject, $createSuccess:Function ):void {

			if ( $dbo )
			{
				Log.out( "PersistAnimation.save - saving Anim back to BigDB: " + $metadata.guid );
				$dbo.name = $metadata.name;
				$dbo.description = $metadata.desc;
				$dbo.data = $metadata.data;
				$dbo.world = $metadata.world;
				$dbo.modified = new Date();
				//$dbo.model = $metadata.model;  // Parent model
//				$dbo.admin = $metadata.admin;
//				$dbo.editors = $metadata.editors;
				//$dbo.owner = $metadata.owner;  // Do not think this should be allowed to change under normal circumstances
				
				$dbo.save( false
					     , false
					     , function saveAnimSuccess():void  {  Log.out( "PersistAnimation.saveAnimSuccess - guid: " + $metadata.guid ); }	
					     , function saveAnimFailed(e:PlayerIOError):void  { 
							Globals.g_app.dispatchEvent( new PersistanceEvent( PersistanceEvent.PERSISTANCE_SAVE_FAILURE, $metadata.guid ) ); 
							Log.out( "PersistAnimation.saveAnimFailed - error data: " + e); }  
						);
			}
			else
			{
				Log.out( "PersistAnimation.create - creating new Anim: " + $metadata.guid + "" );
				createObject( PersistAnimation.DB_TABLE_ANIMATIONS
							, $metadata.guid
							, $metadata
							, $createSuccess
							, function createFailed(e:PlayerIOError):void { 
								Globals.g_app.dispatchEvent( new PersistanceEvent( PersistanceEvent.PERSISTANCE_CREATE_FAILURE, $metadata.guid ) ); 
								Log.out( "PersistAnimation.createFailed - error saving: " + $metadata.guid + " error data: " + e);  }
							);
			}
			
		}
		
		// comma seperated variables
		static private function cvsToVector( value:String ):Vector.<String> {
			var v:Vector.<String> = new Vector.<String>;
			var start:int = 0;
			var end:int = value.indexOf( ",", 0 );
			while ( -1 < end ) {
				v.push( value.substring( start, end ) );
				start = end + 1;
				end = value.indexOf( ",", start );
			}
			// there is only one, or this is the last one
			if ( -1 == end && start < value.length ) {
				v.push( value.substring( start, value.length ) );
			}
			return v;
		}
	}	
}
