-- ============================================================================
-- Glintup Initial Schema Migration
-- ============================================================================
-- Creates all tables, enums, indexes, RLS policies, triggers, and functions
-- for the Glintup learning app.
-- ============================================================================

-- Enable required extensions
create extension if not exists "uuid-ossp";

-- ============================================================================
-- ENUMS
-- ============================================================================

create type card_type as enum (
  'quick_fact',
  'insight',
  'visual',
  'story',
  'deep_read',
  'question',
  'quote'
);

create type card_status as enum (
  'draft',
  'review',
  'approved',
  'published',
  'archived'
);

-- ============================================================================
-- 1. PROFILES — extends auth.users
-- ============================================================================

create table profiles (
  id              uuid primary key references auth.users (id) on delete cascade,
  first_name      text,
  last_name       text,
  avatar_url      text,
  preferred_topics text[] default '{}',
  onboarding_completed boolean not null default false,
  subscription_tier text not null default 'free',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

comment on table profiles is 'Public profile for each user, extends auth.users.';

-- ============================================================================
-- 2. TOPICS — content taxonomy
-- ============================================================================

create table topics (
  id              uuid primary key default uuid_generate_v4(),
  slug            text unique not null,
  display_name    text not null,
  icon_name       text,
  color_hex       text,
  parent_topic_id uuid references topics (id) on delete set null,
  sort_order      int not null default 0,
  is_active       boolean not null default true
);

comment on table topics is 'Content taxonomy for cards and user interests.';

-- Seed the 8 default topics
insert into topics (slug, display_name, icon_name, color_hex, sort_order) values
  ('science',    'Science',    'science',        '#4CAF50', 0),
  ('history',    'History',    'history_edu',    '#FF9800', 1),
  ('psychology', 'Psychology', 'psychology',     '#9C27B0', 2),
  ('technology', 'Technology', 'memory',         '#2196F3', 3),
  ('arts',       'Arts',       'palette',        '#E91E63', 4),
  ('business',   'Business',   'business_center','#607D8B', 5),
  ('nature',     'Nature',     'eco',            '#4CAF50', 6),
  ('space',      'Space',      'rocket_launch',  '#3F51B5', 7);

-- ============================================================================
-- 3. CARDS — learning content
-- ============================================================================

create table cards (
  id                        uuid primary key default uuid_generate_v4(),
  card_type                 card_type not null,
  status                    card_status not null default 'draft',
  title                     text not null,
  subtitle                  text,
  body                      text not null,
  summary                   text,
  image_url                 text,
  source_url                text,
  source_name               text,
  topic                     text not null,
  subtopic                  text,
  tags                      text[] default '{}',
  difficulty_level          int not null default 1,
  estimated_read_seconds    int not null default 30,
  question_text             text,
  answer_options            jsonb,
  correct_answer_explanation text,
  quality_score             int default 0,
  created_at                timestamptz not null default now(),
  published_at              timestamptz
);

comment on table cards is 'Individual learning cards — the core content unit.';

create index idx_cards_topic on cards (topic);
create index idx_cards_status on cards (status);
create index idx_cards_published_at on cards (published_at desc);
create index idx_cards_type_status on cards (card_type, status);

-- ============================================================================
-- 4. EDITIONS — daily curated card sets
-- ============================================================================

create table editions (
  id                uuid primary key default uuid_generate_v4(),
  user_id           uuid not null references auth.users (id) on delete cascade,
  edition_date      date not null,
  edition_number    int,
  theme             text,
  total_cards       int not null default 0,
  total_read_seconds int not null default 0,
  tier              text not null default 'free',
  status            text not null default 'assembled',
  created_at        timestamptz not null default now(),
  assembled_at      timestamptz,

  constraint uq_editions_user_date_tier unique (user_id, edition_date, tier)
);

comment on table editions is 'Daily curated card sets assembled per user.';

create index idx_editions_user_date on editions (user_id, edition_date desc);

-- ============================================================================
-- 5. EDITION_CARDS — links cards to editions with ordering
-- ============================================================================

create table edition_cards (
  id          uuid primary key default uuid_generate_v4(),
  edition_id  uuid not null references editions (id) on delete cascade,
  card_id     uuid not null references cards (id) on delete cascade,
  position    int not null,
  pacing_role text not null default 'standard',

  constraint uq_edition_cards_position unique (edition_id, position)
);

comment on table edition_cards is 'Junction table linking cards to editions with position/pacing.';

create index idx_edition_cards_edition on edition_cards (edition_id);

-- ============================================================================
-- 6. USER_EDITIONS — per-user reading progress
-- ============================================================================

create table user_editions (
  id                 uuid primary key default uuid_generate_v4(),
  user_id            uuid not null references auth.users (id) on delete cascade,
  edition_id         uuid not null references editions (id) on delete cascade,
  started_at         timestamptz,
  completed_at       timestamptz,
  last_card_position int not null default 0,
  cards_viewed       int not null default 0,
  total_time_seconds int not null default 0,
  created_at         timestamptz not null default now(),

  constraint uq_user_editions unique (user_id, edition_id)
);

comment on table user_editions is 'Tracks each user''s progress through an edition.';

create index idx_user_editions_user on user_editions (user_id);

-- ============================================================================
-- 7. USER_STATS — aggregated stats (one row per user)
-- ============================================================================

create table user_stats (
  id                       uuid primary key default uuid_generate_v4(),
  user_id                  uuid unique not null references auth.users (id) on delete cascade,
  current_streak           int not null default 0,
  longest_streak           int not null default 0,
  last_completed_date      date,
  total_editions_completed int not null default 0,
  total_cards_read         int not null default 0,
  total_time_seconds       int not null default 0,
  total_cards_saved        int not null default 0,
  cards_this_week          int not null default 0,
  cards_this_month         int not null default 0,
  xp_points                int not null default 0,
  level                    int not null default 1,
  updated_at               timestamptz not null default now()
);

comment on table user_stats is 'Aggregated gamification stats, one row per user.';

-- ============================================================================
-- 8. SAVED_CARDS — user bookmarks
-- ============================================================================

create table saved_cards (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  card_id    uuid not null references cards (id) on delete cascade,
  folder     text,
  note       text,
  created_at timestamptz not null default now(),

  constraint uq_saved_cards unique (user_id, card_id)
);

comment on table saved_cards is 'Cards bookmarked by users.';

create index idx_saved_cards_user on saved_cards (user_id);

-- ============================================================================
-- 9. USER_INTERESTS — topic preferences
-- ============================================================================

create table user_interests (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  topic_slug text not null,
  created_at timestamptz not null default now(),

  constraint uq_user_interests unique (user_id, topic_slug)
);

comment on table user_interests is 'Per-user topic interest selections from onboarding.';

create index idx_user_interests_user on user_interests (user_id);

-- ============================================================================
-- 10. NOTIFICATION_PREFERENCES
-- ============================================================================

create table notification_preferences (
  id             uuid primary key default uuid_generate_v4(),
  user_id        uuid unique not null references auth.users (id) on delete cascade,
  preferred_time time not null default '08:00',
  enabled        boolean not null default true,
  created_at     timestamptz not null default now()
);

comment on table notification_preferences is 'User notification timing preferences.';

-- ============================================================================
-- 11. RABBIT_HOLES — curated deep-dive collections
-- ============================================================================

create table rabbit_holes (
  id                     uuid primary key default uuid_generate_v4(),
  topic                  text not null,
  title                  text not null,
  description            text,
  cover_image_url        text,
  total_cards            int not null default 0,
  estimated_time_minutes int not null default 0,
  difficulty_level       int not null default 2,
  is_premium             boolean not null default false,
  created_at             timestamptz not null default now()
);

comment on table rabbit_holes is 'Curated deep-dive collections for the Explore tab.';

create index idx_rabbit_holes_topic on rabbit_holes (topic);

-- ============================================================================
-- 12. CARD_INTERACTIONS — analytics events
-- ============================================================================

create table card_interactions (
  id                 uuid primary key default uuid_generate_v4(),
  user_id            uuid not null references auth.users (id) on delete cascade,
  card_id            uuid not null references cards (id) on delete cascade,
  edition_id         uuid references editions (id) on delete set null,
  interaction_type   text not null,
  time_spent_seconds int not null default 0,
  created_at         timestamptz not null default now()
);

comment on table card_interactions is 'Granular analytics for card-level user interactions.';

create index idx_card_interactions_user on card_interactions (user_id);
create index idx_card_interactions_card on card_interactions (card_id);

-- ============================================================================
-- 13. CARD_READ_HISTORY — tracks which cards a user has seen
-- ============================================================================

create table card_read_history (
  id      uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users (id) on delete cascade,
  card_id uuid not null references cards (id) on delete cascade,
  read_at timestamptz not null default now(),

  constraint uq_card_read_history unique (user_id, card_id)
);

comment on table card_read_history is 'Deduplication log so we never serve the same card twice.';

create index idx_card_read_history_user on card_read_history (user_id);

-- ============================================================================
-- TRIGGERS — auto-manage timestamps and row creation
-- ============================================================================

-- Generic updated_at trigger function
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Apply to profiles
create trigger trg_profiles_updated_at
  before update on profiles
  for each row execute function set_updated_at();

-- Apply to user_stats
create trigger trg_user_stats_updated_at
  before update on user_stats
  for each row execute function set_updated_at();

-- Auto-create a profile row when a new user signs up
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, first_name, created_at, updated_at)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    now(),
    now()
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Auto-create a user_stats row when a profile is created
create or replace function handle_new_profile()
returns trigger as $$
begin
  insert into user_stats (user_id, updated_at)
  values (new.id, now());
  return new;
