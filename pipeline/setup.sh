#!/bin/bash
set -e

echo "============================================"
echo "  Glintup Content Pipeline - VPS Setup"
echo "============================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_step() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# 1. System Update
echo "Step 1: Updating system..."
apt update -y && apt upgrade -y
apt install -y curl git python3 python3-pip python3-venv jq cron
print_step "System updated"

# 2. Install Ollama
echo ""
echo "Step 2: Installing Ollama..."
if command -v ollama &> /dev/null; then
    print_warn "Ollama already installed"
else
    curl -fsSL https://ollama.com/install.sh | sh
    print_step "Ollama installed"
fi

# Start Ollama service
systemctl enable ollama
systemctl start ollama
sleep 3
print_step "Ollama service started"

# 3. Pull Qwen2.5 32B model
echo ""
echo "Step 3: Pulling Qwen2.5 32B model (this takes 10-20 minutes)..."
ollama pull qwen2.5:32b
print_step "Qwen2.5 32B model downloaded"

# 4. Create project directory
echo ""
echo "Step 4: Setting up pipeline..."
mkdir -p /opt/glintup/pipeline
mkdir -p /opt/glintup/logs
mkdir -p /opt/glintup/prompts

# 5. Create Python virtual environment
cd /opt/glintup
python3 -m venv venv
source venv/bin/activate
pip install requests supabase python-dotenv schedule
print_step "Python environment ready"

# 6. Create .env file template
cat > /opt/glintup/.env << 'ENVEOF'
# Supabase Configuration
SUPABASE_URL=https://lmbubuhmodtfpeqgqint.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Ollama Configuration
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=qwen2.5:32b

# Pipeline Configuration
CARDS_PER_RUN=30
MIN_QUALITY_SCORE=4
BUFFER_MIN=200
BUFFER_ALERT=50
ENVEOF
print_step "Environment template created at /opt/glintup/.env"

# 7. Create the main pipeline script
cat > /opt/glintup/pipeline/run_pipeline.py << 'PYEOF'
#!/usr/bin/env python3
"""
Glintup Content Pipeline
Generates learning cards using local Ollama (Qwen2.5 32B)
and pushes them to Supabase.
"""

import os
import json
import time
import requests
import logging
from datetime import datetime, timezone
from pathlib import Path
from dotenv import load_dotenv

# Load environment
load_dotenv('/opt/glintup/.env')

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
OLLAMA_HOST = os.getenv('OLLAMA_HOST', 'http://localhost:11434')
OLLAMA_MODEL = os.getenv('OLLAMA_MODEL', 'qwen2.5:32b')
CARDS_PER_RUN = int(os.getenv('CARDS_PER_RUN', '30'))
MIN_QUALITY_SCORE = int(os.getenv('MIN_QUALITY_SCORE', '4'))

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('/opt/glintup/logs/pipeline.log'),
        logging.StreamHandler()
    ]
)
log = logging.getLogger('glintup')

# Supabase headers
HEADERS = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
}

TOPICS = ['science', 'history', 'psychology', 'technology', 'arts', 'business', 'nature', 'space']
CARD_TYPES = ['quick_fact', 'insight', 'visual', 'story', 'deep_read', 'question', 'quote']

# ─────────────────────────────────────────────
# Ollama Helper
# ─────────────────────────────────────────────

def call_ollama(system_prompt: str, user_prompt: str, temperature: float = 0.7) -> str:
    """Call local Ollama model and return the response text."""
    try:
        resp = requests.post(
            f'{OLLAMA_HOST}/api/chat',
            json={
                'model': OLLAMA_MODEL,
                'messages': [
                    {'role': 'system', 'content': system_prompt},
                    {'role': 'user', 'content': user_prompt}
                ],
                'stream': False,
                'options': {
                    'temperature': temperature,
                    'num_predict': 2048,
                }
            },
            timeout=120
        )
        resp.raise_for_status()
        return resp.json()['message']['content']
    except Exception as e:
        log.error(f'Ollama call failed: {e}')
        return ''

