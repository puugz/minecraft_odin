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

vec2 :: [2]f32
vec3 :: [3]f32
vec4 :: [4]f32
s16  :: i16
s32  :: i32
s64  :: i64

WORLD_RIGHT   :: vec3{1, 0, 0}
WORLD_UP      :: vec3{0, 1, 0}
WORLD_FORWARD :: vec3{0, 0, 1}

Color :: rl.Color

state := struct {
  window:        glfw.WindowHandle,
  width, height: s32,
  
  using options: struct {
    scale:     bool,
    wireframe: bool,
    wave:      bool,
    grid:      bool,
    ui_focus:  bool,
  },

  camera:    Camera,
  mouse_pos: vec2,
} {
  width  = WIDTH,
  height = HEIGHT,
  options = {
    wave = true,
    grid = true,
  }
}

Camera :: struct {
  using pos:           vec3,
  vel, dir, up, right: vec3,
  yaw, pitch, fov:     f32,
}

handle_window_resized :: proc "c" (window: glfw.WindowHandle, width, height: s32) {
  if width != 0 && height != 0 {
    state.width  = width
    state.height = height
    gl.Viewport(0, 0, width, height)
  }
}

handle_key_input :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: s32) {
  if key == glfw.KEY_ESCAPE && action == glfw.PRESS {
    state.ui_focus = !state.ui_focus
    set_ui_focus(window)
  }
}

handle_mouse_input :: proc "c" (window: glfw.WindowHandle, x, y: f64) {
  using state

  @(static) first_mouse_input := true
  if first_mouse_input {
    mouse_pos.x = cast(f32) x
    mouse_pos.y = cast(f32) y
    first_mouse_input = false
  }

  x_offset := cast(f32) x - mouse_pos.x
  y_offset := mouse_pos.y - cast(f32) y

  mouse_pos.x = cast(f32) x
  mouse_pos.y = cast(f32) y

  if !ui_focus {
    SENSITIVITY :: 0.1

    x_offset *= SENSITIVITY
    y_offset *= SENSITIVITY

    camera.yaw += x_offset

         if camera.yaw >  180 do camera.yaw = -180
    else if camera.yaw < -180 do camera.yaw =  180

    camera.pitch += y_offset
    camera.pitch = math.clamp(camera.pitch, -89.9, 89.9)

    yaw_rad   := camera.yaw   * rl.DEG2RAD
    pitch_rad := camera.pitch * rl.DEG2RAD

    camera.dir.x = math.cos(yaw_rad) * math.cos(pitch_rad)
    camera.dir.y = math.sin(pitch_rad)
    camera.dir.z = math.sin(yaw_rad) * math.cos(pitch_rad)
    
    camera.dir   = linalg.normalize(camera.dir)
    camera.right = linalg.normalize(linalg.cross(camera.dir, WORLD_UP))
    camera.up    = linalg.normalize(linalg.cross(camera.right, camera.dir))
  }
}

set_ui_focus :: proc "c" (window: glfw.WindowHandle) {
  cursor_state: s32 = state.ui_focus ? glfw.CURSOR_NORMAL : glfw.CURSOR_DISABLED
  glfw.SetInputMode(window, glfw.CURSOR, cursor_state)
}

