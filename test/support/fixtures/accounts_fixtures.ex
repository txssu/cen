defmodule Cen.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Cen.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "HelloWorld123"
  def valid_user_role, do: Enum.random(~w[applicant employer])
  def valid_user_birthdate, do: ~D[1990-01-01]
  def valid_user_fullname, do: "John Doe"
  def valid_user_phone_number, do: "+70001234567"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      role: valid_user_role(),
      fullname: valid_user_fullname(),
      phone_number: valid_user_phone_number(),
      birthdate: valid_user_birthdate()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Cen.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