def call_ollama_json(system_prompt: str, user_prompt: str, temperature: float = 0.7) -> dict | list | None:
    """Call Ollama and parse JSON response."""
    response = call_ollama(system_prompt, user_prompt + '\n\nRespond ONLY with valid JSON. No markdown, no explanation.', temperature)
    if not response:
        return None
    # Try to extract JSON from response
    try:
        # Remove markdown code blocks if present
        cleaned = response.strip()
        if cleaned.startswith('```'):
            cleaned = cleaned.split('\n', 1)[1] if '\n' in cleaned else cleaned[3:]
            if cleaned.endswith('```'):
                cleaned = cleaned[:-3]
            cleaned = cleaned.strip()
            if cleaned.startswith('json'):
                cleaned = cleaned[4:].strip()
        return json.loads(cleaned)
    except json.JSONDecodeError:
        # Try to find JSON in the response
        import re
        json_match = re.search(r'[\[{].*[\]}]', response, re.DOTALL)
        if json_match:
            try:
                return json.loads(json_match.group())
            except json.JSONDecodeError:
                pass
        log.error(f'Failed to parse JSON from response: {response[:200]}')
        return None

# ─────────────────────────────────────────────
# Supabase Helper
# ─────────────────────────────────────────────

def supabase_get(table: str, params: dict = None) -> list:
    """GET from Supabase REST API."""
    resp = requests.get(f'{SUPABASE_URL}/rest/v1/{table}', headers=HEADERS, params=params or {})
    resp.raise_for_status()
    return resp.json()

def supabase_post(table: str, data: dict | list) -> list:
    """POST to Supabase REST API."""
    resp = requests.post(f'{SUPABASE_URL}/rest/v1/{table}', headers=HEADERS, json=data)
    resp.raise_for_status()
    return resp.json()

def supabase_patch(table: str, data: dict, params: dict) -> list:
    """PATCH Supabase REST API."""
    resp = requests.patch(f'{SUPABASE_URL}/rest/v1/{table}', headers=HEADERS, json=data, params=params)
    resp.raise_for_status()
    return resp.json()

def get_card_pool_count() -> int:
    """Get count of published cards in the pool."""
    resp = requests.get(
        f'{SUPABASE_URL}/rest/v1/cards',
        headers={**HEADERS, 'Prefer': 'count=exact'},
        params={'status': 'eq.published', 'select': 'id'}
    )
    count = resp.headers.get('content-range', '*/0').split('/')[-1]
    return int(count) if count != '*' else 0

# ─────────────────────────────────────────────
# AGENT 1: SCOUT
# ─────────────────────────────────────────────

def run_scout(count: int = 30) -> list[dict]:
    """Generate content briefs — what should we write about?"""
    log.info(f'🔍 SCOUT: Generating {count} content briefs...')

    # Get current pool distribution
    pool_stats = {}
    for topic in TOPICS:
        cards = supabase_get('cards', {
            'select': 'id',
            'status': 'eq.published',
            'topic': f'eq.{topic}'
        })
        pool_stats[topic] = len(cards)

    total = sum(pool_stats.values()) or 1
    underrepresented = sorted(pool_stats.items(), key=lambda x: x[1])

    system_prompt = """You are a content research agent for Glintup, a daily learning app.
Your job is to come up with fascinating, engaging topic ideas that make people say "wow, I didn't know that!"

Guidelines:
- Topics should be surprising, counterintuitive, or mind-expanding
- Mix fun facts, deep insights, inspiring stories, and thought-provoking questions
- Avoid controversial politics, religion, or sensitive topics
- Each idea should be specific enough to write a card about (not vague)
- Include a mix of difficulties (some easy, some challenging)"""

    user_prompt = f"""Generate {count} content brief ideas as a JSON array.

Current pool distribution (prioritize topics with fewer cards):
{json.dumps(pool_stats, indent=2)}

For each brief, provide:
{{
  "topic": "one of: {', '.join(TOPICS)}",
  "subtopic": "specific area within the topic",
  "angle": "the specific hook or angle (1-2 sentences)",
  "suggested_card_type": "one of: {', '.join(CARD_TYPES)}",
  "difficulty": 1-5 (1=easy, 5=expert),
  "priority": "high/medium/low"
}}

Return a JSON array of {count} objects. Prioritize underrepresented topics: {', '.join([t[0] for t in underrepresented[:3]])}"""

    briefs = call_ollama_json(system_prompt, user_prompt, temperature=0.8)

    if not briefs or not isinstance(briefs, list):
        log.error('Scout failed to generate briefs')
        return []

    log.info(f'🔍 SCOUT: Generated {len(briefs)} briefs')

    # Save briefs to database
    for brief in briefs:
        try:
            supabase_post('content_briefs', {
                'topic': brief.get('topic', 'science'),
                'subtopic': brief.get('subtopic', ''),
                'angle': brief.get('angle', ''),
                'suggested_card_type': brief.get('suggested_card_type', 'quick_fact'),
                'difficulty': brief.get('difficulty', 3),
                'priority': brief.get('priority', 'medium'),
                'status': 'pending'
            })
        except Exception as e:
            log.warning(f'Failed to save brief: {e}')

    return briefs

