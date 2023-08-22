// Distorts the screen.

#version 120
uniform sampler2D iChannel0;


uniform sampler2D screenBuffer;
uniform vec2 screenSize;

uniform float strength;

void main()
{
	vec4 d = texture2D(iChannel0, gl_TexCoord[0].xy);
	vec2 offset = (d.xy - 0.5)*d.a;

	vec4 c = texture2D(screenBuffer, (gl_FragCoord.xy - offset*strength)/screenSize);

	gl_FragColor = c*gl_Color;
}