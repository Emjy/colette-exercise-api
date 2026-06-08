defmodule Exercise.Accounts.User do
  @moduledoc "A club member."
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :name, :string
    field :archived_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :archived_at])
    |> validate_required([:email, :name])
    |> unique_constraint(:email)
  end
end
