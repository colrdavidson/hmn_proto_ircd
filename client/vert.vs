#version 150
in vec2 coords;

void main() {
    gl_Position = vec4(coords, 0.0, 1.0);
}
