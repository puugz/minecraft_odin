package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "vendor:glfw"
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

vec2  :: [2]f32
vec3  :: [3]f32
vec4  :: [4]f32

VEC3_RIGHT   :: vec3{1, 0, 0}
VEC3_UP      :: vec3{0, 1, 0}
VEC3_FORWARD :: vec3{0, 0, 1}

Color :: rl.Color

state := struct {
  window:        glfw.WindowHandle,
  width, height: i32,
  
  using options: struct {
    scale:     bool,
    wireframe: bool,
    wave:      bool,
    grid:      bool,
  },
} {
  width  = WIDTH,
  height = HEIGHT,
  options = {
    wave = true,
    grid = true,
  }
}

Camera :: struct {
  using pos: vec3,
  vel, dir:  vec3,
  right, up: vec3,
  
  yaw, pitch:     f32,
  fov, near, far: f32,
}

on_window_resized :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
  if width != 0 && height != 0 {
    state.width  = width
    state.height = height
    gl.Viewport(0, 0, width, height)
  }
}

key_pressed :: proc(key: i32) -> bool {
  return glfw.GetKey(state.window, key) == glfw.PRESS
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

  window := glfw.CreateWindow(WIDTH, HEIGHT, "balls", nil, nil)
  assert(window != nil, "GLFW: Could not create window.")
  defer glfw.DestroyWindow(window)
  state.window = window

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
  gl.Init(WIDTH, HEIGHT)
  defer gl.Close()

  gl.Viewport(0, 0, WIDTH, HEIGHT)
  gl.MatrixMode(gl.PROJECTION)
  gl.LoadIdentity()
  gl.Ortho(0, WIDTH, HEIGHT, 0, 0.0, 1.0)
  gl.MatrixMode(gl.MODELVIEW)
  gl.LoadIdentity()

  gl.ClearColor(54, 56, 64, 255)
  gl.EnableDepthTest()

  camera := Camera{}
  camera.pos   = { 0, 50, -110 }
  camera.right = VEC3_RIGHT
  camera.up    = VEC3_UP
  camera.dir   = VEC3_FORWARD
  camera.yaw   = -90

  camera.fov   = 90
  camera.near  = 0.01
  camera.far   = 1000.0

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
    
    current_time := glfw.GetTime()
    delta_time   := current_time - last_time
    last_time     = current_time
    time         += delta_time

    // camera movement
    {
      ACCELERATION :: 300
      MAX_SPEED    :: 200
      DAMPING      :: 10

      input: vec3
      if key_pressed(glfw.KEY_W)          do input += camera.dir
      if key_pressed(glfw.KEY_S)          do input -= camera.dir
      if key_pressed(glfw.KEY_D)          do input += camera.right
      if key_pressed(glfw.KEY_A)          do input -= camera.right
      if key_pressed(glfw.KEY_SPACE)      do input += camera.up
      if key_pressed(glfw.KEY_LEFT_SHIFT) do input -= camera.up

      if linalg.length(input) > 0 {
        input = linalg.normalize(input)
        camera.vel = input * math.min(MAX_SPEED, linalg.length(camera.vel) + ACCELERATION * auto_cast delta_time)
      } else {
        camera.vel -= camera.vel * (DAMPING * auto_cast delta_time)
        if linalg.length(camera.vel) < 0.01 {
          camera.vel = {0, 0, 0}
        }
      }
      
      camera.pos += camera.vel * auto_cast delta_time
    }
    
    gl.ClearScreenBuffers()

    if state.wireframe {
      gl.EnableWireMode()
    } else {
      gl.DisableWireMode()
    }

    aspect_ratio := state.width / state.height
    mat_proj     := rl.MatrixPerspective(camera.fov * rl.DEG2RAD, auto_cast aspect_ratio, 0.01, 1000.0)
    mat_view     := rl.MatrixLookAt(camera.pos, camera.pos + camera.dir, camera.up)

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
}
