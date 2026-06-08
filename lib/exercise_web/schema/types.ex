defmodule ExerciseWeb.Schema.Types do
  @moduledoc "GraphQL object and input types for the exercise schema."
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias ExerciseWeb.Dataloaders.GenericEcto
  alias ExerciseWeb.Resolvers

  object :user do
    field :id, non_null(:id)
    field :name, non_null(:string)
  end

  object :activity_attendance do
    field :id, non_null(:id)
    field :activity, non_null(:activity), resolve: dataloader(GenericEcto)
  end

  input_object :register_to_activity_input do
    field :activity_id, non_null(:id)
  end

  object :register_to_activity_payload do
    field :attendance, :activity_attendance
  end

  object :activity do
    field :id, non_null(:id)
    field :title, non_null(:string)
    field :slug, non_null(:string)
    field :description, :string
    field :starts_at, non_null(:datetime)
    field :max_attendees, non_null(:integer)

    field :creator, :user, resolve: dataloader(GenericEcto)

    @desc "The registered members (active attendances), loaded in a batch via Dataloader."
    field :participants, non_null(list_of(non_null(:user))), resolve: dataloader(GenericEcto)

    @desc "Number of active members, from the trigger-maintained attendee_count column."
    field :attendance_count, non_null(:integer) do
      resolve(fn activity, _args, _resolution -> {:ok, activity.attendee_count} end)
    end

    @desc "Whether the current viewer has an active registration. False when not signed in."
    field :viewer_is_registered, non_null(:boolean) do
      resolve(&Resolvers.Activities.viewer_is_registered/3)
    end

    @desc "Remaining free seats (max_attendees - attendee_count, never negative)."
    field :remaining_spots, non_null(:integer) do
      resolve(fn activity, _args, _resolution ->
        {:ok, max(activity.max_attendees - activity.attendee_count, 0)}
      end)
    end
  end
end