# ─────────────────────────────────────────────
# AGENT 2: WRITER
# ─────────────────────────────────────────────

WRITER_PROMPTS = {
    'quick_fact': """Write a Quick Fact card. Requirements:
- Title: punchy, attention-grabbing (max 10 words)
- Body: 2-3 sentences max. Lead with the surprising fact.
- Summary: one-line takeaway
- Include source_name if referencing specific research
Example: "Octopuses have three hearts and blue blood"
Output must be concise and impactful.""",

    'insight': """Write an Insight card. Requirements:
- Title: frames the key insight (max 10 words)
- Body: 3-5 sentences explaining the insight and why it matters
- Summary: the key takeaway (this appears in a highlighted box)
- Should make the reader think differently about something
Example: "The 10,000 hour rule is misleading — deliberate practice matters more than hours".""",

    'visual': """Write a Visual card. Requirements:
- Title: descriptive, evocative (max 10 words)
- Body: 2-3 sentences describing what makes this visual/concept remarkable
- image_search_term: a specific search term to find a relevant image on Unsplash
- Summary: one-line caption
Focus on things that are visually stunning or conceptually beautiful.""",

    'story': """Write a Story card. Requirements:
- Title: narrative hook (max 10 words)
- Body: 200-300 words telling a compelling story
- Use markdown for formatting (paragraphs, *emphasis*)
- Start with a scene or moment, build tension, deliver the insight
- Summary: the lesson or moral
Example topic: "The janitor who secretly funded 33 scholarships".""",

    'deep_read': """Write a Deep Read card. Requirements:
- Title: thought-provoking (max 10 words)
- Body: 400-500 words, well-structured
- Use markdown: ## subheadings, paragraphs, > blockquotes for key quotes
- Include multiple perspectives or layers of analysis
- Summary: key takeaway for the highlight box
This is the longest card type — make every paragraph count.""",

    'question': """Write a Question card. Requirements:
- question_text: a thought-provoking question (1-2 sentences)
- answer_options: exactly 4 options as a JSON array of strings
- correct_answer_index: 0-3 indicating which option is correct
- correct_answer_explanation: 2-3 sentences explaining why
- title: the topic area
- Make wrong answers plausible but clearly wrong when explained
Example: "What percentage of the ocean floor has been mapped?" A) 5% B) 20% C) 50% D) 80%""",

    'quote': """Write a Quote card. Requirements:
- body: the exact quote (MUST be a real, verified quote — do not make up quotes)
- source_name: the person who said it (full name)
- subtitle: brief context about who they are (max 8 words)
- summary: why this quote matters (1 sentence)
- title: thematic title (max 5 words)
Choose quotes that are profound, surprising, or beautifully expressed."""
}

def run_writer(brief: dict) -> dict | None:
    """Write a single card from a brief."""
    card_type = brief.get('suggested_card_type', 'quick_fact')
    topic = brief.get('topic', 'science')
    angle = brief.get('angle', '')
    difficulty = brief.get('difficulty', 3)

    type_prompt = WRITER_PROMPTS.get(card_type, WRITER_PROMPTS['quick_fact'])

    system_prompt = f"""You are an expert content writer for Glintup, a premium daily learning app.
You write engaging, accurate, well-crafted learning cards.

Card Type: {card_type}
{type_prompt}

Tone: Curious, clear, authoritative but friendly. Like a brilliant friend explaining something fascinating.
Difficulty: {difficulty}/5
"""

    user_prompt = f"""Write a {card_type} card about: {angle}
Topic: {topic}
Subtopic: {brief.get('subtopic', '')}

Return as JSON:
{{
  "title": "...",
  "subtitle": "...",
  "body": "...",
  "summary": "...",
  "source_name": "...",
  "source_url": "",
  "image_url": "",
  "image_search_term": "",
  "question_text": "",
  "answer_options": [],
  "correct_answer_index": null,
  "correct_answer_explanation": "",
  "estimated_read_seconds": 30,
  "tags": ["tag1", "tag2"]
}}

Fill only the fields relevant to this card type. Leave others as empty strings or null."""

    card_data = call_ollama_json(system_prompt, user_prompt, temperature=0.7)

    if not card_data or not isinstance(card_data, dict):
        log.error(f'Writer failed for brief: {angle}')
        return None

    # Build card record
    card = {
        'card_type': card_type,
        'status': 'draft',
        'topic': topic,
        'subtopic': brief.get('subtopic', ''),
        'difficulty_level': difficulty,
        'title': card_data.get('title', ''),
        'subtitle': card_data.get('subtitle', ''),
        'body': card_data.get('body', ''),
        'summary': card_data.get('summary', ''),
        'source_name': card_data.get('source_name', ''),
        'source_url': card_data.get('source_url', ''),
        'image_url': card_data.get('image_url', ''),
        'tags': card_data.get('tags', []),
        'estimated_read_seconds': card_data.get('estimated_read_seconds', 30),
    }

    # Handle question-specific fields
    if card_type == 'question':
        card['question_text'] = card_data.get('question_text', '')
        options = card_data.get('answer_options', [])
        correct_idx = card_data.get('correct_answer_index', 0)
        card['answer_options'] = json.dumps(options) if isinstance(options, list) else '[]'
        card['correct_answer_explanation'] = card_data.get('correct_answer_explanation', '')

    return card

