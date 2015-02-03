uniform sampler2D u_DepthMap;
uniform sampler2D u_DistortionMap;

varying mediump vec2 v_ParallaxOffset;

const float DistortionAmount = 0.25;

void main(){
	// Calculate the amount of distortion to apply for the parallax mapping effect.
	float depth = texture2D(u_DepthMap, cc_FragTexCoord1).x;
	mediump vec2 parallax = v_ParallaxOffset*(1.0 - depth);
	
	// Sample the distortion offset from the distortion map for the distortion field effect.
	mediump vec2 distortion = 2.0*texture2D(u_DistortionMap, cc_FragTexCoord2).xy - 1.0;
	
	// Add the distortion offsets together, sample and tint.
	gl_FragColor = cc_FragColor*texture2D(cc_MainTexture, cc_FragTexCoord1 + parallax + DistortionAmount*distortion);
}