end;
$$ language plpgsql security definer;

create trigger on_profile_created
  after insert on profiles
  for each row execute function handle_new_profile();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
alter table profiles                enable row level security;
alter table topics                  enable row level security;
alter table cards                   enable row level security;
alter table editions                enable row level security;
alter table edition_cards           enable row level security;
alter table user_editions           enable row level security;
alter table user_stats              enable row level security;
alter table saved_cards             enable row level security;
alter table user_interests          enable row level security;
alter table notification_preferences enable row level security;
alter table rabbit_holes            enable row level security;
alter table card_interactions       enable row level security;
alter table card_read_history       enable row level security;

-- PROFILES: users can read and update their own profile
create policy "profiles_select_own"
  on profiles for select
  using (auth.uid() = id);

create policy "profiles_update_own"
  on profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- TOPICS: all authenticated users can read
create policy "topics_select_authenticated"
  on topics for select
  using (auth.role() = 'authenticated');

-- CARDS: authenticated users can read published cards
create policy "cards_select_published"
  on cards for select
  using (auth.role() = 'authenticated' and status = 'published');

-- EDITIONS: users can read their own editions
create policy "editions_select_own"
  on editions for select
  using (auth.uid() = user_id);

-- EDITION_CARDS: users can read cards belonging to their own editions
create policy "edition_cards_select_own"
  on edition_cards for select
  using (
    exists (
      select 1 from editions
      where editions.id = edition_cards.edition_id
        and editions.user_id = auth.uid()
    )
  );