# ─────────────────────────────────────────────
# AGENT 3: REVIEWER
# ─────────────────────────────────────────────

def run_reviewer(card: dict) -> dict:
    """Review and score a card."""
    system_prompt = """You are a quality reviewer for Glintup, a premium learning app.
Score each card on 5 dimensions (1-5 each):

1. ACCURACY: Are facts correct? Any potential hallucination?
2. ENGAGEMENT: Would someone want to read this? Is the hook strong?
3. CLARITY: Easy to understand at the target difficulty level?
4. FORMATTING: Correct length? Proper structure for the card type?
5. UNIQUENESS: Is this interesting and non-obvious?

Be strict. Score 4+ only for genuinely good content.
Flag any factual claims that need verification."""

    user_prompt = f"""Review this {card.get('card_type', 'unknown')} card:

Title: {card.get('title', '')}
Body: {card.get('body', '')}
Summary: {card.get('summary', '')}
Topic: {card.get('topic', '')}
Difficulty: {card.get('difficulty_level', 3)}/5

Return JSON:
{{
  "accuracy": 1-5,
  "engagement": 1-5,
  "clarity": 1-5,
  "formatting": 1-5,
  "uniqueness": 1-5,
  "overall_score": 1-5 (average rounded),
  "feedback": "brief feedback",
  "accuracy_flag": true/false (true if facts need human verification),
  "suggested_improvements": "what to fix if score < 4"
}}"""

    review = call_ollama_json(system_prompt, user_prompt, temperature=0.3)

    if not review or not isinstance(review, dict):
        return {'overall_score': 3, 'feedback': 'Review failed', 'accuracy_flag': True}

    return review

# ─────────────────────────────────────────────
# AGENT 4: EDITOR
# ─────────────────────────────────────────────

def run_editor(card: dict, review: dict) -> dict:
    """Polish and finalize a card based on review feedback."""
    system_prompt = """You are a senior editor for Glintup, a premium learning app.
Your job is to polish cards to perfection:

- Strengthen the opening hook (first sentence must grab attention)
- Trim unnecessary words (be concise)
- Ensure consistent tone (curious, clear, authoritative but warm)
- Fix any issues mentioned in the review feedback
- Make sure the summary captures the key takeaway perfectly
- For quotes: verify attribution format is "— Full Name"
- For questions: ensure all 4 options are plausible"""

    user_prompt = f"""Polish this {card.get('card_type', '')} card.

Current card:
{json.dumps({k: card[k] for k in ['title', 'subtitle', 'body', 'summary', 'source_name'] if k in card}, indent=2)}

Review feedback: {review.get('feedback', 'None')}
Suggested improvements: {review.get('suggested_improvements', 'None')}

Return the COMPLETE polished card as JSON with these fields:
{{
  "title": "...",
  "subtitle": "...",
  "body": "...",
  "summary": "...",
  "source_name": "..."
}}

Only return the fields that need updating. Keep what's already good."""

    edited = call_ollama_json(system_prompt, user_prompt, temperature=0.4)

    if edited and isinstance(edited, dict):
        # Merge edits into original card
        for key in ['title', 'subtitle', 'body', 'summary', 'source_name']:
            if key in edited and edited[key]:
                card[key] = edited[key]

    return card

# ─────────────────────────────────────────────
# ORCHESTRATOR
# ─────────────────────────────────────────────

