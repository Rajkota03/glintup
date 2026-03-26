-- ============================================
-- Migration 002: Content Pipeline Tables
-- Adds tables for AI agent pipeline management
-- ============================================

-- Content prompts: AI prompt templates that admins can edit
CREATE TABLE content_prompts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_role text NOT NULL CHECK (agent_role IN ('scout', 'writer', 'reviewer', 'editor')),
  card_type text,
  name text NOT NULL,
  system_prompt text NOT NULL,
  user_prompt_template text NOT NULL,
  few_shot_examples jsonb DEFAULT '[]',
  model_name text DEFAULT 'gemini-2.0-flash',
  temperature numeric DEFAULT 0.7,
  max_tokens integer DEFAULT 2000,
  tone text DEFAULT 'curious',
  target_difficulty integer DEFAULT 3,
  is_active boolean DEFAULT true,
  success_rate numeric DEFAULT 0,
  total_uses integer DEFAULT 0,
  last_used_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Pipeline runs: tracks each execution of the content pipeline
CREATE TABLE pipeline_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_date date DEFAULT CURRENT_DATE,
  status text DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed', 'cancelled')),
  trigger_type text DEFAULT 'manual' CHECK (trigger_type IN ('manual', 'cron', 'auto_buffer')),

  scout_status text DEFAULT 'pending',
  scout_started_at timestamptz,
  scout_completed_at timestamptz,
  scout_briefs_generated integer DEFAULT 0,
  scout_error text,

  writer_status text DEFAULT 'pending',
  writer_started_at timestamptz,
  writer_completed_at timestamptz,
  writer_cards_drafted integer DEFAULT 0,
  writer_error text,

  reviewer_status text DEFAULT 'pending',
  reviewer_started_at timestamptz,
  reviewer_completed_at timestamptz,
  reviewer_cards_passed integer DEFAULT 0,
  reviewer_cards_failed integer DEFAULT 0,
  reviewer_cards_rewrite integer DEFAULT 0,
  reviewer_error text,

  editor_status text DEFAULT 'pending',
  editor_started_at timestamptz,
  editor_completed_at timestamptz,
  editor_cards_published integer DEFAULT 0,
  editor_error text,

  total_cards_generated integer DEFAULT 0,
  total_cost_cents integer DEFAULT 0,
  duration_seconds integer,
  error_log jsonb DEFAULT '[]',

  created_at timestamptz DEFAULT now(),
  completed_at timestamptz
);

-- Content briefs: Scout agent output (topic ideas)
CREATE TABLE content_briefs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pipeline_run_id uuid REFERENCES pipeline_runs(id) ON DELETE CASCADE,
  topic text NOT NULL,
  subtopic text,
  angle text NOT NULL,
  suggested_card_type text NOT NULL,
  source_hints text,
  difficulty integer DEFAULT 3,
  priority text DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'assigned', 'completed', 'skipped')),
  card_id uuid,
  created_at timestamptz DEFAULT now()
);

-- Card revisions: tracks every change to a card through the pipeline
CREATE TABLE card_revisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id uuid NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  pipeline_run_id uuid REFERENCES pipeline_runs(id) ON DELETE SET NULL,
  revision_number integer DEFAULT 1,
  agent_role text NOT NULL CHECK (agent_role IN ('scout', 'writer', 'reviewer', 'editor', 'manual')),

  accuracy_score integer CHECK (accuracy_score BETWEEN 1 AND 5),
  engagement_score integer CHECK (engagement_score BETWEEN 1 AND 5),
  clarity_score integer CHECK (clarity_score BETWEEN 1 AND 5),
  formatting_score integer CHECK (formatting_score BETWEEN 1 AND 5),
  uniqueness_score integer CHECK (uniqueness_score BETWEEN 1 AND 5),
  overall_score numeric,

  feedback text,
  changes_made text,
  decision text CHECK (decision IN ('pass', 'rewrite', 'reject', 'publish')),

  content_before jsonb,
  content_after jsonb,

  created_at timestamptz DEFAULT now()
);

