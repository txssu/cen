defmodule Cen.Publications do
  @moduledoc false
  alias Cen.Accounts.User
  alias Cen.Employers.Organization
  alias Cen.Publications.Resume
  alias Cen.Publications.Vacancy
  alias Cen.Repo

  @type vacancy_changeset :: {:ok, Vacancy.t()} | {:error, Ecto.Changeset.t()}
  @type resume_changeset :: {:ok, Resume.t()} | {:error, Ecto.Changeset.t()}

  @spec get_vacancy!(id :: integer() | binary()) :: Vacancy.t()
  def get_vacancy!(id), do: Vacancy |> Repo.get!(id) |> Repo.preload(:organization)

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

  @spec format_salary(BetterNumber.t()) :: String.t()
  def format_salary(value) do
    BetterNumber.to_currency(value,
      unit: "₽",
      delimiter: " ",
      precision: 0,
      format: fn unit, number -> "#{number} #{unit}" end
    )
  end

  @spec delete_vacancy(Vacancy.t()) :: :ok
  def delete_vacancy(vacancy) do
    Repo.delete(vacancy)
  end

  @spec get_resume!(id :: integer() | binary()) :: Resume.t()
  def get_resume!(id), do: Resume |> Repo.get!(id) |> Repo.preload([:user])

  @spec list_resumes_for(user :: User.t()) :: [Resume.t()]
  def list_resumes_for(user) do
    user
    |> Repo.preload(:resumes)
    |> Map.get(:resumes)
  end

  @spec change_resume(Resume.t(), map()) :: Ecto.Changeset.t()
  def change_resume(resume, attrs \\ %{}) do
    Resume.changeset(resume, attrs)
  end

  @spec create_resume_for(User.t(), map()) :: resume_changeset()
  def create_resume_for(user, attrs) do
    user
    |> Ecto.build_assoc(:resumes)
    |> Resume.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_resume(Resume.t(), map()) :: resume_changeset()
  def update_resume(resume, attrs) do
    resume
    |> Resume.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_resume(Resume.t()) :: :ok
  def delete_resume(resume) do
    Repo.delete(resume)
  end
end
