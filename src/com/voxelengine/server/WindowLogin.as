
package com.voxelengine.server
{
	import flash.display.Bitmap;
	import flash.events.KeyboardEvent;
	import flash.events.Event;
	import flash.ui.Keyboard;
	
	import org.flashapi.swing.*;
	import org.flashapi.swing.button.ButtonGroup;
    import org.flashapi.swing.event.*;
    import org.flashapi.swing.constants.*;
	import org.flashapi.swing.plaf.spas.SpasUI;
	
	import com.voxelengine.Log;
	import com.voxelengine.Globals;
	import com.voxelengine.events.LoginEvent;
	import com.voxelengine.server.Network;
	
	import com.voxelengine.GUI.VVPopup;
	import com.voxelengine.GUI.WindowSandboxList;
	
	
	public class WindowLogin extends VVPopup
	{
		private var _emailInput:LabelInput;
		private var _passwordInput:LabelInput;
		private var _errorText:TextArea;

		private var _topImage:Bitmap;
		[Embed(source='../../../../../Resources/bin/assets/textures/loginImage.png')]
		private var _topImageClass:Class;
		
		public function WindowLogin( $email:String, $password:String )
		{
			super( "Login" );
			width = 300;
			height = 336;
			layout.orientation = LayoutOrientation.VERTICAL;

			if ( !Globals.g_debug )
				showCloseButton = false;

			_topImage = (new _topImageClass() as Bitmap);
			var pic:Image = new Image( _topImage, width, 189 );
			addElement(pic);
			
			var infoPanel:Container = new Container( width, 80 );
			infoPanel.layout.orientation = LayoutOrientation.VERTICAL;
			infoPanel.addElement( new Spacer( width, 15 ) );
			
			_emailInput = new LabelInput( " Email", $email, width );
			_emailInput.labelControl.width = 80;
			infoPanel.addElement( _emailInput );
			
			infoPanel.addElement( new Spacer( width, 10 ) );
			
			_passwordInput = new LabelInput( " Password", $password, width );
			_passwordInput.labelControl.width = 80;
			infoPanel.addElement( _passwordInput );
			
			_errorText = new TextArea( width, 40);
			_errorText.backgroundColor = SpasUI.DEFAULT_COLOR;
			_errorText.scrollPolicy = ScrollPolicy.NONE;
			_errorText.fontColor = 0xff0000; // Red
			
			infoPanel.addElement( _errorText )
			
			addElement( infoPanel );
			
			const buttonWidth:int = 99;
			const buttonHeight:int = 40;
			var buttonPanel:Container = new Container( width, buttonHeight );
			var loginButton:Button = new Button( "Login", buttonWidth, buttonHeight );
			loginButton.addEventListener(UIMouseEvent.CLICK, loginButtonHandler );
			buttonPanel.addElement( loginButton );
			
			var registerButton:Button = new Button( "Register..", buttonWidth, buttonHeight );
			registerButton.addEventListener(UIMouseEvent.CLICK, registerButtonHandler );
			buttonPanel.addElement( registerButton );
			
			var lostPasswordButton:Button = new Button( "Lost Password", buttonWidth, buttonHeight );
			lostPasswordButton.fontSize = 9;
			lostPasswordButton.addEventListener(UIMouseEvent.CLICK, lostPasswordHandler );
			buttonPanel.addElement( lostPasswordButton );
			
			addElement( buttonPanel );
			
			display( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
			
			Globals.g_app.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
		}
		
        //override protected function onResize(event:Event):void
        //{
			//move( Globals.g_renderer.width / 2 - (((width + 10) / 2) + x ), Globals.g_renderer.height / 2 - (((height + 10) / 2) + y) );
		//}

		// Allows the enter key to activate the login key.
		private function onKeyPressed( e : KeyboardEvent) : void {
			if ( Keyboard.ENTER == e.keyCode ) {
				Globals.g_app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
				loginButtonHandler(null);
			}
		}
		
		////////////////////////////////////////////////////////////////////////////////
		// recovery password
		////////////////////////////////////////////////////////////////////////////////
		private function lostPasswordHandler(event:UIMouseEvent):void {
			addRecoveryEventHandlers();
			Network.recoverPassword( _emailInput.label );
		}

		private function addRecoveryEventHandlers():void {
			Globals.g_app.addEventListener( LoginEvent.PASSWORD_RECOVERY_SUCCESS, recoverySuccess );
			Globals.g_app.addEventListener( LoginEvent.PASSWORD_RECOVERY_FAILURE, recoveryFailure );
		}
		
		private function removeRecoveryEventHandlers():void {
			Globals.g_app.removeEventListener( LoginEvent.PASSWORD_RECOVERY_SUCCESS, recoverySuccess );
			Globals.g_app.removeEventListener( LoginEvent.PASSWORD_RECOVERY_FAILURE, recoveryFailure );
		}
		
		private function recoverySuccess( $e:LoginEvent ):void 
		{ 
			removeRecoveryEventHandlers();
			(new Alert( "An email has been sent to " + _emailInput.label, 350 )).display();
		}

		private function recoveryFailure( $e:LoginEvent ):void 
		{ 
			removeRecoveryEventHandlers();
			(new Alert( "No account has been found for " + _emailInput.label, 350 )).display();
		}

		////////////////////////////////////////////////////////////////////////////////
		// register new account
		////////////////////////////////////////////////////////////////////////////////
		private function registerButtonHandler(event:UIMouseEvent):void 
		{
			new WindowRegister();
			remove();
		}
		
		////////////////////////////////////////////////////////////////////////////////
		// login
		////////////////////////////////////////////////////////////////////////////////
		private function loginButtonHandler(event:UIMouseEvent):void 
		{
			_errorText.text = "";
			_emailInput.glow = false;
			_passwordInput.glow = false;
			addLoginEventHandlers();
			Log.out("WindowLogin.loginButtonHandler - Trying to establish connection to server", Log.WARN );
			Network.login( _emailInput.label, _passwordInput.label );
		}
		
		private function addLoginEventHandlers():void {
			Globals.g_app.addEventListener( LoginEvent.LOGIN_SUCCESS, loginSuccess );
			Globals.g_app.addEventListener( LoginEvent.LOGIN_FAILURE, onUnknownFailure );
			Globals.g_app.addEventListener( LoginEvent.LOGIN_FAILURE_PASSWORD, onPasswordFailure );
			Globals.g_app.addEventListener( LoginEvent.LOGIN_FAILURE_EMAIL, onEmailFailure );
		}
		
		private function removeLoginEventHandlers():void {
			Globals.g_app.removeEventListener( LoginEvent.LOGIN_SUCCESS, loginSuccess );
			Globals.g_app.removeEventListener( LoginEvent.LOGIN_FAILURE, onUnknownFailure );
			Globals.g_app.removeEventListener( LoginEvent.LOGIN_FAILURE_PASSWORD, onPasswordFailure );
			Globals.g_app.removeEventListener( LoginEvent.LOGIN_FAILURE_EMAIL, onEmailFailure );
		}
		
		private function onPasswordFailure( $e:LoginEvent ):void {
			removeLoginEventHandlers()
			Log.out(" WindowLogin.onPasswordFailure" + $e.guid );
			_passwordInput.glow = true;
			_errorText.text = $e.guid;
		}
		
		private function onEmailFailure( $e:LoginEvent ):void {
			removeLoginEventHandlers()
			Log.out(" WindowLogin.onEmailFailure" + $e.guid );
			_emailInput.glow = true;
			_errorText.text = $e.guid;
		}
		
		private function onUnknownFailure( $e:LoginEvent ):void {
			removeLoginEventHandlers()
			Log.out(" WindowLogin.onUnknownFailure" + $e.guid );
			_errorText.text = $e.guid;
		}
		
		private function loginSuccess( $e:LoginEvent ):void {
			removeLoginEventHandlers()
			Log.out(" WindowLogin.loginSuccess - Closing Login Window" );
			
			remove();
		}
	}
}