-- USER_EDITIONS: users can read/insert/update their own progress
create policy "user_editions_select_own"
  on user_editions for select
  using (auth.uid() = user_id);

create policy "user_editions_insert_own"
  on user_editions for insert
  with check (auth.uid() = user_id);

create policy "user_editions_update_own"
  on user_editions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- USER_STATS: users can read their own stats
create policy "user_stats_select_own"
  on user_stats for select
  using (auth.uid() = user_id);

-- SAVED_CARDS: full CRUD on own rows
create policy "saved_cards_select_own"
  on saved_cards for select
  using (auth.uid() = user_id);

create policy "saved_cards_insert_own"
  on saved_cards for insert
  with check (auth.uid() = user_id);

create policy "saved_cards_update_own"
  on saved_cards for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "saved_cards_delete_own"
  on saved_cards for delete
  using (auth.uid() = user_id);

-- USER_INTERESTS: full CRUD on own rows
create policy "user_interests_select_own"
  on user_interests for select
  using (auth.uid() = user_id);

create policy "user_interests_insert_own"
  on user_interests for insert
  with check (auth.uid() = user_id);

create policy "user_interests_update_own"
  on user_interests for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "user_interests_delete_own"
  on user_interests for delete
  using (auth.uid() = user_id);

-- NOTIFICATION_PREFERENCES: full CRUD on own row
create policy "notification_prefs_select_own"
  on notification_preferences for select
  using (auth.uid() = user_id);

