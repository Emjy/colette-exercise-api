alias Exercise.Accounts.User
alias Exercise.Communities.Activity
alias Exercise.Communities.ActivityAttendance
alias Exercise.Repo

now = DateTime.utc_now()
pt = fn lng, lat -> %Geo.Point{coordinates: {lng, lat}, srid: 4326} end

organiser = Repo.insert!(%User{email: "organiser@example.com", name: "Olivia Organiser"})

members =
  for i <- 1..12 do
    Repo.insert!(%User{email: "member#{i}@example.com", name: "Member #{i}"})
  end

make = fn attrs ->
  defaults = %{
    starts_at: DateTime.add(now, 7, :day),
    price_amount: 0,
    price_currency: "EUR",
    postal_code: "1000",
    location: pt.(4.35 + :rand.uniform() / 100, 50.85 + :rand.uniform() / 100),
    creator_id: organiser.id,
    published_at: now
  }

  Repo.insert!(struct(%Activity{}, Map.merge(defaults, attrs)))
end

# Registers the first `n` members to an activity (direct insert; bypasses the
# capacity changeset, so keep n <= max_attendees).
register = fn activity, n ->
  for member <- Enum.take(members, n) do
    Repo.insert!(%ActivityAttendance{user_id: member.id, activity_id: activity.id})
  end
end

# In `days` from now — every seeded activity starts in the future, whenever the seed runs.
in_days = fn days -> DateTime.add(now, days, :day) end

# --- Upcoming, visible activities (published, future start date) ---

full =
  make.(%{
    title: "Sold-out Yoga",
    slug: "sold-out-yoga",
    starts_at: in_days.(7),
    max_attendees: 3,
    description:
      "A slow, candle-lit vinyasa flow to unwind the week. Mats and bolsters provided — " <>
        "just bring yourself and a pair of cosy socks for the final rest."
  })

register.(full, 3)

open =
  make.(%{
    title: "Open Pottery",
    slug: "open-pottery",
    starts_at: in_days.(4),
    max_attendees: 10,
    description:
      "Drop in and throw a bowl on the wheel. Our resident ceramicist guides every step, " <>
        "from centring the clay to trimming the foot. All levels welcome; aprons on us."
  })

register.(open, 4)

sourdough =
  make.(%{
    title: "Sourdough Workshop",
    slug: "sourdough-workshop",
    starts_at: in_days.(3),
    max_attendees: 8,
    description:
      "Build, feed and bake with your own starter. You'll leave with a crusty loaf, a jar of " <>
        "living culture, and far too many opinions about hydration."
  })

register.(sourdough, 5)

run =
  make.(%{
    title: "Evening Run Club",
    slug: "evening-run-club",
    starts_at: in_days.(2),
    max_attendees: 20,
    description:
      "An easy 5k along the canal at dusk, finishing at the café for something warm. " <>
        "All paces welcome — nobody gets left behind."
  })

register.(run, 9)

_watercolour =
  make.(%{
    title: "Watercolour Basics",
    slug: "watercolour-basics",
    starts_at: in_days.(10),
    max_attendees: 12,
    description:
      "Washes, wet-on-wet, and learning to love the happy accident. Paper and paints supplied; " <>
        "bring a photo that means something to you."
  })

board =
  make.(%{
    title: "Board Game Night",
    slug: "board-game-night",
    starts_at: in_days.(5),
    max_attendees: 16,
    description:
      "From quick fillers to a meaty euro or two. Snacks on the table, a teacher at every game, " <>
        "and zero pressure to win."
  })

register.(board, 6)

# --- Non-visible activities (kept for the visibility rules) ---

_draft =
  make.(%{
    title: "Draft Hike",
    slug: "draft-hike",
    starts_at: in_days.(8),
    max_attendees: 10,
    published_at: nil,
    description: "A morning ridge walk with coffee at the summit. Still being planned."
  })

_archived =
  make.(%{
    title: "Archived Choir",
    slug: "archived-choir",
    starts_at: in_days.(6),
    max_attendees: 10,
    archived_at: now,
    description: "Four-part harmony for the season — now wrapped up."
  })

IO.puts(
  "Seeded: 1 organiser, #{length(members)} members, 6 upcoming activities + 1 draft + 1 archived."
)
