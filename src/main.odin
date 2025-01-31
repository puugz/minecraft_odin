package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "vendor:glfw"
import glfw_bindings "vendor:glfw/bindings"
import rl "vendor:raylib"
import gl "vendor:raylib/rlgl"
import im "imgui"
import imgui_impl_glfw "imgui/glfw"
import imgui_impl_opengl3 "imgui/opengl3"

DISABLE_DOCKING :: #config(DISABLE_DOCKING, false)

WIDTH  :: #config(WIDTH,  1280)
HEIGHT :: #config(HEIGHT, 720)

RED      :: Color{ 230,  41,  55, 255 }
RAYWHITE :: Color{ 245, 245, 245, 255 }
DARKGRAY :: Color{  80,  80,  80, 255 }

WindowHandle  :: glfw_bindings.WindowHandle
MonitorHandle :: glfw_bindings.MonitorHandle

Vector3      :: rl.Vector3
Vector2      :: rl.Vector2
Color        :: rl.Color

state := struct {
  width, height: i32,
  using options: struct {
    scale:     bool,
    wireframe: bool,
    wave:      bool,
    grid:      bool,
  }
} {
  width  = WIDTH,
  height = HEIGHT,
  options = {
    wave = true,
    grid = true,
  }
}

Camera :: struct {
  using pos:  Vector3,
  target, up: Vector3,
  fovy:       f32,
  projection: int,
}

