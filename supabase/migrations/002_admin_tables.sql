-- ============================================================================
-- Glintup Admin Tables Migration
-- ============================================================================
-- Creates tables for the admin dashboard: content prompts and generation logs.
-- These tables are used by the admin panel and edge functions only.
-- ============================================================================

-- ============================================================================
-- 1. CONTENT_PROMPTS — AI prompt configuration per topic/card_type
-- ============================================================================

create table content_prompts (
  id                uuid primary key default uuid_generate_v4(),
  topic             text not null,
  card_type         text,
  system_prompt     text not null,
  example_output    text,
  tone              text default 'curious',
  target_difficulty int default 3,
  is_active         boolean default true,
  success_rate      numeric default 0,
  last_used_at      timestamptz,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

comment on table content_prompts is 'AI prompt templates for content generation, configurable per topic and card type.';

create index idx_content_prompts_topic on content_prompts (topic);
create index idx_content_prompts_active on content_prompts (is_active) where is_active = true;

-- Apply updated_at trigger
create trigger trg_content_prompts_updated_at
  before update on content_prompts
  for each row execute function set_updated_at();

-- ============================================================================
-- 2. GENERATION_LOGS — tracks AI content generation runs
-- ============================================================================

create table generation_logs (
  id              uuid primary key default uuid_generate_v4(),
  topic           text not null,
  card_types      text[],
  cards_requested int not null,
  cards_generated int default 0,
  cards_published int default 0,
  prompt_used     text,
  error_message   text,
  duration_ms     int,
  created_at      timestamptz default now()
);

comment on table generation_logs is 'Audit log for AI content generation runs triggered from the admin dashboard.';

create index idx_generation_logs_created on generation_logs (created_at desc);
create index idx_generation_logs_topic on generation_logs (topic);

-- ============================================================================
-- No RLS on admin tables — accessed via service role only
-- ============================================================================
