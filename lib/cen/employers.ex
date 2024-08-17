defmodule Cen.Employers do
  @moduledoc false

  alias Cen.Accounts.User
  alias Cen.Employers.Organization
  alias Cen.Repo

  @type organization_changeset :: {:ok, Organization.t()} | {:error, Ecto.Changeset.t()}

  @spec get_organization(id :: integer() | binary()) :: Organization.t() | nil
  def get_organization(id), do: Repo.get(Organization, id)

  @spec list_organizations_for(User.t()) :: [Organization.t()]
  def list_organizations_for(user) do
    user
    |> Repo.preload(:organizations)
    |> Map.get(:organizations)
  end

  @spec create_organization_for(User.t(), map()) :: organization_changeset()
  def create_organization_for(user, attrs \\ %{}) do
    organization = Ecto.build_assoc(user, :organizations)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:organization, Organization.changeset(organization, attrs))
    |> Ecto.Multi.update(:organization_with_image, &Organization.image_changeset(&1.organization, attrs))
    |> Repo.transaction()
    |> case do
      {:ok, %{organization_with_image: organization_with_image}} -> {:ok, organization_with_image}
      {:error, _operation, changeset, _changes} -> {:error, changeset}
    end
  end

  @spec update_organization(Organization.t(), map()) :: organization_changeset()
  def update_organization(organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_organization(Organization.t()) :: :ok
  def delete_organization(organization) do
    Repo.delete(organization)
  end

  @spec change_organization(Organization.t(), map()) :: Ecto.Changeset.t()
  def change_organization(organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
  end
end
