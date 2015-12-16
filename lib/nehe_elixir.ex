defmodule NeheElixir do
  @behaviour :wx_object
  #require Quaff.Constants
  require Record
  require WxMacros
  WxMacros.wx_macros
#  Quaff.Constants.include_lib("wx/include/wx.hrl")
#  Quaff.Constants.include_lib("wx/include/gl.hrl")
#  Quaff.Constants.include_lib("wx/include/glu.hrl")

  Record.defrecord :state, [win: :undefined, object: :undefined]
  Record.extract_all(from_lib: "wx/include/wx.hrl")
  |> Enum.map(fn {id, args} -> Record.defrecord id, args end)

  def start_link() do
    start_link([])
  end

  def start_link(config) do
    :wx_object.start_link(__MODULE__, config, [])
  end
  def init(config) do
    :wx.new(config)
    Process.flag(:trap_exit, true)
    frame = :wxFrame.new(:wx.null(), -1, 'Game Core', [{:size, {500, 500}}])
    :wxFrame.show(frame)
    {frame, state(win: frame)}
  end

  def load(ref, module) do
    :wx_object.call(ref, {:load, module})
  end
  def unload(ref) do
    :wx_object.call(ref, :unload)
  end
  def shutdown(ref) do
    :wx_object.call(ref, :stop)
  end

  def handle_info({'EXIT', _, :wx_deleted}, s) do
    {:noreply, s}
  end
  def handle_info({'EXIT', _, :normal}, s) do
    {:noreply, s}
  end
  def handle_info(msg, s) do
    :io.format('Info: ~p~n', [msg])
    {:noreply, s}
  end

  def handle_call({:load, module}, from, s) do
    ref = module.start([{:parent, state(s,:win)}, {:size, :wxWindow.getClientSize(state(s,:win))}])
    {:reply, ref, state(s,object: ref)}
  end
  def handle_call(:unload, _from, s) do
    send :wx_object.get_pid(state(s,:object)), :stop
    {:reply, :ok, state(s,object: :undefined)}
  end
  def handle_call(:stop, _from, s) do
    {:stop, :normal,:ok, s}
  end
  def handle_call(msg, _from, s) do
    :io.format('Call: ~p~n', [msg])
    {:reply, :ok, s}
  end


  def handle_event(wx_rec, s) do #wx{event=#wxClose{}}, State = #state{win = Frame}) ->
  event = wx(wx_rec, :event) #might need to do this inside case, might not be a wx record
  case Record.is_record(event,:wxClose) do
    true ->
      frame = state(s,:win)
      :io.format('~p Closing window ~n', [self()])
      :wxFrame.setStatusText(frame, 'Closing...', [])
      {:stop, :normal,s}
    _ ->
      :io.format('~p Event: ~p~n', [__MODULE__, wx_rec])
      {:noreply, s}
    end
  end

  def code_change(_, _, s) do
    {:stop, :not_yet_implemented, s}
  end
  def terminate(_reason, _s) do
    :wx.destroy()
  end
end