-- Agent logs: per-call debugging logs
CREATE TABLE agent_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pipeline_run_id uuid REFERENCES pipeline_runs(id) ON DELETE CASCADE,
  agent_role text NOT NULL,
  card_id uuid,
  brief_id uuid,

  model_used text,
  prompt_id uuid,
  input_tokens integer,
  output_tokens integer,
  cost_cents numeric DEFAULT 0,
  latency_ms integer,

  status text DEFAULT 'success' CHECK (status IN ('success', 'error', 'timeout', 'rate_limited')),
  error_message text,

  request_payload jsonb,
  response_payload jsonb,

  created_at timestamptz DEFAULT now()
);

-- OTP codes: for phone authentication
CREATE TABLE IF NOT EXISTS otp_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone text UNIQUE NOT NULL,
  otp text NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- Indexes
-- ============================================
CREATE INDEX idx_content_briefs_run ON content_briefs(pipeline_run_id);
CREATE INDEX idx_content_briefs_status ON content_briefs(status);
CREATE INDEX idx_pipeline_runs_date ON pipeline_runs(run_date);
CREATE INDEX idx_pipeline_runs_status ON pipeline_runs(status);
CREATE INDEX idx_card_revisions_card ON card_revisions(card_id);
CREATE INDEX idx_card_revisions_run ON card_revisions(pipeline_run_id);
CREATE INDEX idx_agent_logs_run ON agent_logs(pipeline_run_id);
CREATE INDEX idx_agent_logs_role ON agent_logs(agent_role);
CREATE INDEX idx_agent_logs_created ON agent_logs(created_at);
CREATE INDEX idx_content_prompts_role ON content_prompts(agent_role, is_active);

-- ============================================
-- Updated_at trigger for content_prompts
-- ============================================
CREATE TRIGGER trg_content_prompts_updated_at
  BEFORE UPDATE ON content_prompts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- ============================================
-- RLS Policies
-- ============================================
ALTER TABLE content_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_briefs ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_codes ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read pipeline tables (for admin dashboard)
CREATE POLICY "Authenticated users can read content_prompts" ON content_prompts
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can manage content_prompts" ON content_prompts
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can read pipeline_runs" ON pipeline_runs
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can manage pipeline_runs" ON pipeline_runs
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Authenticated users can read content_briefs" ON content_briefs
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can read card_revisions" ON card_revisions
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can read agent_logs" ON agent_logs
  FOR SELECT TO authenticated USING (true);

-- Service role bypasses RLS anyway, these policies are for admin dashboard access

-- ============================================
-- SEED: Content Prompts
-- ============================================

-- 1. Scout prompt
INSERT INTO content_prompts (agent_role, card_type, name, system_prompt, user_prompt_template, temperature, max_tokens, tone) VALUES
('scout', NULL, 'Topic Scout',
'You are a content scout for Glintup, a daily learning app. Your job is to find fascinating, surprising, and educational topic ideas that make people say "I didn''t know that!" or "That''s fascinating!"

Focus on:
- Counterintuitive findings
- Surprising connections between fields
- Little-known facts with big implications
- Recent discoveries or research
- Historical stories that read like fiction

Avoid:
- Common knowledge everyone already knows
- Overly technical jargon
- Controversial political topics
- Unverified claims',

'Generate {{count}} content brief ideas for the topic "{{topic}}".

For each idea, provide a JSON object with:
- "subtopic": specific area within the topic
- "angle": the unique hook that makes this interesting (start with a surprising fact or question)
- "suggested_card_type": one of "quick_fact", "insight", "visual", "story", "deep_read", "question", "quote"
- "difficulty": 1-5 (1=casual reader, 5=expert level)
- "source_hints": what to research for accurate information

Return a JSON array of {{count}} objects.',
0.8, 2000, 'curious');

