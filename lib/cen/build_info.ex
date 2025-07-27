defmodule Cen.BuildInfo do
  @moduledoc false

  head = ".git/HEAD"

  if File.exists?(head), do: @external_resource(head)

  git_hash_file =
    if File.exists?(head) do
      head_contents = File.read!(head)

      if String.starts_with?(head_contents, "ref:") do
        ref_path =
          head_contents
          |> String.replace("ref:", "")
          |> String.trim()

        ".git/#{ref_path}"
      end
    end

  if git_hash_file && File.exists?(git_hash_file), do: @external_resource(git_hash_file)

  hash =
    if File.exists?(git_hash_file) do
      git_hash_file
      |> File.read!()
      |> String.slice(0, 7)
    end

  def git_short_hash, do: unquote(hash)
end
