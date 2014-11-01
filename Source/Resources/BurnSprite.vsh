uniform float u_BurnScale;

void main(){
	gl_Position = cc_Position;
	cc_FragColor = cc_Color;
	cc_FragTexCoord1 = cc_TexCoord1;
	cc_FragTexCoord2 = u_BurnScale*cc_TexCoord1;
}
