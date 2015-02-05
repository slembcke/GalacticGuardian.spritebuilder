uniform highp float u_StarfieldDepth;
uniform highp float u_NebulaDepth1;
uniform highp float u_NebulaDepth2;

uniform sampler2D u_NebulaTexture;
uniform sampler2D u_DepthMap;
uniform sampler2D u_DistortionMap;

varying vec2 v_ParallaxCoords1;
varying vec2 v_ParallaxCoords2;
varying mediump vec2 v_ParallaxOffset;

const float DistortionAmount = 0.5;

mediump vec4 composite(vec4 over, vec4 under){return over + under*(1.0 - over.a);}

void main(){
	// Sample the distortion offset from the distortion map for the distortion field effect.
	mediump vec2 distortion = DistortionAmount*(2.0*texture2D(u_DistortionMap, cc_FragTexCoord2).xy - 1.0);
	
	// Starfield
	gl_FragColor = texture2D(cc_MainTexture, cc_FragTexCoord1 + u_StarfieldDepth*distortion);
	
//	// Nebula1
//	float depth1 = texture2D(u_DepthMap, v_ParallaxCoords1).r;
//	mediump vec2 parallax1 = 0.2*v_ParallaxOffset*(1.0 - depth1);
//	gl_FragColor = composite(0.7*texture2D(u_NebulaTexture, v_ParallaxCoords1 + parallax1 + u_NebulaDepth1*distortion), gl_FragColor);
	
	// Nebula2
	float depth2 = texture2D(u_DepthMap, v_ParallaxCoords2).r;
	mediump vec2 parallax2 = 0.2*v_ParallaxOffset*(1.0 - depth2);
	gl_FragColor = composite(texture2D(u_NebulaTexture, v_ParallaxCoords2 + parallax2 + u_NebulaDepth2*distortion), gl_FragColor);
}
