package main

import gl "vendor:raylib/rlgl"

draw_rectangle_v :: proc(pos, size: vec2, color: Color) {
  gl.Begin(gl.TRIANGLES)
  defer gl.End()

  gl.Color4ub(color.r, color.g, color.b, color.a)

  gl.Vertex2f(pos.x, pos.y)
  gl.Vertex2f(pos.x, pos.y + size.y)
  gl.Vertex2f(pos.x + size.x, pos.y + size.y)

  gl.Vertex2f(pos.x, pos.y)
  gl.Vertex2f(pos.x + size.x, pos.y + size.y)
  gl.Vertex2f(pos.x + size.x, pos.y)
}

draw_grid :: proc(slices: int, spacing: f32) {
  half_slices := slices / 2

  gl.Begin(gl.LINES)
  defer gl.End()

  for i in -half_slices ..= half_slices {
    if i == 0 {
      gl.Color3f(0.5, 0.5, 0.5)
      gl.Color3f(0.5, 0.5, 0.5)
      gl.Color3f(0.5, 0.5, 0.5)
      gl.Color3f(0.5, 0.5, 0.5)
    } else {
      gl.Color3f(0.75, 0.75, 0.75)
      gl.Color3f(0.75, 0.75, 0.75)
      gl.Color3f(0.75, 0.75, 0.75)
      gl.Color3f(0.75, 0.75, 0.75)
    }

    gl.Vertex3f(cast(f32)i * spacing, 0.0, cast(f32)-half_slices * spacing)
    gl.Vertex3f(cast(f32)i * spacing, 0.0, cast(f32) half_slices * spacing)

    gl.Vertex3f(cast(f32)-half_slices * spacing, 0.0, cast(f32)i * spacing)
    gl.Vertex3f(cast(f32) half_slices * spacing, 0.0, cast(f32)i * spacing)
  }
}

draw_cube :: proc(pos: vec3, w, h, len: f32, color: Color) {
  x, y, z: f32 = 0.0, 0.0, 0.0

  gl.PushMatrix()

  // NOTE: Be careful! Function order matters (rotate -> scale -> translate)
  gl.Translatef(pos.x, pos.y, pos.z)
  //gl.Scalef(2.0f, 2.0f, 2.0f);
  //gl.Rotatef(45, 0, 1, 0);

  gl.Begin(gl.TRIANGLES)
  gl.Color4ub(color.r, color.g, color.b, color.a)

  // Front Face -----------------------------------------------------
  gl.Vertex3f(x - w / 2, y - h / 2, z + len / 2)  // Bottom Left
  gl.Vertex3f(x + w / 2, y - h / 2, z + len / 2)  // Bottom Right
  gl.Vertex3f(x - w / 2, y + h / 2, z + len / 2)  // Top Left

  gl.Vertex3f(x + w / 2, y + h / 2, z + len / 2)  // Top Right
  gl.Vertex3f(x - w / 2, y + h / 2, z + len / 2)  // Top Left
  gl.Vertex3f(x + w / 2, y - h / 2, z + len / 2)  // Bottom Right

  // Back Face ------------------------------------------------------
  gl.Vertex3f(x - w / 2, y - h / 2, z - len / 2)  // Bottom Left
  gl.Vertex3f(x - w / 2, y + h / 2, z - len / 2)  // Top Left
  gl.Vertex3f(x + w / 2, y - h / 2, z - len / 2)  // Bottom Right

  gl.Vertex3f(x + w / 2, y + h / 2, z - len / 2)  // Top Right
  gl.Vertex3f(x + w / 2, y - h / 2, z - len / 2)  // Bottom Right
  gl.Vertex3f(x - w / 2, y + h / 2, z - len / 2)  // Top Left

  // Top Face -------------------------------------------------------
  gl.Vertex3f(x - w / 2, y + h / 2, z - len / 2)  // Top Left
  gl.Vertex3f(x - w / 2, y + h / 2, z + len / 2)  // Bottom Left
  gl.Vertex3f(x + w / 2, y + h / 2, z + len / 2)  // Bottom Right

  gl.Vertex3f(x + w / 2, y + h / 2, z - len / 2)  // Top Right
  gl.Vertex3f(x - w / 2, y + h / 2, z - len / 2)  // Top Left
  gl.Vertex3f(x + w / 2, y + h / 2, z + len / 2)  // Bottom Right

  // Bottom Face ----------------------------------------------------
  gl.Vertex3f(x - w / 2, y - h / 2, z - len / 2)  // Top Left
  gl.Vertex3f(x + w / 2, y - h / 2, z + len / 2)  // Bottom Right
  gl.Vertex3f(x - w / 2, y - h / 2, z + len / 2)  // Bottom Left

  gl.Vertex3f(x + w / 2, y - h / 2, z - len / 2)  // Top Right
  gl.Vertex3f(x + w / 2, y - h / 2, z + len / 2)  // Bottom Right
  gl.Vertex3f(x - w / 2, y - h / 2, z - len / 2)  // Top Left

  // Right face -----------------------------------------------------
  gl.Vertex3f(x + w / 2, y - h / 2, z - len / 2)  // Bottom Right
  gl.Vertex3f(x + w / 2, y + h / 2, z - len / 2)  // Top Right
  gl.Vertex3f(x + w / 2, y + h / 2, z + len / 2)  // Top Left

  gl.Vertex3f(x + w / 2, y - h / 2, z + len / 2)  // Bottom Left
  gl.Vertex3f(x + w / 2, y - h / 2, z - len / 2)  // Bottom Right
  gl.Vertex3f(x + w / 2, y + h / 2, z + len / 2)  // Top Left

  // Left Face ------------------------------------------------------
  gl.Vertex3f(x - w / 2, y - h / 2, z - len / 2)  // Bottom Right
  gl.Vertex3f(x - w / 2, y + h / 2, z + len / 2)  // Top Left
  gl.Vertex3f(x - w / 2, y + h / 2, z - len / 2)  // Top Right

  gl.Vertex3f(x - w / 2, y - h / 2, z + len / 2)  // Bottom Left
  gl.Vertex3f(x - w / 2, y + h / 2, z + len / 2)  // Top Left
  gl.Vertex3f(x - w / 2, y - h / 2, z - len / 2)  // Bottom Right

  gl.End()
  gl.PopMatrix()
}

