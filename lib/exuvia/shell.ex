defmodule Exuvia.Shell do
  def start(opts) when is_list(opts), do: start(Enum.into(opts, %{}))
  def start(%{project: project_slug, user: remote_user}) do
    IEx.start(prefix: render_ps1(project_slug, remote_user))
  end

  defp render_ps1({project_name, version}, remote_user) do
    IO.ANSI.format([
      :green, project_name, "-", version, :reset,
      " ",
      :blue, :italic, "~#{remote_user}", :reset
    ])
  end
  defp render_ps1(:unknown, remote_user) do
    IO.ANSI.format([
      :blue, :italic, "~#{remote_user}", :reset
    ])
  end
end