-- 2-8. Writer prompts (one per card type)
INSERT INTO content_prompts (agent_role, card_type, name, system_prompt, user_prompt_template, temperature, max_tokens, tone) VALUES

-- Quick Fact Writer
('writer', 'quick_fact', 'Quick Fact Writer',
'You write concise, surprising quick facts for the Glintup learning app. Each fact should be mind-blowing in 2-3 sentences. Lead with the most surprising part. Be accurate.',
'Write a Quick Fact card about: {{angle}}
Topic: {{topic}}, Subtopic: {{subtopic}}
Difficulty: {{difficulty}}/5
Research hints: {{source_hints}}

Return a JSON object with: "title" (compelling 5-8 word title), "body" (2-3 sentences, lead with the surprising part), "summary" (one-line takeaway), "source_name" (credible source), "tags" (array of 2-3 tags), "estimated_read_seconds" (10-20)',
0.7, 500, 'curious'),

-- Insight Writer
('writer', 'insight', 'Insight Writer',
'You write insightful analysis cards that help readers understand WHY something works the way it does. Go beyond surface-level facts to reveal the underlying principle or mechanism.',
'Write an Insight card about: {{angle}}
Topic: {{topic}}, Subtopic: {{subtopic}}
Difficulty: {{difficulty}}/5
Research hints: {{source_hints}}

Return a JSON object with: "title" (thought-provoking title), "body" (3-4 paragraphs explaining the insight, why it matters, and how it connects to daily life), "summary" (key takeaway in one sentence), "source_name" (credible source), "tags" (array of 2-3 tags), "estimated_read_seconds" (45-90)',
0.7, 1500, 'curious'),

-- Story Writer
('writer', 'story', 'Story Writer',
'You write engaging narrative stories for the Glintup learning app. Start with a vivid scene, build curiosity or tension, and deliver a satisfying insight. Use sensory details and human elements.',
'Write a Story card about: {{angle}}
Topic: {{topic}}, Subtopic: {{subtopic}}
Difficulty: {{difficulty}}/5
Research hints: {{source_hints}}

Return a JSON object with: "title" (narrative title), "subtitle" (one-line subtitle), "body" (300-400 words, start with a scene, use markdown formatting, end with insight), "summary" (the lesson from this story), "source_name" (credible source), "tags" (array of 2-3 tags), "estimated_read_seconds" (90-150)',
0.8, 2000, 'curious'),

-- Visual Writer
('writer', 'visual', 'Visual Writer',
'You create visual learning cards. Describe something amazing to see and explain why it matters. Include an image search term for finding a relevant photo on Unsplash.',
'Write a Visual card about: {{angle}}
Topic: {{topic}}, Subtopic: {{subtopic}}
Difficulty: {{difficulty}}/5
Research hints: {{source_hints}}

Return a JSON object with: "title" (descriptive visual title), "body" (2-3 paragraphs about what we are seeing and why it matters), "summary" (what this teaches us), "image_search_term" (specific Unsplash search query), "source_name" (credible source), "tags" (array of 2-3 tags), "estimated_read_seconds" (30-60)',
0.7, 1000, 'curious'),

-- Quote Writer
('writer', 'quote', 'Quote Writer',
'You curate real, verified quotes with context. ONLY use actual quotes from real people. NEVER fabricate or modify quotes. Include proper attribution.',
'Find a real quote related to: {{angle}}
Topic: {{topic}}, Subtopic: {{subtopic}}

Return a JSON object with: "title" (speaker full name), "body" (the exact quote text), "summary" (one sentence of context about why this quote matters or when it was said), "source_name" (book, speech, or interview where this was said), "tags" (array of 2-3 tags), "estimated_read_seconds" (15-25)',
0.5, 500, 'curious'),

