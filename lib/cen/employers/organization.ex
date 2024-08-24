defmodule Cen.Employers.Organization do
  @moduledoc false
  use Ecto.Schema
  use Waffle.Ecto.Schema
  use Gettext, backend: CenWeb.Gettext

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "organizations" do
    field :name, :string
    field :address, :string
    field :description, :string
    field :email, :string
    field :inn, :string
    field :phone_number, :string
    field :website_link, :string
    field :social_link, :string

    field :image, Cen.ImageUploader.Type

    belongs_to :user, Cen.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @spec image_changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def image_changeset(organization, attrs) do
    cast_attachments(organization, attrs, [:image], allow_paths: true)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :inn, :description, :phone_number, :email, :website_link, :social_link, :address])
    |> image_changeset(attrs)
    |> validate_name()
    |> validate_inn()
    |> validate_description()
    |> validate_phone_number()
    |> validate_email()
    |> validate_website_link()
    |> validate_social_link()
    |> validate_address()
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required(:name)
    |> validate_length(:name, max: 160)
  end

  defp validate_inn(changeset) do
    changeset
    |> validate_required(:inn)
    |> validate_length(:inn, is: 10)
  end

  defp validate_description(changeset) do
    changeset
    |> validate_required(:description)
    |> validate_length(:description, max: 1000)
  end

  defp validate_phone_number(changeset) do
    changeset
    |> validate_required(:phone_number)
    |> validate_length(:phone_number, max: 20)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: dgettext("errors", "must have the @ sign and no spaces"))
    |> validate_length(:email, max: 160)
  end

  defp validate_website_link(changeset) do
    changeset
    |> validate_length(:website_link, max: 160)
    |> validate_uri(:website_link)
  end

  defp validate_social_link(changeset) do
    changeset
    |> validate_length(:social_link, max: 160)
    |> validate_uri(:social_link)
  end

  defp validate_address(changeset) do
    validate_length(changeset, :address, max: 200)
  end

  defp validate_uri(changeset, field) do
    maybe_uri = get_change(changeset, field)

    case maybe_uri && URI.new(maybe_uri) do
      nil -> changeset
      {:ok, uri} -> validate_uri_is_absolute(changeset, field, uri)
      _other -> add_error(changeset, field, dgettext("errors", "must be a valid URL"))
    end
  end

  defp validate_uri_is_absolute(changeset, field, uri) do
    case uri do
      %URI{scheme: "https", host: host} when host != nil -> changeset
      _other -> add_error(changeset, field, dgettext("errors", "must be an absolute URL (starts with https://)"))
    end
  end
end
