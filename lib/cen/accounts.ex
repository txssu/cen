defmodule Cen.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Cen.Accounts.InvalidParamsStorage
  alias Cen.Accounts.User
  alias Cen.Accounts.UserNotifier
  alias Cen.Accounts.UserToken
  alias Cen.Accounts.VKIDAuthProvider
  alias Cen.Repo
  alias Ecto.Multi

  @type user_changeset :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  @spec get_user_by_email(String.t()) :: User.t() | nil
  def get_user_by_email(email) when is_binary(email) do
    User
    |> User.not_deleted()
    |> where([u], u.email == ^email)
    |> Repo.one()
  end

  def get_user_by_vk_id(vk_id) do
    User
    |> User.not_deleted()
    |> where([u], u.vk_id == ^vk_id)
    |> Repo.one()
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  @spec get_user_by_email_and_password(String.t(), String.t()) :: User.t() | nil
  def get_user_by_email_and_password(email, password) when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user!(id :: term()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec register_user(map()) :: user_changeset()
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_registration(User.t(), map()) :: Ecto.Changeset.t()
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_email(User.t(), map()) :: Ecto.Changeset.t()
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  @spec apply_user_email(User.t(), String.t(), map()) :: user_changeset()
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  @spec update_user_email(User.t(), String.t()) :: :ok | :error
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _user} <-
           user
           |> user_email_multi(email, context)
           |> Repo.transaction() do
      :ok
    else
      _error -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Multi.new()
    |> Multi.update(:user, changeset)
    |> Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  @spec deliver_user_update_email_instructions(User.t(), String.t(), (String.t() -> String.t())) ::
          {:ok, Swoosh.Email.t()} | {:error, term()}
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun) when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_password(User.t(), map()) :: Ecto.Changeset.t()
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user_password(User.t(), String.t(), map()) :: user_changeset()
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Multi.new()
    |> Multi.update(:user, changeset)
    |> Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _changes} -> {:error, changeset}
    end
  end

  @spec change_user_personal_info(User.t(), map()) :: Ecto.Changeset.t()
  def change_user_personal_info(user, attrs \\ %{}) do
    User.personal_info_changeset(user, attrs)
  end

  @spec update_user_personal_info(User.t(), map()) :: user_changeset()
  def update_user_personal_info(user, attrs) do
    user
    |> User.personal_info_changeset(attrs)
    |> Repo.update()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  @spec generate_user_session_token(User.t()) :: String.t()
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  @spec get_user_by_session_token(String.t()) :: User.t() | nil
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  @spec delete_user_session_token(String.t()) :: :ok
  def delete_user_session_token(token) do
    token
    |> UserToken.by_token_and_context_query("session")
    |> Repo.delete_all()

    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  @spec deliver_user_confirmation_instructions(User.t(), (String.t() -> String.t())) ::
          {:ok, Swoosh.Email.t()} | {:error, :already_confirmed | term()}
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun) when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  @spec confirm_user(String.t()) :: {:ok, User.t()} | :error
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <-
           user
           |> confirm_user_multi()
           |> Repo.transaction() do
      {:ok, user}
    else
      _error -> :error
    end
  end

  defp confirm_user_multi(user) do
    Multi.new()
    |> Multi.update(:user, User.confirm_changeset(user))
    |> Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  @spec deliver_user_reset_password_instructions(User.t(), (String.t() -> String.t())) ::
          {:ok, Swoosh.Email.t()} | {:error | term()}
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun) when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  @spec get_user_by_reset_password_token(binary()) :: User.t() | nil
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _error -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  @spec reset_user_password(User.t(), map()) :: user_changeset()
  def reset_user_password(user, attrs) do
    Multi.new()
    |> Multi.update(:user, User.password_changeset(user, attrs))
    |> Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _changes} -> {:error, changeset}
    end
  end

  @doc """
  Soft deletes the user by setting deleted_at timestamp.
  This hides the user from most queries while preserving data integrity.
  """
  def soft_delete_user(user) do
    t =
      Multi.new()
      |> Multi.update(:soft_delete, User.soft_delete_changeset(user))
      |> Multi.delete_all(:delete_tokens, UserToken.by_user_and_contexts_query(user, :all))

    case Repo.transaction(t) do
      {:ok, %{soft_delete: user}} -> {:ok, user}
      {:error, _action, _reason, _changes} -> :error
    end
  end

  @spec calculate_user_age(User.t()) :: integer()
  def calculate_user_age(%User{birthdate: birthdate}) do
    Date.utc_today()
    |> Date.diff(birthdate)
    |> Kernel.div(365)
  end

  @spec list_users() :: [User.t()]
  def list_users do
    User
    |> User.not_deleted()
    |> Repo.all()
  end

  def fetch_user_from_vk(params, redirect_uri) do
    case VKIDAuthProvider.auth(params, redirect_uri) do
      {:ok, user_vk_id, access_token} -> fetch_user_by_vk_data(user_vk_id, access_token)
      :error -> {:error, :unauth_from_vk}
    end
  end

  defp fetch_user_by_vk_data(vk_id, access_token) do
    if user = get_user_by_vk_id(vk_id) do
      {:ok, user}
    else
      create_user_using_access_token(access_token)
    end
  end

  def create_user_using_access_token(access_token, fixed_info \\ %{}) do
    with {:ok, user_info} <- VKIDAuthProvider.get_info(access_token) do
      attrs =
        user_info
        |> format_vk_user_info()
        |> Map.merge(fixed_info)

      %User{vk_access_token: access_token}
      |> User.vk_id_changeset(attrs)
      |> Repo.insert()
    end
  end

  defp format_vk_user_info(user_info) do
    %{
      "birthdate" => convert_ru_date_to_iso(user_info["birthday"]),
      "email" => user_info["email"],
      "fullname" => user_info["last_name"] <> " " <> user_info["first_name"],
      "phone_number" => "+" <> user_info["phone"],
      "vk_id" => user_info["user_id"]
    }
  end

  def change_vk_user_creation(user, attrs) do
    User.vk_id_changeset(user, attrs)
  end

  def create_vk_user(attrs) do
    create_user_using_access_token(attrs["vk_access_token"], attrs)
  end

  def save_invalid_params(%Ecto.Changeset{changes: %{vk_id: vk_id}} = changeset) do
    InvalidParamsStorage.put(vk_id, changeset)

    vk_id
  end

  def get_invalid_params(vk_id) do
    InvalidParamsStorage.get(vk_id)
  end

  defp convert_ru_date_to_iso(ru_date) do
    ru_date
    |> String.split(".")
    |> Enum.reverse()
    |> Enum.join("-")
  end

  @spec change_user_role(User.t(), map()) :: Ecto.Changeset.t()
  def change_user_role(user, attrs \\ %{}) do
    User.role_changeset(user, attrs)
  end

  @spec update_user_role(User.t(), map()) :: user_changeset()
  def update_user_role(user, attrs) do
    user
    |> User.role_changeset(attrs)
    |> Repo.update()
  end
end
