defmodule ExerciseWeb.Schema do
  @moduledoc "The GraphQL schema root."
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(ExerciseWeb.Schema.Types)

  alias ExerciseWeb.Dataloaders.GenericEcto
  alias ExerciseWeb.Resolvers
  alias ExerciseWeb.Schema.Middleware.Authenticated
  alias ExerciseWeb.Schema.Middleware.ErrorHandler

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(GenericEcto, GenericEcto.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  query do
    @desc "List published, non-archived activities."
    field :activities, non_null(list_of(non_null(:activity))) do
      resolve(&Resolvers.Activities.list_activities/3)
    end

    @desc "Fetch a single published, non-archived activity by slug (null if not visible)."
    field :activity, :activity do
      arg(:slug, non_null(:string))
      resolve(&Resolvers.Activities.get_activity/3)
    end
  end

  mutation do
    @desc "Register the current member to an activity."
    field :register_to_activity, :register_to_activity_payload do
      arg(:input, non_null(:register_to_activity_input))
      middleware(Authenticated)
      resolve(&Resolvers.Activities.register/3)
      middleware(ErrorHandler)
    end

    @desc "Unregister the current member from an activity (frees a seat)."
    field :unregister_from_activity, :register_to_activity_payload do
      arg(:input, non_null(:register_to_activity_input))
      middleware(Authenticated)
      resolve(&Resolvers.Activities.unregister/3)
      middleware(ErrorHandler)
    end
  end
end
