# NeheElixir
a port of:
https://github.com/asceth/nehe_erlang
of the NeHe Game tutorials for Elixir

## Examples
iex> nehe = NeheElixir.start_link  
iex> nehe |> NeheElixir.load(Tut5)  
iex> nehe |> NeheElixir.unload()  
iex> nehe |> NeheElixir.shutdown()  

## Notes
I tried using `{:quaff, git: "https://github.com/qhool/quaff.git"}` to load the macros from wx.hrl, gl.hrl and glu.hrl. That didn't work. So instead I converted them to elixir macros myself. One caveat is that as erlang macros it seemed that they assumed :wx.new would be called by the time they were invoked (either they are runtime macros or just something else) since they read :wx config out of shared ets memory. So, I just call :wx.new at compile time. This might not be the best solution, we could always turn them from @ macros into function calls or proper macro definitions, but for now it is fine. Also, all macros have had their WX and GL prefixes turned into wx and gl, respectively as @ macros need to be lowercase in elixir.

I do expect the \*.hrl files to be on your system, though, so that we can load the erlang record types from them using Record.export_all
