defmodule Cen.Communications do
  @moduledoc false
  import Ecto.Query

  alias Cen.Accounts.User
  alias Cen.Communications.Interaction
  alias Cen.Communications.Message
  alias Cen.Repo

  @type interaction_changeset :: {:ok, Interaction.t()} | {:error, Ecto.Changeset.t()}
  @type message_changeset :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}

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
    message_attrs = Keyword.fetch!(entities, :message_attrs)

    interaction = Interaction.changeset(%Interaction{resume_id: resume.id, vacancy_id: vacancy.id, initiator: initiator}, %{})

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:interaction, interaction)
    |> Ecto.Multi.run(:message, fn _repo, %{interaction: interaction} ->
      maybe_create_message(interaction.id, message_attrs.user_id, message_attrs.text)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{interaction: interaction}} -> {:ok, interaction}
      {:error, _operation, changeset, _changes} -> {:error, changeset}
    end
  end

  defp maybe_create_message(interaction_id, user_id, text) do
    case text do
      "" ->
        {:ok, nil}

      _text ->
        %Message{interaction_id: interaction_id, user_id: user_id}
        |> Message.changeset(%{text: text})
        |> Repo.insert()
    end
  end

  @spec list_interactions_for(user :: User.t()) :: [Interaction.t()]
  def list_interactions_for(user) do
    query =
      from interaction in Interaction,
        as: :interaction,
        join: resume in assoc(interaction, :resume),
        join: vacancy in assoc(interaction, :vacancy),
        left_lateral_join:
          latest_message in subquery(
            from m in Message,
              where: m.interaction_id == parent_as(:interaction).id,
              order_by: [desc: m.inserted_at],
              limit: 1
          ),
        on: latest_message.interaction_id == interaction.id,
        where: resume.user_id == ^user.id or vacancy.user_id == ^user.id,
        order_by: [desc: latest_message.inserted_at],
        preload: [
          messages: latest_message,
          vacancy: [:organization, :user],
          resume: :user
        ]

    Repo.all(query)
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

  @spec change_message(Message.t(), map()) :: Ecto.Changeset.t()
  def change_message(message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  @spec send_message(integer(), integer(), map()) :: message_changeset()
  def send_message(interaction_id, user_id, attrs) do
    %Message{interaction_id: interaction_id, user_id: user_id}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @spec list_messages(integer(), integer()) :: {[Message.t()], Flop.Meta.t()}
  def list_messages(interaction_id, offset) do
    Message
    |> where([message], message.interaction_id == ^interaction_id)
    |> Flop.run(%Flop{limit: 30, order_by: [:inserted_at], order_directions: [:desc], offset: offset}, repo: Cen.Repo)
  end
end
