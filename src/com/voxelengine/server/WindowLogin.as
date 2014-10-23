
package com.voxelengine.server
{
	import flash.events.Event;
	import flash.display.Bitmap;
	
	import org.flashapi.swing.*;
	import org.flashapi.swing.button.ButtonGroup;
    import org.flashapi.swing.event.*;
	import org.flashapi.swing.color.SVGCK;
    import org.flashapi.swing.constants.*;
	
	import playerio.Client;
	import playerio.PlayerIO;
	import playerio.PlayerIOError;
	
	import com.voxelengine.Globals;
	import com.voxelengine.Log;
	import com.voxelengine.events.LoginEvent;
	import com.voxelengine.GUI.VVPopup;
	import com.voxelengine.GUI.WindowSandboxList;
	
	public class WindowLogin extends VVPopup
	{
		//private var eventCollector:EventCollector = new EventCollector();
		private var _emailInput:LabelInput = null;
		private var _email:String;
		private var _passwordInput:LabelInput = null;
		private var _password:String;
		private var _result:Text;

		private var _background:Bitmap;
		[Embed(source='../../../../../Resources/bin/assets/textures/black.jpg')]
		private var _backgroundImage:Class;
		
		public function WindowLogin( email:String = "bob@me.com", password:String = "bob" )
		{
			super( "Login" );
            autoSize = true;
			width = 300;
			height = 800;
			layout.orientation = LayoutOrientation.VERTICAL;
			
			_background = (new _backgroundImage() as Bitmap);
			//backgroundTexture = _background;
			//texture = _background;
			
			var infoPanel:Panel = new Panel( width, 200 );
			infoPanel.layout.orientation = LayoutOrientation.VERTICAL;
			
			_email = email;
			_emailInput = new LabelInput( "email", _email );
			_emailInput.labelControl.width = 80;
			_emailInput.editableText.addEventListener( TextEvent.EDITED, 
				function( event:TextEvent ):void 
				{ _email = event.target.text; } );
			infoPanel.addElement( _emailInput );
			
			_password = password;
			_passwordInput = new LabelInput( "Password", _password );
			_passwordInput.labelControl.width = 80;
			_passwordInput.editableText.addEventListener( TextEvent.EDITED, 
				function( event:TextEvent ):void 
				{ _password = event.target.text; } );
			infoPanel.addElement( _passwordInput );
			addElement( infoPanel );
			
			var buttonPanel:Panel = new Panel( width, 40 );
			//var buttonPanel:Panel = new Panel( 200, 30 );
			var loginButton:Button = new Button( "Login" );
			loginButton.addEventListener(UIMouseEvent.CLICK, loginButtonHandler );
			buttonPanel.addElement( loginButton );
			
			var registerButton:Button = new Button( "Register" );
			registerButton.addEventListener(UIMouseEvent.CLICK, registerButtonHandler );
			buttonPanel.addElement( registerButton );
			addElement( buttonPanel );
			
			//_result = new Text(200, 30);
			//_result.textAlign = TextAlign.CENTER;
			//_result.textFormat.size = 16;
			//var my_SVGCK:SVGCK = new SVGCK("orangered");
			//_result.textFormat.color = my_SVGCK;
			//addElement( _result );
			
			display( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
			
			//Globals.g_app.stage.addEventListener( LoginEvent.LOGIN_SUCCESS, onLoginSucess );
		}

			
		// Window events
		private function onRemoved( event:UIOEvent ):void
 		{
            Globals.g_app.stage.removeEventListener(Event.RESIZE, onResize);
			removeEventListener(UIOEvent.REMOVED, onRemoved );
		}
		
        protected function onResize(event:Event):void
        {
			move( Globals.g_renderer.width / 2 - (width + 10) / 2, Globals.g_renderer.height / 2 - (height + 10) / 2 );
		}
		
		private function loginButtonHandler(event:UIMouseEvent):void 
		{
			PlayerIO.quickConnect.simpleConnect( Globals.g_app.stage
											   , Globals.g_gamesNetworkID
											   , _email
											   , _password
											   , connectSuccess
											   , connectFailure );
			Log.out("WindowLogin.loginButtonHandler - Trying to establish connection to server");
		}
		
		private function registerButtonHandler(event:UIMouseEvent):void 
		{
			new WindowRegister();
			remove();
		}
		
		public function connectFailure(error:PlayerIOError):void
		{
			Log.writeError(" VVServer.handleConnectError", "Failed on connect to server", error );
		}
		
		public function connectSuccess( $client:Client):void
		{
			remove();
			trace("WindowLogin.connectSuccess - connection to server established");
			onSuccess( $client );
		}
		
		// This was a test to see if I could make a client that didnt need user interaction.
		// This will allow me to do things like post to Facebook things that users create.
		static public function autoLogin():void {
			PlayerIO.quickConnect.simpleConnect( Globals.g_app.stage
											   , Globals.g_gamesNetworkID
											   , "bob@me.com"
											   , "bob"
											   , connectSuccess
											   , function (error:PlayerIOError):void { Log.out("WindowLogin.handleConnectError", Log.ERROR); }
											   );
											   
			function connectSuccess( $client:Client):void
			{
				Log.out("WindowLogin.connectSuccess - connection to server established using AUTOLOGIN");
				onSuccess( $client );
			}
		}
		
		static private function onSuccess( $client:Client ):void {
			
			Network.userId = $client.connectUserId;
			Network.client = $client
			Globals.online = true;
			if ( !WindowSandboxList.isActive )
				WindowSandboxList.create();
			
		}
		
	}
}