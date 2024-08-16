defmodule Cen.Employers do
  @moduledoc false

  alias Cen.Employers.Organization
  alias Cen.Repo

  @type organization_changeset :: {:ok, Organization.t()} | {:error, Ecto.Changeset.t()}

  def get_organization(id), do: Repo.get(Organization, id)

  @spec create_organization_for(Cen.Accounts.User.t(), map()) :: organization_changeset()
  def create_organization_for(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:organizations)
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

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
