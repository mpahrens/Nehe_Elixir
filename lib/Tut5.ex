defmodule Tut5 do

  @behaviour :wx_object


  require Record
  require WxMacros
  require Logger
  WxMacros.wx_macros

  Record.defrecord :state, [parent: :undefined,
          config: :undefined,
          canvas: :undefined,
          timer: :undefined,
          time: :undefined,
          triangle_rot: 10,
          square_rot: 10]
  Record.extract_all(from_lib: "wx/include/wx.hrl")
  |> Enum.map(fn {id, args} -> Record.defrecord id, args end)

  def start(config) do
    :wx_object.start_link(__MODULE__, config, [])
  end

  def init(config) do
    :wx.batch(fn() -> do_init(config) end)
  end

  def do_init(config) do
    parent = :proplists.get_value(:parent, config)
    size = :proplists.get_value(:size, config)
    opts = [{:size, size}, {:style, @wxSUNKEN_BORDER}]
    gLAttrib = [{:attribList, [@wx_GL_RGBA,
                              @wx_GL_DOUBLEBUFFER,
                              @wx_GL_MIN_RED, 8,
                              @wx_GL_MIN_GREEN, 8,
                              @wx_GL_MIN_BLUE, 8,
                              @wx_GL_DEPTH_SIZE, 24, 0]}]
    canvas = :wxGLCanvas.new(parent, opts ++ gLAttrib)
    :wxGLCanvas.connect(canvas, :size)
    :wxWindow.hide(parent)
    :wxWindow.reparent(canvas, parent)
    :wxWindow.show(parent)
    :wxGLCanvas.setCurrent(canvas)
    setup_gl(canvas)
    timer = :timer.send_interval(20, self(), :update)
    {parent, state(parent: parent, config: config, canvas: canvas, timer: timer)}
  end

  def handle_event(wx_rec, s) do
    event = wx(wx_rec, :event)
    size = if Record.is_record(event, :wxSize), do: wxSize(event, :size) #{w,h}
    case size do
      {0,_} -> :skip
      {_,0} -> :skip
      {w,h} ->
        :wxGLCanvas.setCurrent(state(s,:canvas))
        resize_gl_scene(w,h)
      _ -> :skip
    end
    {:noreply, s}
  end

  def handle_info(:update, s) do
    new_s = :wx.batch(fn() -> render(s) end)
    {:noreply, new_s}
  end

  def handle_info(:stop, s) do
    :timer.cancel(state(state,:timer))
    try do
      :wxGLCanvas.destroy(state(s,:canvas))
    rescue
      _ -> :ok
    end
    {:stop, :normal, state}
  end

  def handle_call(msg, _from, s) do
    :io.format('Call: ~p~n', [msg])
    {:reply, :ok, s}
  end

  def code_change(_, _, s) do
    {:stop, :not_yet_implemented, s}
  end

  def terminate(_reason, s) do
    try do
      :wxGLCanvas.destroy(state(s,:canvas))
    rescue
      _ -> :ok
    end
    :timer.cancel(state(s,:timer))
    :timer.sleep(300)
  end

  def resize_gl_scene(w,h) do
    :gl.matrixMode(@gl_PROJECTION)
    :gl.loadIdentity()
    :gl.viewport(0, 0, w, h)
    :glu.perspective(45.0, w / h, 0.1, 100.0)
    :gl.matrixMode(@gl_MODELVIEW)
    :gl.loadIdentity()
  end
  def setup_gl(win) do
    {w, h} = :wxWindow.getClientSize(win)
    resize_gl_scene(w,h)
    :gl.shadeModel(@gl_SMOOTH)
    :gl.clearColor(0.0, 0.0, 0.0, 0.0)
    :gl.clearDepth(1.0)
    :gl.enable(@gl_DEPTH_TEST)
    :gl.depthFunc(@gl_LEQUAL)
    :gl.hint(@gl_PERSPECTIVE_CORRECTION_HINT, @gl_NICEST)
    :ok
  end
  def render(s) do #state{parent = _Window, canvas = Canvas} = _State) ->
    canvas = state(s, :canvas)
    new_s = draw(s)
    :wxGLCanvas.swapBuffers(canvas)
    new_s
  end

  def draw(s) do
    triangleRot = state(s, :triangle_rot)
    squareRot = state(s, :square_rot)
    :gl.clear(Bitwise.bor(@gl_COLOR_BUFFER_BIT, @gl_DEPTH_BUFFER_BIT))
    :gl.loadIdentity()
    :gl.translatef(-1.5, 0.0, -6.0)

    # pyramid
    :gl.rotatef(triangleRot, 0.0, 1.0, 0.0)
    :gl.begin(@gl_TRIANGLES)

    # front
    :gl.color3f(  1.0,  0.0, 0.0)
    :gl.vertex3f( 0.0,  1.0, 0.0)
    :gl.color3f(  0.0,  1.0, 0.0)
    :gl.vertex3f(-1.0, -1.0, 1.0)
    :gl.color3f(  0.0,  0.0, 1.0)
    :gl.vertex3f( 1.0, -1.0, 1.0)

    # right
    :gl.color3f(  1.0,  0.0,  0.0)
    :gl.vertex3f( 0.0,  1.0,  0.0)
    :gl.color3f(  0.0,  1.0,  0.0)
    :gl.vertex3f( 1.0, -1.0,  1.0)
    :gl.color3f(  0.0,  0.0,  1.0)
    :gl.vertex3f( 1.0, -1.0, -1.0)

    # back
    :gl.color3f(  1.0,  0.0,  0.0)
    :gl.vertex3f( 0.0,  1.0,  0.0)
    :gl.color3f(  0.0,  1.0,  0.0)
    :gl.vertex3f( 1.0, -1.0, -1.0)
    :gl.color3f(  0.0,  0.0,  1.0)
    :gl.vertex3f(-1.0, -1.0, -1.0)

    # left
    :gl.color3f(  1.0,  0.0,  0.0)
    :gl.vertex3f( 0.0,  1.0,  0.0)
    :gl.color3f(  0.0,  1.0,  0.0)
    :gl.vertex3f(-1.0, -1.0, -1.0)
    :gl.color3f(  0.0,  0.0,  1.0)
    :gl.vertex3f(-1.0, -1.0,  1.0)
    :gl.end()

    :gl.loadIdentity()
    :gl.translatef(1.5, 0.0, -7.0)

    # cube
    :gl.rotatef(squareRot, 1.0, 1.0, 1.0)
    :gl.begin(@gl_QUADS)

    # top
    :gl.color3f(0.0, 1.0, 0.0)
    :gl.vertex3f( 1.0, 1.0, -1.0)
    :gl.vertex3f(-1.0, 1.0, -1.0)
    :gl.vertex3f(-1.0, 1.0,  1.0)
    :gl.vertex3f( 1.0, 1.0,  1.0)

    # bottom
    :gl.color3f(1.0, 0.5, 0.0)
    :gl.vertex3f( 1.0, -1.0, 1.0)
    :gl.vertex3f(-1.0, -1.0,  1.0)
    :gl.vertex3f(-1.0, -1.0, -1.0)
    :gl.vertex3f( 1.0, -1.0, -1.0)

    # front
    :gl.color3f(1.0, 0.0, 0.0)
    :gl.vertex3f( 1.0,  1.0,  1.0)
    :gl.vertex3f(-1.0,  1.0,  1.0)
    :gl.vertex3f(-1.0, -1.0,  1.0)
    :gl.vertex3f( 1.0, -1.0,  1.0)

    # back
    :gl.color3f(1.0, 1.0, 0.0)
    :gl.vertex3f( 1.0, -1.0, -1.0)
    :gl.vertex3f(-1.0, -1.0, -1.0)
    :gl.vertex3f(-1.0,  1.0, -1.0)
    :gl.vertex3f( 1.0,  1.0, -1.0)

    # left
    :gl.color3f(0.0, 0.0, 1.0)
    :gl.vertex3f(-1.0,  1.0,  1.0)
    :gl.vertex3f(-1.0,  1.0, -1.0)
    :gl.vertex3f(-1.0, -1.0, -1.0)
    :gl.vertex3f(-1.0, -1.0,  1.0)

    # right
    :gl.color3f(1.0, 0.0, 1.0)
    :gl.vertex3f( 1.0,  1.0, -1.0)
    :gl.vertex3f( 1.0,  1.0,  1.0)
    :gl.vertex3f( 1.0, -1.0,  1.0)
    :gl.vertex3f( 1.0, -1.0, -1.0)
    :gl.end()
    :gl.flush()
    state(s, triangle_rot: triangleRot + 0.2, square_rot: squareRot - 0.15)
  end
end
