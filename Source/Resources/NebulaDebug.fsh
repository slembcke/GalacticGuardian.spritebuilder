uniform sampler2D u_DepthMap;
uniform sampler2D u_DistortionMap;

varying mediump vec2 v_ParallaxOffset;

const float DistortionAmount = 0.5;

void main(){
	// Calculate the amount of distortion to apply for the parallax mapping effect.
	float depth = texture2D(u_DepthMap, cc_FragTexCoord1).x;
	mediump vec2 parallax = v_ParallaxOffset*(1.0 - depth);
	
	// Sample the distortion offset from the distortion map for the distortion field effect.
	mediump vec2 distortion = 2.0*texture2D(u_DistortionMap, cc_FragTexCoord2).xy - 1.0;
	
	// Show the distortion field texture coordinate offset.
	// The red channel is how much to offset the x-axis, green is y-axis.
	// When it shows a dim yellow color (0.5, 0.5, 0.0), that means no offset.
	// The colors are greatly exagerated to show the effect better.
	gl_FragColor = vec4(0.5 + 2.0*(parallax + DistortionAmount*distortion), 0.0, 1.0);
}
