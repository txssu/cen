defmodule Cen.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Cen.Accounts` context.
  """

  @spec unique_user_email() :: String.t()
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @spec valid_user_password() :: String.t()
  def valid_user_password, do: "HelloWorld123"

  @spec valid_user_role() :: atom()
  def valid_user_role, do: :applicant

  @spec valid_user_birthdate() :: Date.t()
  def valid_user_birthdate, do: ~D[1990-01-01]

  @spec valid_user_fullname() :: String.t()
  def valid_user_fullname, do: "Иван Иванов"

  @spec valid_user_phone_number() :: String.t()
  def valid_user_phone_number, do: "+70001234567"

  @spec valid_user_attributes(map()) :: map()
  def valid_user_attributes(attrs \\ %{}) do
    base_attrs = %{
      email: unique_user_email(),
      password: valid_user_password(),
      role: valid_user_role(),
      fullname: valid_user_fullname(),
      phone_number: valid_user_phone_number(),
      privacy_consent: true
    }

    attrs_with_defaults = Enum.into(attrs, base_attrs)

    # Use Date for non-web contexts
    birthdate =
      case attrs_with_defaults.role do
        role when role in [:applicant, "applicant"] -> valid_user_birthdate()
        _other -> nil
      end

    Map.put(attrs_with_defaults, :birthdate, birthdate)
  end

  @spec valid_user_web_attributes(map()) :: map()
  def valid_user_web_attributes(attrs \\ %{}) do
    base_attrs = %{
      email: unique_user_email(),
      password: valid_user_password(),
      role: "applicant",
      fullname: valid_user_fullname(),
      phone_number: valid_user_phone_number(),
      privacy_consent: true
    }

    attrs_with_defaults = Enum.into(attrs, base_attrs)

    # Use string for web contexts
    birthdate =
      case attrs_with_defaults.role do
        role when role in [:applicant, "applicant"] -> "1990-01-01"
        _other -> ""
      end

    Map.put(attrs_with_defaults, :birthdate, birthdate)
  end

  @spec user_fixture(map()) :: Cen.Accounts.User.t()
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Cen.Accounts.register_user()

    user
  end

  @spec extract_user_token((String.t() -> {:ok, Swoosh.Email.t()})) :: String.t()
  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_prefix, token | _suffix] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