key_pressed :: proc(key: s32) -> bool {
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

  state.window = glfw.CreateWindow(WIDTH, HEIGHT, "balls", nil, nil)
  assert(state.window != nil, "GLFW: Could not create window.")
  defer glfw.DestroyWindow(state.window)

  set_ui_focus(state.window)

  glfw.MakeContextCurrent(state.window)
  glfw.SwapInterval(1)

  glfw.SetWindowSizeCallback(state.window, handle_window_resized)
  glfw.SetCursorPosCallback(state.window, handle_mouse_input)
  glfw.SetKeyCallback(state.window, handle_key_input)

  gl.LoadExtensions(cast(rawptr) glfw.GetProcAddress)

  // MARK:init imgui
  im.CHECKVERSION()
  im.CreateContext()
  defer im.DestroyContext()
    
  style := im.GetStyle()
  style.WindowRounding = 4
  style.FrameRounding  = 4

  io := im.GetIO()
  io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}

  when !DISABLE_DOCKING {
    io.ConfigFlags += {.DockingEnable, .ViewportsEnable}

    style.Colors[im.Col.WindowBg].w = 1
  }

  im.FontAtlas_AddFontFromFileTTF(io.Fonts, "res/Hack-Regular.ttf", 16.0)
  im.StyleColorsDark()

  imgui_impl_glfw.InitForOpenGL(state.window, true)
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

  {
    state.camera.pos   = { 0, 50, 0 }
    state.camera.right = WORLD_RIGHT
    state.camera.up    = WORLD_UP
    state.camera.dir   = WORLD_FORWARD
    state.camera.fov   = 90
  }

  time      := 0.0
  last_time := 0.0
  angle: f32 = 0.0

  scale: f32 = 2
  color := Color{255, 255, 255, 255}

  // MARK:loop
  for !glfw.WindowShouldClose(state.window) {
    minimized := glfw.GetWindowAttrib(state.window, glfw.ICONIFIED)

    if cast(bool) minimized {
      glfw.WaitEvents()
      continue
    }

    glfw.PollEvents()

    io.WantCaptureMouse    = !state.ui_focus
    io.WantCaptureKeyboard = !state.ui_focus
    
    current_time := glfw.GetTime()
    delta_time   := current_time - last_time
    last_time     = current_time
    time         += delta_time

    // MARK:camera movement
    {
      ACCELERATION :: 300
      MAX_SPEED    :: 200
      DAMPING      :: 10

      input: vec3
      if key_pressed(glfw.KEY_W)          do input += state.camera.dir
      if key_pressed(glfw.KEY_S)          do input -= state.camera.dir
      if key_pressed(glfw.KEY_D)          do input += state.camera.right
      if key_pressed(glfw.KEY_A)          do input -= state.camera.right
      if key_pressed(glfw.KEY_SPACE)      do input += WORLD_UP
      if key_pressed(glfw.KEY_LEFT_SHIFT) do input -= WORLD_UP

      if linalg.length(input) > 0 {
        input = linalg.normalize(input)
        state.camera.vel = input * math.min(MAX_SPEED, linalg.length(state.camera.vel) + ACCELERATION * auto_cast delta_time)
      } else {
        state.camera.vel -= state.camera.vel * (DAMPING * auto_cast delta_time)
        if linalg.length(state.camera.vel) < 0.01 {
          state.camera.vel = {0, 0, 0}
        }
      }
      
      state.camera.pos += state.camera.vel * auto_cast delta_time
    }
    
    gl.ClearScreenBuffers()

    if state.wireframe {
      gl.EnableWireMode()
    } else {
      gl.DisableWireMode()
    }

    aspect_ratio := state.width / state.height
    mat_proj     := rl.MatrixPerspective(state.camera.fov * rl.DEG2RAD, auto_cast aspect_ratio, 0.01, 1000.0)
    mat_view     := rl.MatrixLookAt(state.camera.pos, state.camera.pos + state.camera.dir, state.camera.up)

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

    {
      XYZ_LINES_OFFSET :: vec3{0, 0, 0}
      draw_line(XYZ_LINES_OFFSET, {10, 0, 0}, {255,   0,   0, 255})
      draw_line(XYZ_LINES_OFFSET, {0, 10, 0}, {  0, 255,   0, 255})
      draw_line(XYZ_LINES_OFFSET, {0, 0, 10}, {  0,   0, 255, 255})
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

    if state.ui_focus {
      if im.Begin("Options") {
        im.Checkbox("Scale", &state.scale)
        im.Checkbox("Wireframe", &state.wireframe)
        im.Checkbox("Wave", &state.wave)
        im.Checkbox("Grid", &state.grid)
      }
      im.End()
    }  
  
    im.Render()
    imgui_impl_opengl3.RenderDrawData(im.GetDrawData())

    when !DISABLE_DOCKING {
      backup_current_window := glfw.GetCurrentContext()
      im.UpdatePlatformWindows()
      im.RenderPlatformWindowsDefault()
      glfw.MakeContextCurrent(backup_current_window)
    }

    glfw.SwapBuffers(state.window)
  }
}
