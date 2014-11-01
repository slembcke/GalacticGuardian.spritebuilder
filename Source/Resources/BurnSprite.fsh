uniform sampler2D u_BurnTexture;

// Destroyed pieces should always be darkened a little to visually distinguish themselves.
// Blackening them completely looks bad too though.
uniform float u_MinChar;
uniform float u_MaxChar;

uniform float u_CharSmooth;
uniform float u_CharWidth;

uniform float u_GlowSmooth;

void main(){
	// The sprite's alpha. 
	// Make the threshold start higher than 1.0 to give the charring and glowing some padding.
	float threshold = (1.0 + u_CharWidth)*cc_FragColor.a;
	
	// This is a texture with a noise pattern on it.
	// By comparing the threshold to this, we figure out which pixels to char, burn or clip.
	float burn = texture2D(u_BurnTexture, cc_FragTexCoord2).r;
	
	// Sample the sprite's actual texture. We'll start modifying it.
	gl_FragColor = texture2D(cc_MainTexture, cc_FragTexCoord1);
	
	// First figure out how much to char the sprite.
	float charring = smoothstep(0.0, u_CharSmooth, burn - threshold + u_CharWidth);
	// We just want to blacken the sprite, so multiplying the rgb components is good enough.
	gl_FragColor.rgb *= mix(u_MinChar, u_MaxChar, charring);
	
	// The sprite's color is used for the glow color.
	// Unfortunately vertex colors are premultiplied, need to undo that.
	// Precision issues only show up once the sprite is nearly fully faded out. \o/
	vec4 glowColor = vec4(cc_FragColor.rgb/cc_FragColor.a, 1.0);
	
	// Calculate the glow factor like the char factor.
	// Multiply by the sprite's alpha to clip it.
	float glow = gl_FragColor.a*clamp(1.0 + (burn - threshold)/u_GlowSmooth, 0.0, 1.0);
	
	// Add the glow to the color and multiply the step() function to clip pixels that are burnt away.
	gl_FragColor = step(burn, threshold)*(gl_FragColor + glow*glowColor);
}
