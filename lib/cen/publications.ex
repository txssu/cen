defmodule Cen.Publications do
  @moduledoc false
  alias Cen.Accounts.User
  alias Cen.Employers.Organization
  alias Cen.Publications.Vacancy
  alias Cen.Repo

  @type vacancy_changeset :: {:ok, Vacancy.t()} | {:error, Ecto.Changeset.t()}

  @spec get_vacancy!(id :: integer() | binary()) :: Vacancy.t()
  def get_vacancy!(id), do: Repo.get!(Vacancy, id)

  @spec list_vacancies_for(User.t()) :: [Vacancy.t()]
  def list_vacancies_for(user) do
    user
    |> Repo.preload(vacancies: :organization)
    |> Map.get(:vacancies)
  end

  @spec change_vacancy(Vacancy.t(), map()) :: Ecto.Changeset.t()
  def change_vacancy(vacancy, attrs \\ %{}) do
    Vacancy.changeset(vacancy, attrs)
  end

  @spec create_vacancy_for(User.t(), Organization.t(), map()) :: vacancy_changeset()
  def create_vacancy_for(user, organization, attrs) do
    %Vacancy{user: user, organization: organization}
    |> Vacancy.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_vacancy(Vacancy.t(), map()) :: vacancy_changeset()
  def update_vacancy(vacancy, attrs) do
    vacancy
    |> Vacancy.changeset(attrs)
    |> Repo.update()
  end
end