create policy "notification_prefs_insert_own"
  on notification_preferences for insert
  with check (auth.uid() = user_id);

create policy "notification_prefs_update_own"
  on notification_preferences for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "notification_prefs_delete_own"
  on notification_preferences for delete
  using (auth.uid() = user_id);

-- RABBIT_HOLES: all authenticated users can read
create policy "rabbit_holes_select_authenticated"
  on rabbit_holes for select
  using (auth.role() = 'authenticated');

-- CARD_INTERACTIONS: users can insert their own
create policy "card_interactions_insert_own"
  on card_interactions for insert
  with check (auth.uid() = user_id);

create policy "card_interactions_select_own"
  on card_interactions for select
  using (auth.uid() = user_id);

-- CARD_READ_HISTORY: users can read/insert their own
create policy "card_read_history_select_own"
  on card_read_history for select
  using (auth.uid() = user_id);

create policy "card_read_history_insert_own"
  on card_read_history for insert
  with check (auth.uid() = user_id);

-- ============================================================================
-- FUNCTION: assemble_edition
-- ============================================================================
-- Assembles a daily edition of cards for a user.
-- 1. Returns existing edition if one already exists for today.
-- 2. Selects cards weighted by user topic preferences.
-- 3. Applies pacing rules for card ordering.
-- ============================================================================

create or replace function assemble_edition(p_user_id uuid, p_tier text default 'free')
returns uuid as $$
declare
  v_today         date := current_date;
  v_edition_id    uuid;
  v_card_count    int;
  v_total_seconds int := 0;
  v_card_rec      record;
  v_position      int := 0;
  v_pacing_role   text;
begin
  -- 1. Check if an edition already exists for today
  select id into v_edition_id
  from editions
  where user_id = p_user_id
    and edition_date = v_today
    and tier = p_tier
  limit 1;

  if v_edition_id is not null then
    return v_edition_id;
  end if;

  -- Determine card count based on tier
  if p_tier = 'pro' then
    v_card_count := 10;
  else
    v_card_count := 5;
  end if;

  -- 2. Create the edition row
  v_edition_id := uuid_generate_v4();

  insert into editions (id, user_id, edition_date, total_cards, total_read_seconds, tier, status, created_at, assembled_at)
  values (v_edition_id, p_user_id, v_today, v_card_count, 0, p_tier, 'assembled', now(), now());

  -- 3. Select cards the user hasn't read, weighted by their topic interests.
  --    Cards matching user interests are scored higher via a CASE expression.
  --    We apply pacing constraints for the first and last positions.
  for v_card_rec in
    select
      c.id as card_id,
      c.card_type,
      c.estimated_read_seconds,
      case
        when exists (
          select 1 from user_interests ui
          where ui.user_id = p_user_id
            and ui.topic_slug = c.topic
        ) then 1
        else 0
      end as topic_weight
    from cards c
    where c.status = 'published'
      and not exists (
        select 1 from card_read_history crh
        where crh.user_id = p_user_id
          and crh.card_id = c.id
      )
    order by
      topic_weight desc,
      random()
    limit v_card_count
  loop
    -- 4. Assign pacing roles
    if v_position = 0 then
      v_pacing_role := 'opener';        -- visual or quick_fact preferred
    elsif v_position = v_card_count - 1 then
      v_pacing_role := 'closer';        -- quote preferred
    else
      v_pacing_role := 'standard';
    end if;

    insert into edition_cards (id, edition_id, card_id, position, pacing_role)
    values (uuid_generate_v4(), v_edition_id, v_card_rec.card_id, v_position, v_pacing_role);

    v_total_seconds := v_total_seconds + v_card_rec.estimated_read_seconds;
    v_position := v_position + 1;
  end loop;

  -- Update edition totals
  update editions
  set total_cards = v_position,
      total_read_seconds = v_total_seconds
  where id = v_edition_id;

  return v_edition_id;
end;
$$ language plpgsql security definer;

comment on function assemble_edition(uuid, text) is
  'Assembles a daily edition for the given user. Returns existing edition if already assembled today. '
  'Selects unread cards weighted by user topic interests with pacing rules applied.';

-- ============================================================================
-- DONE
-- ============================================================================