draw_cube_wires :: proc(pos: vec3, w, h, len: f32, color: Color) {
  x, y, z: f32 = 0.0, 0.0, 0.0

  gl.PushMatrix()

  gl.Translatef(pos.x, pos.y, pos.z)
  //gl.Rotatef(45, 0, 1, 0);

  gl.Begin(gl.LINES)
  gl.Color4ub(color.r, color.g, color.b, color.a)

  // Front Face -----------------------------------------------------
  // Bottom Line
  gl.Vertex3f(x - w / 2, y - h / 2, z + len / 2)  // Bottom Left
  gl.Vertex3f(x + w / 2, y - h / 2, z + len / 2)  // Bottom Right

  // Left Line
  gl.Vertex3f(x + w / 2, y - h / 2, z + len / 2)  // Bottom Right
  gl.Vertex3f(x + w / 2, y + h / 2, z + len / 2)  // Top Right

  // Top Line
  gl.Vertex3f(x + w / 2, y + h / 2, z + len / 2)  // Top Right
  gl.Vertex3f(x - w / 2, y + h / 2, z + len / 2)  // Top Left

  // Right Line
  gl.Vertex3f(x - w / 2, y + h / 2, z + len / 2)  // Top Left
  gl.Vertex3f(x - w / 2, y - h / 2, z + len / 2)  // Bottom Left

  // Back Face ------------------------------------------------------
  // Bottom Line
  gl.Vertex3f(x - w / 2, y - h / 2, z - len / 2)  // Bottom Left
  gl.Vertex3f(x + w / 2, y - h / 2, z - len / 2)  // Bottom Right

  // Left Line
  gl.Vertex3f(x + w / 2, y - h / 2, z - len / 2)  // Bottom Right
  gl.Vertex3f(x + w / 2, y + h / 2, z - len / 2)  // Top Right

  // Top Line
  gl.Vertex3f(x + w / 2, y + h / 2, z - len / 2)  // Top Right
  gl.Vertex3f(x - w / 2, y + h / 2, z - len / 2)  // Top Left

  // Right Line
  gl.Vertex3f(x - w / 2, y + h / 2, z - len / 2)  // Top Left
  gl.Vertex3f(x - w / 2, y - h / 2, z - len / 2)  // Bottom Left

  // Top Face -------------------------------------------------------
  // Left Line
  gl.Vertex3f(x - w / 2, y + h / 2, z + len / 2)  // Top Left Front
  gl.Vertex3f(x - w / 2, y + h / 2, z - len / 2)  // Top Left Back

  // Right Line
  gl.Vertex3f(x + w / 2, y + h / 2, z + len / 2)  // Top Right Front
  gl.Vertex3f(x + w / 2, y + h / 2, z - len / 2)  // Top Right Back

  // Bottom Face  ---------------------------------------------------
  // Left Line
  gl.Vertex3f(x - w / 2, y - h / 2, z + len / 2)  // Top Left Front
  gl.Vertex3f(x - w / 2, y - h / 2, z - len / 2)  // Top Left Back

  // Right Line
  gl.Vertex3f(x + w / 2, y - h / 2, z + len / 2)  // Top Right Front
  gl.Vertex3f(x + w / 2, y - h / 2, z - len / 2)  // Top Right Back
  
  gl.End()
  gl.PopMatrix()
}
