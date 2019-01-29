defmodule Exuvia.Shell do
  def start(opts) when is_list(opts), do: start(Enum.into(opts, %{}))

  def start(%{project: project_slug, session_id: session_id}) do
    prefix =
      project_slug
      |> render_ps1(session_id)

    IEx.start(prefix: prefix)
  end

  defp render_ps1(project_slug, session_id) do
    parts = [
      format_project_slug(project_slug),
      format_session_id(session_id)
    ]

    parts |> Enum.filter(& &1) |> Enum.join(" ")
  end

  def format_project_slug(nil), do: []

  def format_project_slug({project_name, version}) do
    IO.ANSI.format([:green, project_name, "-", version])
  end

  def format_session_id({session_counter, remote_user}) do
    [
      format_remote_user(remote_user),
      IO.ANSI.format([:blue, ":", to_string(session_counter)])
    ]
  end

  def format_remote_user(username) do
    IO.ANSI.format([:blue, :italic, "~", username])
  end
end
