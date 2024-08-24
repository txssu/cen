# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Cen.ImageUploader do
  @moduledoc false
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @allowed_extensions ~w(.png .jpg .jpeg)

  def filename(version, {file, organization}) do
    # It is desirable for this name to be unique
    "#{file.file_name}_#{organization.id}_#{version}"
  end

  def validate(_version, {file, _scope}) do
    file_extension =
      file.file_name
      |> Path.extname()
      |> String.downcase()

    Enum.member?(@allowed_extensions, file_extension)
  end
end
