defmodule Cen.Communications do
  @moduledoc false
  import Ecto.Query

  alias Cen.Accounts.User
  alias Cen.Communications.Interaction
  alias Cen.Communications.Message
  alias Cen.Communications.Notification
  alias Cen.Communications.NotificationStatus
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

  def send_notification(attrs) do
    with {:ok, notification} <- create_notification(attrs),
         :ok <- deliver_notification(notification) do
      {:ok, notification}
    end
  end

  defp create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  defp deliver_notification(%Notification{} = notification) do
    topic =
      if notification.is_broadcast do
        broadcast_topic()
      else
        user_topic(notification.user_id)
      end

    Phoenix.PubSub.broadcast(Cen.PubSub, topic, {:new_notification, notification})
  end

  def subscribe_to_notifications(user)

  def subscribe_to_notifications(%User{id: id}) do
    with :ok <- Phoenix.PubSub.subscribe(Cen.PubSub, broadcast_topic()) do
      Phoenix.PubSub.subscribe(Cen.PubSub, user_topic(id))
      :ok
    end
  end

  defp broadcast_topic, do: "notifications:all"
  defp user_topic(user_id), do: "notifications:#{user_id}"

  def list_notifications_for_user(user_id) do
    query =
      from n in Notification,
        left_join: ns in NotificationStatus,
        on: ns.notification_id == n.id and ns.user_id == ^user_id,
        select_merge: %{is_read: not is_nil(ns.id)},
        where: (n.is_broadcast == true or n.user_id == ^user_id) and is_nil(ns.id)

    Repo.all(query)
  end

  @spec read_notifications(User.t(), [Notification.t()]) :: {non_neg_integer(), nil | [NotificationStatus.t()]}
  def read_notifications(%User{} = user, notifications) when is_list(notifications) do
    now = DateTime.utc_now(:second)

    entries =
      Enum.map(notifications, fn notification ->
        %{notification_id: notification.id, user_id: {:placeholder, :user_id}, inserted_at: {:placeholder, :now}, updated_at: {:placeholder, :now}}
      end)

    placeholders = %{user_id: user.id, now: now}

    Repo.insert_all(NotificationStatus, entries,
      placeholders: placeholders,
      returning: true,
      on_conflict: :nothing,
      conflict_target: [:notification_id, :user_id]
    )
  end
end
