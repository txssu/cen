defmodule Cen.Accounts.User do
  @moduledoc false
  use Ecto.Schema
  use Gettext, backend: CenWeb.Gettext

  import Ecto.Changeset

  alias Cen.Communications.Notification
  alias Cen.Employers.Organization
  alias Cen.Publications.Resume
  alias Cen.Publications.Vacancy

  # @cyrillic_or_space ~r/^[\p{Cyrillic}\s]+$/u

  @type t() :: %__MODULE__{}

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime

    field :privacy_consent, :boolean, virtual: true, default: false

    field :vk_id, :integer

    field :fullname, :string
    field :phone_number, :string
    field :birthdate, :date
    field :role, Ecto.Enum, values: [:applicant, :employer, :admin]

    has_many :organizations, Organization
    has_many :vacancies, Vacancy
    has_many :resumes, Resume
    has_many :notifications, Notification

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  @spec registration_changeset(t(), map(), keyword()) :: Ecto.Changeset.t()
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, ~w[email password fullname phone_number role birthdate privacy_consent]a)
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_role()
    |> validate_privacy_consent()
    |> validate_personal_info()
  end

  defp validate_role(changeset) do
    changeset
    |> validate_required([:role])
    |> validate_change(:role, fn
      :role, :admin -> [role: dgettext("errors", "cannot be admin")]
      :role, _otherwise -> []
    end)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: dgettext("errors", "must have the @ sign and no spaces"))
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    |> validate_format(:password, ~r/[a-z]/, message: dgettext("errors", "should be at least one lower case character"))
    |> validate_format(:password, ~r/[A-Z]/, message: dgettext("errors", "should be at least one upper case character"))
    |> validate_format(:password, ~r/[0-9]/, message: dgettext("errors", "should be at least one digit"))
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Cen.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @spec vk_id_changeset(t(), map()) :: Ecto.Changeset.t()
  def vk_id_changeset(user, attrs) do
    user
    |> cast(attrs, ~w[email fullname phone_number role birthdate vk_id]a)
    |> validate_vk_id()
    |> validate_personal_info()
  end

  @spec personal_info_changeset(t(), map()) :: Ecto.Changeset.t()
  def personal_info_changeset(user, attrs) do
    user
    |> cast(attrs, [:fullname, :phone_number, :birthdate])
    |> validate_personal_info()
  end

  defp validate_personal_info(changeset) do
    changeset
    |> validate_birthdate()
    |> validate_fullname()
    |> validate_phone_number()
  end

  defp validate_birthdate(changeset) do
    case get_field(changeset, :role) do
      :applicant -> validate_required(changeset, [:birthdate])
      _employer -> changeset
    end
  end

  defp validate_fullname(changeset) do
    changeset
    |> validate_required([:fullname])
    |> validate_length(:fullname, max: 60)

    # |> validate_format(:fullname, @cyrillic_or_space, message: "Содержит недопустимые символы")
  end

  defp validate_phone_number(changeset) do
    changeset
    |> validate_required([:phone_number])
    |> validate_format(:phone_number, ~r/^\+7\d{10}$/, message: "должен быть в формате +7XXXXXXXXXX")
  end

  defp validate_vk_id(changeset) do
    validate_required(changeset, [:vk_id])
  end

  defp validate_privacy_consent(changeset) do
    changeset
    |> validate_required(:privacy_consent)
    |> validate_acceptance(:privacy_consent, message: "необходимо согласие")
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  @spec email_changeset(t(), map(), keyword()) :: Ecto.Changeset.t()
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, dgettext("errors", "did not change"))
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  @spec password_changeset(t(), map(), keyword()) :: Ecto.Changeset.t()
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: dgettext("errors", "does not match password"))
    |> validate_password(opts)
  end

  @spec role_changeset(t(), map()) :: Ecto.Changeset.t()
  def role_changeset(user, attrs) do
    user
    |> cast(attrs, [:role])
    |> validate_role()
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  @spec confirm_changeset(t() | Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  @spec valid_password?(t(), String.t()) :: boolean()
  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password) when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_user, _password) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  @spec validate_current_password(Ecto.Changeset.t(), String.t()) :: Ecto.Changeset.t()
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, dgettext("errors", "is not valid"))
    end
  end
end
