shader_type canvas_item;
uniform vec2 extent = vec2(300.0,100.0);
uniform float radius = 28.0;
uniform vec4 base_color : source_color = vec4(0.13,0.10,0.25,1.0);
uniform float emphasis = 0.0;
float rounded(vec2 p, vec2 b, float r) {
    vec2 q = abs(p)-b+vec2(r);
    return length(max(q,vec2(0.0)))+min(max(q.x,q.y),0.0)-r;
}
void fragment() {
    vec2 p = (UV-0.5)*extent;
    vec2 half_size = extent*0.5-vec2(6.0);
    float r = min(radius,min(half_size.x,half_size.y));
    float d = rounded(p,half_size,r);
    float inner = rounded(p,half_size-vec2(5.0),max(1.0,r-5.0));
    vec3 color = mix(base_color.rgb*1.40,base_color.rgb,UV.y);
    color += vec3(0.10,0.06,0.17)*emphasis;
    float gloss = exp(-pow((UV.y-0.10)*12.0,2.0))*(1.0-UV.x)*0.18;
    color += vec3(gloss);
    float ring = smoothstep(-2.0,0.0,inner);
    vec3 edge = mix(vec3(0.40,0.16,0.83),vec3(0.78,0.63,1.0),pow(1.0-UV.y,3.0));
    color = mix(color,edge,ring);
    color = mix(color,vec3(0.025,0.016,0.065),smoothstep(-2.0,0.0,d));
    float alpha = 1.0-smoothstep(0.0,1.2,d);
    COLOR = vec4(color,alpha);
}
