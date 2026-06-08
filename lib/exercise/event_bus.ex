defmodule Exercise.EventBus do
  @moduledoc "The application event bus (ex_event_bus). Dispatches domain events to handlers via Oban."
  use ExEventBus, otp_app: :exercise
end
