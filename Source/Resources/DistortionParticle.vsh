void main(){
	gl_Position = cc_Position;
	
	// Apply a nice cubic hermite curve to the particle's alpha to make it fade in and out nicely.
	float a = cc_Color.a;
	cc_FragColor = vec4(a*(a*a - 2.0*a + 1.0));
	
	cc_FragTexCoord1 = cc_TexCoord1;
}
