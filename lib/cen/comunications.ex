defmodule Cen.Communications do
  @moduledoc false
  import Ecto.Query

  alias Cen.Accounts.User
  alias Cen.Communications.Interaction
  alias Cen.Repo

  @type interaction_changeset :: {:ok, Interaction.t()} | {:error, Ecto.Changeset.t()}

  @spec create_interaction_from_vacancy(Keyword.t()) :: interaction_changeset()
  def create_interaction_from_vacancy(entries) do
    create_interaction(:vacancy, entries)
  end

  @spec create_interaction_from_resume(Keyword.t()) :: interaction_changeset()
  def create_interaction_from_resume(entries) do
    create_interaction(:resume, entries)
  end

  defp create_interaction(initiator, entities) do
    resume = Keyword.fetch!(entities, :resume)
    vacancy = Keyword.fetch!(entities, :vacancy)

    interaction = Interaction.changeset(%Interaction{resume_id: resume.id, vacancy_id: vacancy.id, initiator: initiator}, %{})

    Repo.insert(interaction)
  end

  @spec list_interactions_for(user :: User.t(), initiator :: :resume | :vacancy) :: [Interaction.t()]
  def list_interactions_for(user, initiator) do
    query =
      from interaction in Interaction,
        where: interaction.initiator == ^initiator,
        join: resume in assoc(interaction, :resume),
        join: vacancy in assoc(interaction, :vacancy),
        where: resume.user_id == ^user.id or vacancy.user_id == ^user.id,
        preload: [vacancy: [organization: :user], resume: :user]

    Repo.all(query)
  end
end
