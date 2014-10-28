const float BurnScale = 3.0;

void main(){
	gl_Position = cc_Position;
	cc_FragColor = cc_Color;
	cc_FragTexCoord1 = cc_TexCoord1;
	cc_FragTexCoord2 = BurnScale*cc_TexCoord1;
}