def run_pipeline():
    """Run the complete content generation pipeline."""
    start_time = time.time()
    run_date = datetime.now(timezone.utc).isoformat()

    log.info('=' * 50)
    log.info('🚀 GLINTUP CONTENT PIPELINE STARTED')
    log.info(f'   Model: {OLLAMA_MODEL}')
    log.info(f'   Cards to generate: {CARDS_PER_RUN}')
    log.info('=' * 50)

    stats = {
        'briefs_generated': 0,
        'cards_drafted': 0,
        'cards_passed': 0,
        'cards_rejected': 0,
        'cards_published': 0,
        'errors': []
    }

    # Check current pool
    pool_count = get_card_pool_count()
    log.info(f'📊 Current card pool: {pool_count} published cards')

    # AGENT 1: SCOUT
    briefs = run_scout(CARDS_PER_RUN)
    stats['briefs_generated'] = len(briefs)

    if not briefs:
        log.error('Scout produced no briefs. Aborting.')
        return stats

    # AGENT 2 + 3 + 4: Write → Review → Edit for each brief
    for i, brief in enumerate(briefs):
        try:
            log.info(f'\n--- Card {i+1}/{len(briefs)}: {brief.get("angle", "unknown")[:60]} ---')

            # WRITE
            card = run_writer(brief)
            if not card:
                stats['errors'].append(f'Writer failed for brief {i+1}')
                continue
            stats['cards_drafted'] += 1
            log.info(f'  ✍️  Written: {card.get("title", "untitled")}')

            # REVIEW
            review = run_reviewer(card)
            score = review.get('overall_score', 0)
            log.info(f'  📋 Review score: {score}/5 — {review.get("feedback", "")[:80]}')

            card['quality_score'] = score

            if score < MIN_QUALITY_SCORE:
                stats['cards_rejected'] += 1
                log.info(f'  ❌ Rejected (score {score} < {MIN_QUALITY_SCORE})')

                # Try rewrite for score 3
                if score == 3:
                    log.info(f'  🔄 Attempting rewrite...')
                    card = run_writer(brief)
                    if card:
                        review2 = run_reviewer(card)
                        score2 = review2.get('overall_score', 0)
                        if score2 >= MIN_QUALITY_SCORE:
                            card['quality_score'] = score2
                            review = review2
                            score = score2
                            stats['cards_rejected'] -= 1
                            log.info(f'  ✅ Rewrite passed with score {score2}')
                        else:
                            log.info(f'  ❌ Rewrite also failed (score {score2})')
                            continue
                    else:
                        continue
                else:
                    continue

            stats['cards_passed'] += 1

            # EDIT
            card = run_editor(card, review)
            log.info(f'  ✏️  Edited: {card.get("title", "untitled")}')

            # Publish to Supabase
            card['status'] = 'published'
            card['published_at'] = datetime.now(timezone.utc).isoformat()

            # Clean up card for database
            db_card = {k: v for k, v in card.items() if v is not None and v != ''}
            if 'answer_options' in db_card and isinstance(db_card['answer_options'], str):
                db_card['answer_options'] = json.loads(db_card['answer_options'])

            try:
                supabase_post('cards', db_card)
                stats['cards_published'] += 1
                log.info(f'  ✅ Published: {card.get("title", "untitled")}')
            except Exception as e:
                stats['errors'].append(f'DB insert failed: {e}')
                log.error(f'  ❌ DB insert failed: {e}')

        except Exception as e:
            stats['errors'].append(f'Card {i+1} error: {str(e)}')
            log.error(f'  ❌ Error processing card {i+1}: {e}')

    # Log pipeline run
    duration = int(time.time() - start_time)
    log.info(f'\n{"=" * 50}')
    log.info(f'📊 PIPELINE COMPLETE')
    log.info(f'   Duration: {duration}s ({duration//60}m {duration%60}s)')
    log.info(f'   Briefs: {stats["briefs_generated"]}')
    log.info(f'   Drafted: {stats["cards_drafted"]}')
    log.info(f'   Passed review: {stats["cards_passed"]}')
    log.info(f'   Rejected: {stats["cards_rejected"]}')
    log.info(f'   Published: {stats["cards_published"]}')
    log.info(f'   Errors: {len(stats["errors"])}')
    log.info(f'{"=" * 50}')

    # Save pipeline run to database
    try:
        supabase_post('pipeline_runs', {
            'run_date': run_date,
            'briefs_generated': stats['briefs_generated'],
            'cards_drafted': stats['cards_drafted'],
            'cards_passed': stats['cards_passed'],
            'cards_rejected': stats['cards_rejected'],
            'cards_published': stats['cards_published'],
            'duration_seconds': duration,
            'errors': json.dumps(stats['errors']) if stats['errors'] else None
        })
    except Exception as e:
        log.error(f'Failed to log pipeline run: {e}')

    return stats

