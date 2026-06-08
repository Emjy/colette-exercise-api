defmodule Exercise.Communities.Activity do
  @moduledoc "An activity members can attend."
  use Ecto.Schema

  import Ecto.Changeset

  alias Exercise.Accounts.User
  alias Exercise.Communities.ActivityAttendance

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "activities" do
    field :title, :string
    field :slug, :string
    field :description, :string
    field :starts_at, :utc_datetime_usec
    field :max_attendees, :integer
    # Maintained by a DB trigger (active attendances); never cast — see migration.
    field :attendee_count, :integer, default: 0, read_after_writes: true
    field :price_amount, :integer, default: 0
    field :price_currency, :string, default: "EUR"
    field :postal_code, :string
    field :location, Geo.PostGIS.Geometry
    field :published_at, :utc_datetime_usec
    field :archived_at, :utc_datetime_usec

    belongs_to :creator, User
    has_many :attendances, ActivityAttendance, where: [deleted_at: nil]
    # Registered members: the users behind the active (non-soft-deleted) attendances.
    has_many :participants, through: [:attendances, :user]

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [
      :title,
      :slug,
      :description,
      :starts_at,
      :max_attendees,
      :price_amount,
      :price_currency,
      :postal_code,
      :location,
      :published_at,
      :archived_at,
      :creator_id
    ])
    |> validate_required([:title, :slug, :starts_at, :max_attendees])
    |> validate_number(:max_attendees, greater_than: 0)
    |> unique_constraint(:slug)
  end
end
