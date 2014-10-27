uniform float u_ParallaxAmount;
uniform vec2 u_ScrollOffset;

varying vec2 v_ParallaxOffset;

void main(){
	gl_Position = cc_Position;
	cc_FragColor = clamp(cc_Color, 0.0, 1.0);
	cc_FragTexCoord1 = cc_TexCoord1;
	
	// Use UV2 for the screen space distortion map tex coords.
	cc_FragTexCoord2 = 0.5 + gl_Position.xy*(0.5/gl_Position.w);
	
	// Use a custom varying to pass the parallax offset.
	v_ParallaxOffset = gl_Position.xy*(u_ParallaxAmount/gl_Position.w);
	
	// Apply scroll offset to the background.
	// This was a simple cheat to make the background on the menu scroll more easily.
	cc_FragTexCoord1 += u_ScrollOffset;
}
