
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
		private var _errorText:TextArea;

		private var _topImage:Bitmap;
		[Embed(source='../../../../../Resources/bin/assets/textures/loginImage.png')]
		private var _topImageClass:Class;
		
		public function WindowLogin( email:String = "bob@me.com", password:String = "bob" )
		{
			super( "Login" );
            //autoSize = true;
			width = 300;
			height = 340;
			layout.orientation = LayoutOrientation.VERTICAL;

			if ( !Globals.g_debug )
				closeButtonActive = false;  // this greys it out, and doesnt allow it to be clicked

			_topImage = (new _topImageClass() as Bitmap);
			var pic:Image = new Image( _topImage, width, 189 );
			addElement(pic);
			
			var infoPanel:Container = new Container( width, 80 );
			infoPanel.layout.orientation = LayoutOrientation.VERTICAL;
			infoPanel.addElement( new Spacer( width, 15 ) );
			
			_email = email;
			_emailInput = new LabelInput( " Email", _email, width );
			_emailInput.labelControl.width = 80;
			_emailInput.editableText.addEventListener( TextEvent.EDITED, 
				function( event:TextEvent ):void 
				{ _email = event.target.text; } );
			infoPanel.addElement( _emailInput );
			
			infoPanel.addElement( new Spacer( width, 10 ) );
			
			_password = password;
			_passwordInput = new LabelInput( " Password", _password, width );
			_passwordInput.labelControl.width = 80;
			_passwordInput.editableText.addEventListener( TextEvent.EDITED, 
				function( event:TextEvent ):void 
				{ _password = event.target.text; } );
			infoPanel.addElement( _passwordInput );
			
			_errorText = new TextArea( width, 40);
			_errorText.backgroundColor = 0xC0C0C0;
			_errorText.scrollPolicy = ScrollPolicy.NONE;
			_errorText.fontColor = 0xff0000;
			
			infoPanel.addElement( _errorText )
			
			addElement( infoPanel );
			
			const buttonWidth:int = 100;
			const buttonHeight:int = 40;
			var buttonPanel:Container = new Container( width, 40 );
			var loginButton:Button = new Button( "Login", buttonWidth, buttonHeight );
			loginButton.addEventListener(UIMouseEvent.CLICK, loginButtonHandler );
			buttonPanel.addElement( loginButton );
			
			var registerButton:Button = new Button( "Register..", buttonWidth, buttonHeight );
			registerButton.addEventListener(UIMouseEvent.CLICK, registerButtonHandler );
			buttonPanel.addElement( registerButton );
			
			var lostPasswordButton:Button = new Button( "Lost Password", buttonWidth, buttonHeight );
			lostPasswordButton.fontSize = 10;
			lostPasswordButton.addEventListener(UIMouseEvent.CLICK, lostPasswordHandler );
			buttonPanel.addElement( lostPasswordButton );
			
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
			
		private function loginButtonHandler(event:UIMouseEvent):void 
		{
			_errorText.text = "";
			_emailInput.glow = false;
			_passwordInput.glow = false;
			PlayerIO.quickConnect.simpleConnect( Globals.g_app.stage
											   , Globals.g_gamesNetworkID
											   , _email
											   , _password
											   , connectSuccess
											   , simpleConnectFailure );
			Log.out("WindowLogin.loginButtonHandler - Trying to establish connection to server");
		}
		
		private function registerButtonHandler(event:UIMouseEvent):void 
		{
			new WindowRegister();
			remove();
		}
		
		private function lostPasswordHandler(event:UIMouseEvent):void 
		{
			PlayerIO.quickConnect.simpleRecoverPassword( Globals.g_gamesNetworkID, _email, recoverySuccess, recoveryFailure );

			function recoverySuccess():void 
			{ 
				(new Alert( "An email has been sent to " + ( _email ? _email : "INVALID EMAIL ADDRESS"), 350 )).display();
			}

			function recoveryFailure( error:PlayerIOError ):void 
			{ 
				(new Alert( "No account has been found for " + ( _email ? _email : "INVALID EMAIL ADDRESS"), 350 )).display();
			}
		}
		
		
		public function simpleConnectFailure( $error:PlayerIOError):void
		{
			_errorText.text = $error.name + ": " + $error.message;
			if ( 0 < _errorText.text.indexOf( "user" ) )
				_emailInput.glow = true;
			else if ( 0 < _errorText.text.indexOf( "password" ) )
				_passwordInput.glow = true;
			else
				Log.writeError(" WindowLogin.simpleConnectFailure", _errorText.text, $error );
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