# ─────────────────────────────────────────────
# API SERVER (for admin dashboard)
# ─────────────────────────────────────────────

def start_api_server():
    """Simple HTTP API for admin dashboard to trigger/monitor pipeline."""
    from http.server import HTTPServer, BaseHTTPRequestHandler
    import threading

    pipeline_status = {'running': False, 'last_run': None, 'last_stats': None}

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path == '/health':
                self._respond(200, {'status': 'ok', 'model': OLLAMA_MODEL})
            elif self.path == '/status':
                self._respond(200, pipeline_status)
            elif self.path == '/pool-count':
                count = get_card_pool_count()
                self._respond(200, {'count': count})
            else:
                self._respond(404, {'error': 'Not found'})

        def do_POST(self):
            if self.path == '/run':
                if pipeline_status['running']:
                    self._respond(409, {'error': 'Pipeline already running'})
                    return

                def run_in_background():
                    pipeline_status['running'] = True
                    try:
                        stats = run_pipeline()
                        pipeline_status['last_stats'] = stats
                        pipeline_status['last_run'] = datetime.now(timezone.utc).isoformat()
                    finally:
                        pipeline_status['running'] = False

                threading.Thread(target=run_in_background, daemon=True).start()
                self._respond(202, {'message': 'Pipeline started'})
            else:
                self._respond(404, {'error': 'Not found'})

        def _respond(self, code, data):
            self.send_response(code)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())

        def do_OPTIONS(self):
            self._respond(200, {})

        def log_message(self, format, *args):
            pass  # Suppress default logging

    server = HTTPServer(('0.0.0.0', 8080), Handler)
    log.info('🌐 API server running on port 8080')
    server.serve_forever()

if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == 'serve':
        # Run API server (for admin dashboard)
        import threading
        # Start API server in background
        api_thread = threading.Thread(target=start_api_server, daemon=True)
        api_thread.start()

        # Keep main thread alive
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            log.info('Shutting down...')
    elif len(sys.argv) > 1 and sys.argv[1] == 'run':
        # Run pipeline once
        run_pipeline()
    else:
        print('Usage:')
        print('  python run_pipeline.py run    — Run pipeline once')
        print('  python run_pipeline.py serve  — Start API server')
PYEOF

chmod +x /opt/glintup/pipeline/run_pipeline.py
print_step "Pipeline script created"

# 8. Create systemd service for the API server
cat > /etc/systemd/system/glintup-pipeline.service << 'SVCEOF'
[Unit]
Description=Glintup Content Pipeline API
After=network.target ollama.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/glintup
Environment=PATH=/opt/glintup/venv/bin:/usr/bin:/bin
ExecStart=/opt/glintup/venv/bin/python /opt/glintup/pipeline/run_pipeline.py serve
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable glintup-pipeline
systemctl start glintup-pipeline
print_step "Pipeline API service created and started"

# 9. Set up daily cron job (runs at 2 AM UTC)
(crontab -l 2>/dev/null; echo "0 2 * * * cd /opt/glintup && /opt/glintup/venv/bin/python /opt/glintup/pipeline/run_pipeline.py run >> /opt/glintup/logs/cron.log 2>&1") | crontab -
print_step "Daily cron job set (2 AM UTC)"

# 10. Open firewall for API
ufw allow 8080/tcp 2>/dev/null || iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
print_step "Firewall opened for port 8080"

echo ""
echo "============================================"
echo -e "${GREEN}  SETUP COMPLETE!${NC}"
echo "============================================"
echo ""
echo "  Ollama:    http://localhost:11434"
echo "  Pipeline:  http://$(curl -s ifconfig.me):8080"
echo "  Model:     Qwen2.5 32B"
echo ""
echo "  Next steps:"
echo "  1. Edit /opt/glintup/.env and add your SUPABASE_SERVICE_ROLE_KEY"
echo "  2. Run: systemctl restart glintup-pipeline"
echo "  3. Test: curl http://localhost:8080/health"
echo "  4. Generate cards: curl -X POST http://localhost:8080/run"
echo ""
echo "  Logs: tail -f /opt/glintup/logs/pipeline.log"
echo "  Cron: runs daily at 2 AM UTC"
echo ""
