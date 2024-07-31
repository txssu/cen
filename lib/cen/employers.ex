defmodule Cen.Employers do
  @moduledoc false

  alias Cen.Employers.Organization
  alias Cen.Repo

  def create_organization_for(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:organizations)
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  def change_organization(organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
  end
end
