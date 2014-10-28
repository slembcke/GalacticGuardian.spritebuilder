uniform sampler2D u_BurnTexture;

const float GlowWidth_Inv = 1.0/0.4;

void main(){
	float threshold = cc_FragColor.a;

	float burn = texture2D(u_BurnTexture, cc_FragTexCoord2).r;
	vec4 color = texture2D(cc_MainTexture, cc_FragTexCoord1);
	
	// Add some glow where the burn value is slightly below the threshold.
	float glow = color.a*clamp(1.0 + (burn - threshold)*GlowWidth_Inv, 0.0, 1.0);
	
	// Perform a hard cut on the alpha if the burn map value is below the threshold.
	// Add the glow and main color together.
	gl_FragColor = step(burn, threshold)*(mix(color, vec4(cc_FragColor.rgb, 1.0), glow));
}