-- Question Writer
('writer', 'question', 'Question Writer',
'You create thought-provoking multiple choice questions that teach through the answer explanation. All 4 options must be plausible. The explanation should be the real learning moment.',
'Create a Question card about: {{angle}}
Topic: {{topic}}, Subtopic: {{subtopic}}
Difficulty: {{difficulty}}/5
Research hints: {{source_hints}}

Return a JSON object with: "title" (question category), "question_text" (interesting question testing understanding, not just memory), "answer_options" (array of 4 objects with "label" A/B/C/D and "text"), "correct_answer" (the label e.g. "B"), "correct_answer_explanation" (2-3 sentences explaining why and what we learn), "tags" (array of 2-3 tags), "estimated_read_seconds" (30-60)',
0.7, 1000, 'curious'),

-- Deep Read Writer
('writer', 'deep_read', 'Deep Read Writer',
'You write in-depth educational articles for curious minds. Use clear sections, build understanding progressively, and end with actionable takeaways. Make complex topics accessible.',
'Write a Deep Read card about: {{angle}}
Topic: {{topic}}, Subtopic: {{subtopic}}
Difficulty: {{difficulty}}/5
Research hints: {{source_hints}}

Return a JSON object with: "title" (compelling article title), "body" (500-700 words, use markdown ## headings for sections, build from basics to depth, include a surprising detail, end strong), "summary" (the key takeaway readers should remember), "source_name" (primary source), "tags" (array of 2-3 tags), "estimated_read_seconds" (150-240)',
0.7, 3000, 'curious');

-- 9. Reviewer prompt
INSERT INTO content_prompts (agent_role, card_type, name, system_prompt, user_prompt_template, temperature, max_tokens, tone) VALUES
('reviewer', NULL, 'Quality Reviewer',
'You are a strict quality reviewer for the Glintup learning app. Score each card honestly on 5 dimensions. Be critical — only score 4+ if it is genuinely good. Your standards protect the user experience.

Scoring guide:
5 = Exceptional, would share with friends
4 = Good, solid content worth publishing
3 = Okay but needs improvement
2 = Below standard, significant issues
1 = Poor, should not be published',

'Review this card:
Type: {{card_type}}
Title: {{title}}
Body: {{body}}
Summary: {{summary}}
Target difficulty: {{difficulty}}/5

Score each dimension 1-5:
1. ACCURACY: Are facts likely correct? Any hallucination red flags?
2. ENGAGEMENT: Would a curious person enjoy reading this?
3. CLARITY: Is it easy to understand at the target difficulty level?
4. FORMATTING: Is the length appropriate? Structure correct for this card type?
5. UNIQUENESS: Does this feel fresh and surprising, not generic?

Return a JSON object with: "accuracy_score", "engagement_score", "clarity_score", "formatting_score", "uniqueness_score", "overall_score" (average), "decision" ("pass" if overall >= 4, "rewrite" if 3-3.9, "reject" if < 3), "feedback" (specific actionable feedback), "accuracy_flag" (true if facts need human verification), "rewrite_instructions" (if decision is rewrite, what specifically to change)',
0.3, 1000, 'curious');

-- 10. Editor prompt
INSERT INTO content_prompts (agent_role, card_type, name, system_prompt, user_prompt_template, temperature, max_tokens, tone) VALUES
('editor', NULL, 'Content Editor',
'You are the final editor for the Glintup learning app. Your job is to polish content to be clear, engaging, and consistent in tone. Do not rewrite — refine. Keep the core content intact.

Your priorities:
1. The opening sentence MUST grab attention
2. Remove unnecessary words (be concise)
3. Fix any issues from reviewer feedback
4. Ensure consistent tone throughout
5. Make sure the summary captures the key takeaway',

'Polish this card:
Type: {{card_type}}
Title: {{title}}
Body: {{body}}
Summary: {{summary}}
Reviewer feedback: {{feedback}}
Target tone: {{tone}}

Return a JSON object with: "title" (polished title), "body" (polished body), "summary" (polished summary), "changes_made" (brief description of what you changed)',
0.5, 2000, 'curious');
