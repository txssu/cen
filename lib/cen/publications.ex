defmodule Cen.Publications do
  @moduledoc false
  import Cen.Utils.QueryFilter
  import Ecto.Query

  alias Cen.Accounts.User
  alias Cen.Employers.Organization
  alias Cen.Publications.Filters
  alias Cen.Publications.Resume
  alias Cen.Publications.ResumeSearchOptions
  alias Cen.Publications.Vacancy
  alias Cen.Publications.VacancySearchOptions
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

  @spec search_resumes(map()) :: {:ok, {[Resume.t()], Flop.Meta.t()}} | {:error, Flop.Meta.t()}
  def search_resumes(params) do
    case %ResumeSearchOptions{} |> ResumeSearchOptions.changeset(params) |> Ecto.Changeset.apply_action(:validate) do
      {:ok, filters} ->
        Resume
        |> filter(:searchable, :search, filters.query)
        |> filter(:field_of_art, :eq, filters.field_of_art)
        |> Filters.filter_employment_types(filters.employment_types)
        |> Filters.filter_work_schedules(filters.work_schedules)
        |> Filters.filter_work_experience(filters.min_years_of_work_experience)
        |> Filters.filter_education(filters.education)
        |> preload(:user)
        |> Flop.validate_and_run(%Flop{page_size: 10, order_by: [:inserted_at], order_directions: [:desc], page: params["page"]}, repo: Cen.Repo)

      {:error, _} ->
        []
    end
  end

  @spec search_vacancies(map()) :: {:ok, {[Vacancy.t()], Flop.Meta.t()}} | {:error, Flop.Meta.t()}
  def search_vacancies(params) do
    case %VacancySearchOptions{} |> VacancySearchOptions.changeset(params) |> Ecto.Changeset.apply_action(:validate) do
      {:ok, filters} ->
        Vacancy
        |> filter(:searchable, :search, filters.query)
        |> filter(:field_of_art, :eq, filters.field_of_art)
        |> filter(:min_years_of_work_experience, :not_gt, filters.min_years_of_work_experience)
        |> filter(:proposed_salary, :not_lt, filters.proposed_salary)
        |> Filters.filter_employment_types(filters.employment_types)
        |> Filters.filter_work_schedules(filters.work_schedules)
        |> Filters.filter_vacancy_educations(filters.education)
        |> preload(organization: [:user])
        |> Flop.validate_and_run(%Flop{page_size: 10, order_by: [:inserted_at], order_directions: [:desc], page: params["page"]}, repo: Cen.Repo)

      {:error, _} ->
        []
    end
  end
end
