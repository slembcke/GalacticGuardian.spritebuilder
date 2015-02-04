uniform vec2 u_ScrollOffset;
uniform highp float u_StarfieldDepth;
uniform highp float u_NebulaDepth1;
uniform highp float u_NebulaDepth2;

varying vec2 v_ParallaxCoords1;
varying vec2 v_ParallaxCoords2;
varying vec2 v_ParallaxOffset;

void main(){
	gl_Position = cc_Position;
	cc_FragColor = clamp(cc_Color, 0.0, 1.0);
	
	// TODO doesn't respect the view's aspect ratio.
	// Use a custom varying to pass the parallax offset.
	v_ParallaxOffset = gl_Position.xy/(gl_Position.w);
	v_ParallaxOffset.y *= cc_ViewSize.y/cc_ViewSize.x;
	
	// Starfield
	cc_FragTexCoord1 = cc_TexCoord1 + u_StarfieldDepth*v_ParallaxOffset;
	
	// Distortion Map
	cc_FragTexCoord2 = 0.5 + gl_Position.xy*(0.5/gl_Position.w);
	
	v_ParallaxCoords1 = 0.7*(cc_TexCoord1 + u_NebulaDepth1*v_ParallaxOffset);
	v_ParallaxCoords2 = 0.4*(cc_TexCoord1 + u_NebulaDepth2*v_ParallaxOffset) + vec2(0.5);
}