draw_rectangle_v :: proc(pos, size: Vector2, color: Color) {
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

  for i in -half_slices..=half_slices {
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

draw_cube :: proc(pos: Vector3, width, height, length: f32, color: Color) {
  x, y, z: f32 = 0.0, 0.0, 0.0

  gl.PushMatrix()

  // NOTE: Be careful! Function order matters (rotate -> scale -> translate)
  gl.Translatef(pos.x, pos.y, pos.z)
  //gl.Scalef(2.0f, 2.0f, 2.0f);
  //gl.Rotatef(45, 0, 1, 0);

  gl.Begin(gl.TRIANGLES)
  gl.Color4ub(color.r, color.g, color.b, color.a)

  // Front Face -----------------------------------------------------
  gl.Vertex3f(x - width / 2, y - height / 2, z + length / 2)  // Bottom Left
  gl.Vertex3f(x + width / 2, y - height / 2, z + length / 2)  // Bottom Right
  gl.Vertex3f(x - width / 2, y + height / 2, z + length / 2)  // Top Left

  gl.Vertex3f(x + width / 2, y + height / 2, z + length / 2)  // Top Right
  gl.Vertex3f(x - width / 2, y + height / 2, z + length / 2)  // Top Left
  gl.Vertex3f(x + width / 2, y - height / 2, z + length / 2)  // Bottom Right

  // Back Face ------------------------------------------------------
  gl.Vertex3f(x - width / 2, y - height / 2, z - length / 2)  // Bottom Left
  gl.Vertex3f(x - width / 2, y + height / 2, z - length / 2)  // Top Left
  gl.Vertex3f(x + width / 2, y - height / 2, z - length / 2)  // Bottom Right

  gl.Vertex3f(x + width / 2, y + height / 2, z - length / 2)  // Top Right
  gl.Vertex3f(x + width / 2, y - height / 2, z - length / 2)  // Bottom Right
  gl.Vertex3f(x - width / 2, y + height / 2, z - length / 2)  // Top Left

  // Top Face -------------------------------------------------------
  gl.Vertex3f(x - width / 2, y + height / 2, z - length / 2)  // Top Left
  gl.Vertex3f(x - width / 2, y + height / 2, z + length / 2)  // Bottom Left
  gl.Vertex3f(x + width / 2, y + height / 2, z + length / 2)  // Bottom Right

  gl.Vertex3f(x + width / 2, y + height / 2, z - length / 2)  // Top Right
  gl.Vertex3f(x - width / 2, y + height / 2, z - length / 2)  // Top Left
  gl.Vertex3f(x + width / 2, y + height / 2, z + length / 2)  // Bottom Right

  // Bottom Face ----------------------------------------------------
  gl.Vertex3f(x - width / 2, y - height / 2, z - length / 2)  // Top Left
  gl.Vertex3f(x + width / 2, y - height / 2, z + length / 2)  // Bottom Right
  gl.Vertex3f(x - width / 2, y - height / 2, z + length / 2)  // Bottom Left

  gl.Vertex3f(x + width / 2, y - height / 2, z - length / 2)  // Top Right
  gl.Vertex3f(x + width / 2, y - height / 2, z + length / 2)  // Bottom Right
  gl.Vertex3f(x - width / 2, y - height / 2, z - length / 2)  // Top Left

  // Right face -----------------------------------------------------
  gl.Vertex3f(x + width / 2, y - height / 2, z - length / 2)  // Bottom Right
  gl.Vertex3f(x + width / 2, y + height / 2, z - length / 2)  // Top Right
  gl.Vertex3f(x + width / 2, y + height / 2, z + length / 2)  // Top Left

  gl.Vertex3f(x + width / 2, y - height / 2, z + length / 2)  // Bottom Left
  gl.Vertex3f(x + width / 2, y - height / 2, z - length / 2)  // Bottom Right
  gl.Vertex3f(x + width / 2, y + height / 2, z + length / 2)  // Top Left

  // Left Face ------------------------------------------------------
  gl.Vertex3f(x - width / 2, y - height / 2, z - length / 2)  // Bottom Right
  gl.Vertex3f(x - width / 2, y + height / 2, z + length / 2)  // Top Left
  gl.Vertex3f(x - width / 2, y + height / 2, z - length / 2)  // Top Right

  gl.Vertex3f(x - width / 2, y - height / 2, z + length / 2)  // Bottom Left
  gl.Vertex3f(x - width / 2, y + height / 2, z + length / 2)  // Top Left
  gl.Vertex3f(x - width / 2, y - height / 2, z - length / 2)  // Bottom Right

  gl.End()
  gl.PopMatrix()
}

draw_cube_wires :: proc(pos: Vector3, width, height, length: f32, color: Color) {
  x, y, z: f32 = 0.0, 0.0, 0.0

  gl.PushMatrix()

  gl.Translatef(pos.x, pos.y, pos.z)
  //gl.Rotatef(45, 0, 1, 0);

  gl.Begin(gl.LINES)
  gl.Color4ub(color.r, color.g, color.b, color.a)

  // Front Face -----------------------------------------------------
  // Bottom Line
  gl.Vertex3f(x - width / 2, y - height / 2, z + length / 2)  // Bottom Left
  gl.Vertex3f(x + width / 2, y - height / 2, z + length / 2)  // Bottom Right

  // Left Line
  gl.Vertex3f(x + width / 2, y - height / 2, z + length / 2)  // Bottom Right
  gl.Vertex3f(x + width / 2, y + height / 2, z + length / 2)  // Top Right

  // Top Line
  gl.Vertex3f(x + width / 2, y + height / 2, z + length / 2)  // Top Right
  gl.Vertex3f(x - width / 2, y + height / 2, z + length / 2)  // Top Left

  // Right Line
  gl.Vertex3f(x - width / 2, y + height / 2, z + length / 2)  // Top Left
  gl.Vertex3f(x - width / 2, y - height / 2, z + length / 2)  // Bottom Left

  // Back Face ------------------------------------------------------
  // Bottom Line
  gl.Vertex3f(x - width / 2, y - height / 2, z - length / 2)  // Bottom Left
  gl.Vertex3f(x + width / 2, y - height / 2, z - length / 2)  // Bottom Right

  // Left Line
  gl.Vertex3f(x + width / 2, y - height / 2, z - length / 2)  // Bottom Right
  gl.Vertex3f(x + width / 2, y + height / 2, z - length / 2)  // Top Right

  // Top Line
  gl.Vertex3f(x + width / 2, y + height / 2, z - length / 2)  // Top Right
  gl.Vertex3f(x - width / 2, y + height / 2, z - length / 2)  // Top Left

  // Right Line
  gl.Vertex3f(x - width / 2, y + height / 2, z - length / 2)  // Top Left
  gl.Vertex3f(x - width / 2, y - height / 2, z - length / 2)  // Bottom Left

  // Top Face -------------------------------------------------------
  // Left Line
  gl.Vertex3f(x - width / 2, y + height / 2, z + length / 2)  // Top Left Front
  gl.Vertex3f(x - width / 2, y + height / 2, z - length / 2)  // Top Left Back

  // Right Line
  gl.Vertex3f(x + width / 2, y + height / 2, z + length / 2)  // Top Right Front
  gl.Vertex3f(x + width / 2, y + height / 2, z - length / 2)  // Top Right Back

  // Bottom Face  ---------------------------------------------------
  // Left Line
  gl.Vertex3f(x - width / 2, y - height / 2, z + length / 2)  // Top Left Front
  gl.Vertex3f(x - width / 2, y - height / 2, z - length / 2)  // Top Left Back

  // Right Line
  gl.Vertex3f(x + width / 2, y - height / 2, z + length / 2)  // Top Right Front
  gl.Vertex3f(x + width / 2, y - height / 2, z - length / 2)  // Top Right Back
  
  gl.End()
  gl.PopMatrix()
}

on_window_resized :: proc "c" (window: WindowHandle, width, height: i32) {
  if width == 0 || height == 0 {
    return
  }

  state.width     = width
  state.height    = height
  gl.Viewport(0, 0, width, height)
}

// MARK:main
main :: proc() {
  assert(cast(bool) glfw.Init(), "GLFW: Could not initialize.")
  defer glfw.Terminate()

  glfw.WindowHint(glfw.SAMPLES, 4)
  glfw.WindowHint(glfw.DEPTH_BITS, 16)

  glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
  glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
  glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
  when ODIN_DEBUG {
    glfw.WindowHint(glfw.OPENGL_DEBUG_CONTEXT, true)
  }

  width:  i32 = WIDTH
  height: i32 = HEIGHT

  window := glfw.CreateWindow(width, height, "balls", nil, nil)
  assert(window != nil, "GLFW: Could not create window.")
  defer glfw.DestroyWindow(window)

  glfw.MakeContextCurrent(window)
  glfw.SwapInterval(1)

  glfw.SetWindowSizeCallback(window, on_window_resized)

  gl.LoadExtensions(cast(rawptr) glfw.GetProcAddress)

  // MARK:init imgui
  im.CHECKVERSION()
  im.CreateContext()
  defer im.DestroyContext()
  io := im.GetIO()
  io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}
  when !DISABLE_DOCKING {
    io.ConfigFlags += {.DockingEnable, .ViewportsEnable}

    style := im.GetStyle()
    style.WindowRounding = 0
    style.Colors[im.Col.WindowBg].w = 1
  }

  im.StyleColorsDark()

  imgui_impl_glfw.InitForOpenGL(window, true)
  defer imgui_impl_glfw.Shutdown()
  imgui_impl_opengl3.Init()
  defer imgui_impl_opengl3.Shutdown()

  // MARK:init rlgl
  gl.Init(width, height)
  defer gl.Close()

  gl.Viewport(0, 0, width, height)
  gl.MatrixMode(gl.PROJECTION)
  gl.LoadIdentity()
  gl.Ortho(0, cast(f64) width, cast(f64) height, 0, 0.0, 1.0)
  gl.MatrixMode(gl.MODELVIEW)
  gl.LoadIdentity()

  gl.ClearColor(54, 56, 64, 255)
  gl.EnableDepthTest()

  camera := Camera{}
  camera.pos    = { 50.0, 50.0, -50.0 }
  camera.target = { 0.0, -35.0, 0.0 }
  camera.up     = { 0.0, 1.0, 0.0 }
  camera.fovy   = 90.0

  time      := 0.0
  last_time := 0.0
  angle: f32 = 0.0

  scale: f32 = 2
  color := Color{255, 255, 255, 255}

  // MARK:loop
  for !glfw.WindowShouldClose(window) {
    minimized := glfw.GetWindowAttrib(window, glfw.ICONIFIED)

    if cast(bool) minimized {
      glfw.WaitEvents()
      continue
    }

    glfw.PollEvents()
    gl.ClearScreenBuffers()

    if state.wireframe {
      gl.EnableWireMode()
    } else {
      gl.DisableWireMode()
    }

    current_time := glfw.GetTime()
    delta_time   := current_time - last_time
    last_time     = current_time
    time         += delta_time

    {
      color.r = cast(u8) ((math.sin(time) * 127.5 + 127.5))
      color.g = cast(u8) ((math.sin(time + 2.0) * 127.5 + 127.5))
      color.b = cast(u8) ((math.sin(time + 4.0) * 127.5 + 127.5))
    }

    aspect_ratio := state.width / state.height
    mat_proj     := rl.MatrixPerspective(camera.fovy * rl.DEG2RAD, auto_cast aspect_ratio, 0.01, 1000.0)
    mat_view     := rl.MatrixLookAt(camera.pos, camera.target, camera.up)

    gl.SetMatrixModelview(mat_view)
    gl.SetMatrixProjection(mat_proj)

    ROTATION_SPEED :: 600.0
    angle += auto_cast (ROTATION_SPEED * delta_time)

    SPACING :: 5
    if state.scale {
      scale = math.sin_f32(auto_cast time) + 1
    }

    for x in 0..=20 {
      for z in 0..=20 {
        y_offset: f32
        if state.wave {
          y_offset = auto_cast (math.sin(time * 16 + f64(x) * 0.5 + f64(z) * 0.5)) * 2.0 + 5
        }

        // col := Color{
        //   cast(u8) (x * 13 + z * 17) % 255,
        //   cast(u8) (x * 23 + z * 29) % 255,
        //   cast(u8) (x * 31 + z * 37) % 255,
        //   255
        // }

        col: Color
        col.r = cast(u8) ((math.sin(time + f64(x) + f64(z))       * 127.5 + 127.5))
        col.g = cast(u8) ((math.sin(time + f64(x) + f64(z) + 2.0) * 127.5 + 127.5))
        col.b = cast(u8) ((math.sin(time + f64(x) + f64(z) + 4.0) * 127.5 + 127.5))
        col.a = 255

        gl.PushMatrix()
        gl.Translatef(-50, 0, -50)
        gl.Translatef(cast(f32)x * SPACING, y_offset, cast(f32)z * SPACING)
        // gl.Rotatef(angle, 1, 1, 1)
        gl.Scalef(scale, scale, scale)
        
        draw_cube({0, 0, 0}, 2.0, 2.0, 2.0, col)
        
        gl.PopMatrix()
      }
    }

    // draw_cube_wires(cube_position, 2.0, 2.0, 2.0, RAYWHITE)
    if state.grid {
      draw_grid(100, 1.0)
    }

    gl.DrawRenderBatchActive()

// #define RLGL_SET_MATRIX_MANUALLY
// #if defined(RLGL_SET_MATRIX_MANUALLY)
//     matProj = MatrixOrtho(0.0, screenWidth, screenHeight, 0.0, 0.0, 1.0)
//     matView = MatrixIdentity()
//     rlSetMatrixModelview(matView)    // Set internal modelview matrix (default shader)
//     rlSetMatrixProjection(matProj)   // Set internal projection matrix (default shader)
// #else   // Let rlgl generate and multiply matrix internally
    gl.MatrixMode(gl.PROJECTION)
    gl.LoadIdentity()
    gl.Ortho(0.0, auto_cast state.width, auto_cast state.height, 0.0, 0.0, 1.0)
    gl.MatrixMode(gl.MODELVIEW)
    gl.LoadIdentity()
// #endif
    
    // MARK:2D
    // draw_rectangle_v(Vector2{10.0, 10.}, Vector2{780.0, 20.0}, DARKGRAY)
    
    gl.DrawRenderBatchActive()

    // MARK:imgui
    imgui_impl_opengl3.NewFrame()
    imgui_impl_glfw.NewFrame()
    im.NewFrame()
    im.ShowDemoWindow()

    if im.Begin("Options") {
      im.Checkbox("Scale", &state.scale)
      im.Checkbox("Wireframe", &state.wireframe)
      im.Checkbox("Wave", &state.wave)
      im.Checkbox("Grid", &state.grid)
    }
    im.End()

    im.Render()
    imgui_impl_opengl3.RenderDrawData(im.GetDrawData())

    when !DISABLE_DOCKING {
      backup_current_window := glfw.GetCurrentContext()
      im.UpdatePlatformWindows()
      im.RenderPlatformWindowsDefault()
      glfw.MakeContextCurrent(backup_current_window)
    }

    glfw.SwapBuffers(window)
  }

  a := 5
}
