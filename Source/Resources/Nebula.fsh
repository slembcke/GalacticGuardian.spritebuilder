uniform sampler2D u_DepthTexture;

varying vec2 v_ParallaxOffset;

void main(){
	// Calculate the amount of distortion to apply for the parallax mapping effect.
	float depth = texture2D(u_DepthTexture, cc_FragTexCoord1).x;
	vec2 parallax = v_ParallaxOffset*(1.0 - depth);
	
	// Calculate the amount of distortion to apply for the distortion effect.
	vec2 distortion = vec2(0.0);
	
	// Sample and tint.
	gl_FragColor = cc_FragColor*texture2D(cc_MainTexture, cc_FragTexCoord1 + parallax + distortion);
}
