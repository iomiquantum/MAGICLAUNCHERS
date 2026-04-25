#!/usr/bin/env python3
"""
Token & Session Control
Parses ~/.claude/projects/ JSONL files and serves a live dashboard.
No external dependencies — uses only Python stdlib.
"""

import json
import os
import glob
import csv
import io
import http.server
import socketserver
import time
import logging
from datetime import datetime, timezone, timedelta
from collections import defaultdict
from pathlib import Path

logging.basicConfig(level=logging.WARNING, format='%(asctime)s %(levelname)s: %(message)s')
logger = logging.getLogger("claude-dashboard")

PORT = 8420
CLAUDE_DIR = os.path.expanduser("~/.claude/projects")

# ============================================================
# LIMITES - Plan Max $100
# ============================================================
LIMITS = {
    "plan": "Max $100",
    "models": {
        "opus":   {"tokens_per_day": 1_000_000,  "requests_per_day": 200},
        "sonnet": {"tokens_per_day": 5_000_000,  "requests_per_day": 1000},
        "haiku":  {"tokens_per_day": 10_000_000, "requests_per_day": 2000},
    }
}

# ============================================================
# REAL CLAUDE LIMITS — Max $100 Plan
# These match the claude.ai/settings "Uso" page
# Adjust reset times to match YOUR account
# ============================================================
PLAN_LIMITS = {
    "plan": "Max $100",

    # Session window (rolling ~5 hours based on claude.ai observation)
    "session_window_minutes": 300,

    # Weekly limit: All models combined
    # Reset: Tuesday 12:00 AM (adjust to your timezone)
    "weekly_all_models": {
        "reset_day": "tuesday",    # day of week
        "reset_hour": 0,           # 0 = midnight
        "reset_minute": 0,
    },

    # Weekly limit: Sonnet only (separate, larger pool)
    # Reset: Wednesday 2:00 PM
    "weekly_sonnet": {
        "reset_day": "wednesday",
        "reset_hour": 14,          # 2 PM
        "reset_minute": 0,
    },
}

# ============================================================
# DAILY BUDGET - Personal daily token goals per model
# ============================================================
DAILY_BUDGET = {
    "opus": 500_000,
    "sonnet": 2_000_000,
    "haiku": 5_000_000,
}

# ============================================================
# API PRICING (per million tokens, for cost estimation reference)
# ============================================================
API_PRICES = {
    "opus":   {"input": 5.0,   "output": 25.0},   # Opus 4.6 pricing
    "sonnet": {"input": 3.0,   "output": 15.0},
    "haiku":  {"input": 1.0,   "output": 5.0},     # Haiku 4.5 pricing
}


_cache = {"data": None, "timestamp": 0, "records": None, "meta": None}
CACHE_TTL = 30  # seconds


def get_cached_data():
    """Return cached parsed data, refreshing if stale."""
    now = time.time()
    if _cache["data"] is not None and (now - _cache["timestamp"]) < CACHE_TTL:
        return _cache["data"]

    records, session_meta = parse_all_data()
    data = aggregate_data(records, session_meta)
    _cache["data"] = data
    _cache["timestamp"] = now
    _cache["records"] = records
    _cache["meta"] = session_meta
    return data


def get_model_family(model):
    if "opus" in model:
        return "opus"
    elif "sonnet" in model:
        return "sonnet"
    elif "haiku" in model:
        return "haiku"
    return "other"


def parse_all_data():
    """Parse all JSONL files and extract usage, user messages, assistant responses, and tool actions."""
    records = []
    session_meta = defaultdict(lambda: {
        "user_messages": [],
        "assistant_summaries": [],
        "tools_used": [],
        "files_touched": set(),
        "cwd": None,
        "models": set(),
    })

    jsonl_files = glob.glob(os.path.join(CLAUDE_DIR, "**", "*.jsonl"), recursive=True)

    for filepath in jsonl_files:
        try:
            with open(filepath, "r") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        obj = json.loads(line)
                    except json.JSONDecodeError:
                        logger.warning(f"Failed to parse line in {filepath}: invalid JSON")
                        continue

                    sid = obj.get("sessionId", "unknown")
                    ts = obj.get("timestamp")

                    # Capture user messages
                    if obj.get("type") == "user":
                        msg = obj.get("message", {})
                        content = msg.get("content", "")
                        if isinstance(content, str) and content.strip():
                            text = content.strip()
                            # Skip very short messages like "ok", "si", "no"
                            if len(text) > 5:
                                session_meta[sid]["user_messages"].append({
                                    "text": text[:200],
                                    "ts": ts,
                                })
                        if obj.get("cwd"):
                            session_meta[sid]["cwd"] = obj["cwd"]
                        continue

                    if obj.get("type") != "assistant":
                        continue

                    msg = obj.get("message", {})
                    usage = msg.get("usage")
                    model = msg.get("model")

                    if obj.get("cwd"):
                        session_meta[sid]["cwd"] = obj["cwd"]

                    # Extract tool uses and assistant text
                    for block in msg.get("content", []):
                        if block.get("type") == "text":
                            text = block["text"].strip()
                            # Capture first meaningful assistant text as summary
                            if len(text) > 20 and len(session_meta[sid]["assistant_summaries"]) < 5:
                                session_meta[sid]["assistant_summaries"].append(text[:150])
                        elif block.get("type") == "tool_use":
                            tool_name = block.get("name", "")
                            tool_input = block.get("input", {})
                            # Track tool types
                            if tool_name in ("Write", "Edit"):
                                fp = tool_input.get("file_path", "")
                                if fp:
                                    # Shorten path
                                    short = Path(fp).name
                                    session_meta[sid]["files_touched"].add(short)
                                    session_meta[sid]["tools_used"].append(f"Edito {short}")
                            elif tool_name == "Bash":
                                cmd = tool_input.get("command", "")[:60]
                                desc = tool_input.get("description", "")
                                if desc:
                                    session_meta[sid]["tools_used"].append(desc[:60])
                                elif cmd:
                                    session_meta[sid]["tools_used"].append(f"$ {cmd[:50]}")
                            elif tool_name == "Agent":
                                desc = tool_input.get("description", "subagent")
                                session_meta[sid]["tools_used"].append(f"Agent: {desc}")

                    if not usage or not model or not ts:
                        continue
                    if not model.startswith("claude-"):
                        continue

                    session_meta[sid]["models"].add(model)

                    records.append({
                        "model": model,
                        "timestamp": ts,
                        "input_tokens": usage.get("input_tokens", 0),
                        "output_tokens": usage.get("output_tokens", 0),
                        "cache_creation_input_tokens": usage.get("cache_creation_input_tokens", 0),
                        "cache_read_input_tokens": usage.get("cache_read_input_tokens", 0),
                        "session_id": sid,
                    })
        except Exception as e:
            logger.warning(f"Failed to read file {filepath}: {e}")
            continue

    # Build session descriptions
    for sid, meta in session_meta.items():
        meta["files_touched"] = list(meta["files_touched"])

    return records, {k: v for k, v in session_meta.items()}


def aggregate_data(records, session_meta):
    now = datetime.now(timezone.utc)
    today_str = now.strftime("%Y-%m-%d")
    yesterday_str = (now - timedelta(days=1)).strftime("%Y-%m-%d")
    window_5h = now - timedelta(hours=5)
    window_2h = now - timedelta(hours=2)

    daily_by_model = defaultdict(lambda: defaultdict(lambda: {"input": 0, "output": 0, "requests": 0}))
    hourly_by_model = defaultdict(lambda: defaultdict(lambda: {"input": 0, "output": 0, "requests": 0}))
    slots_by_model = defaultdict(lambda: defaultdict(lambda: {"input": 0, "output": 0, "requests": 0}))
    slot_names = {0: "Madrugada (0-6)", 1: "Manana (6-12)", 2: "Tarde (12-18)", 3: "Noche (18-24)"}

    today_by_model = defaultdict(lambda: {"input": 0, "output": 0, "total": 0, "requests": 0})
    yesterday_by_family = defaultdict(lambda: {"input": 0, "output": 0, "tokens": 0, "requests": 0})
    rolling_by_family = defaultdict(lambda: {"tokens": 0, "requests": 0})
    rate_by_family = defaultdict(lambda: {"tokens": 0})

    # ALL sessions (not just today)
    all_sessions = defaultdict(lambda: {
        "tokens": 0, "input": 0, "output": 0, "requests": 0,
        "models": set(), "families": set(),
        "first_ts": None, "last_ts": None, "date": None,
    })

    for r in records:
        try:
            ts = datetime.fromisoformat(r["timestamp"].replace("Z", "+00:00"))
        except Exception:
            continue

        date_str = ts.strftime("%Y-%m-%d")
        hour = ts.hour
        model = r["model"]
        family = get_model_family(model)
        total_tokens = r["input_tokens"] + r["output_tokens"]
        sid = r["session_id"]

        # Daily
        d = daily_by_model[date_str][model]
        d["input"] += r["input_tokens"]
        d["output"] += r["output_tokens"]
        d["requests"] += 1

        # Session tracking (ALL sessions)
        sess = all_sessions[sid]
        sess["tokens"] += total_tokens
        sess["input"] += r["input_tokens"]
        sess["output"] += r["output_tokens"]
        sess["requests"] += 1
        sess["models"].add(model)
        sess["families"].add(family)
        if sess["first_ts"] is None or r["timestamp"] < sess["first_ts"]:
            sess["first_ts"] = r["timestamp"]
            sess["date"] = date_str
        if sess["last_ts"] is None or r["timestamp"] > sess["last_ts"]:
            sess["last_ts"] = r["timestamp"]

        # Yesterday
        if date_str == yesterday_str:
            y = yesterday_by_family[family]
            y["input"] += r["input_tokens"]
            y["output"] += r["output_tokens"]
            y["tokens"] += total_tokens
            y["requests"] += 1

        # Today
        if date_str == today_str:
            h = hourly_by_model[hour][model]
            h["input"] += r["input_tokens"]
            h["output"] += r["output_tokens"]
            h["requests"] += 1

            t = today_by_model[model]
            t["input"] += r["input_tokens"]
            t["output"] += r["output_tokens"]
            t["total"] += total_tokens
            t["requests"] += 1

            s = slots_by_model[slot_names[hour // 6]][model]
            s["input"] += r["input_tokens"]
            s["output"] += r["output_tokens"]
            s["requests"] += 1

        # Rolling windows
        if ts >= window_5h:
            rolling_by_family[family]["tokens"] += total_tokens
            rolling_by_family[family]["requests"] += 1
        if ts >= window_2h:
            rate_by_family[family]["tokens"] += total_tokens

    # Limits
    limits_info = {}
    for family in ["opus", "sonnet", "haiku"]:
        rate = rate_by_family[family]["tokens"] / 2
        cfg = LIMITS["models"].get(family, {})
        daily_limit = cfg.get("tokens_per_day", 0)
        req_limit = cfg.get("requests_per_day", 0)
        today_tokens = sum(d["total"] for m, d in today_by_model.items() if get_model_family(m) == family)
        today_input = sum(d["input"] for m, d in today_by_model.items() if get_model_family(m) == family)
        today_output = sum(d["output"] for m, d in today_by_model.items() if get_model_family(m) == family)
        today_reqs = sum(d["requests"] for m, d in today_by_model.items() if get_model_family(m) == family)
        remaining = max(0, daily_limit - today_tokens)
        hours_left = remaining / rate if rate > 0 else None
        pct = (today_tokens / daily_limit * 100) if daily_limit > 0 else 0

        # Cost estimation
        prices = API_PRICES.get(family, {"input": 0, "output": 0})
        cost_input = (today_input / 1_000_000) * prices["input"]
        cost_output = (today_output / 1_000_000) * prices["output"]
        cost_total = cost_input + cost_output

        # Yesterday data
        yd = yesterday_by_family[family]

        # Budget
        budget = DAILY_BUDGET.get(family, 0)
        budget_pct = (today_tokens / budget * 100) if budget > 0 else 0

        limits_info[family] = {
            "daily_limit": daily_limit, "req_limit": req_limit,
            "today_tokens": today_tokens, "today_requests": today_reqs,
            "today_input": today_input, "today_output": today_output,
            "rolling_5h_tokens": rolling_by_family[family]["tokens"],
            "rolling_5h_requests": rolling_by_family[family]["requests"],
            "burn_rate_per_hour": round(rate),
            "remaining_tokens": remaining,
            "hours_remaining": round(hours_left, 1) if hours_left is not None else None,
            "pct_used": round(pct, 1),
            "cost_input": round(cost_input, 4),
            "cost_output": round(cost_output, 4),
            "cost_total": round(cost_total, 4),
            "yesterday_tokens": yd["tokens"],
            "yesterday_requests": yd["requests"],
            "yesterday_input": yd["input"],
            "yesterday_output": yd["output"],
            "budget": budget,
            "budget_pct": round(budget_pct, 1),
            "budget_remaining": max(0, budget - today_tokens),
        }

    # Build sessions list with metadata and descriptions
    sessions_list = []
    for sid, s in all_sessions.items():
        if not s["first_ts"]:
            continue
        meta = session_meta.get(sid, {})
        cwd = meta.get("cwd") or ""
        if cwd.startswith("/Users/"):
            parts = cwd.split("/")
            if len(parts) > 3:
                cwd = "~/" + "/".join(parts[3:])

        # Build title from first meaningful user message
        user_msgs = sorted(meta.get("user_messages", []), key=lambda x: x.get("ts", ""))
        title = "Sin titulo"
        for um in user_msgs:
            if len(um["text"]) > 5:
                title = um["text"][:120]
                break

        # Build description: combine user requests
        user_topics = []
        for um in user_msgs[:10]:
            text = um["text"]
            if len(text) > 5 and text not in user_topics:
                user_topics.append(text)
        description_lines = [t[:150] for t in user_topics[:6]]
        description = " → ".join(description_lines) if description_lines else ""

        # Build actions summary from tools
        tools = meta.get("tools_used", [])
        files = meta.get("files_touched", [])
        assistant_texts = meta.get("assistant_summaries", [])

        # Deduplicate similar tool entries
        seen_tools = set()
        unique_tools = []
        for t in tools:
            key = t[:30]
            if key not in seen_tools:
                seen_tools.add(key)
                unique_tools.append(t)

        actions_summary = unique_tools[:8]
        files_list = files[:10]

        # Pick best assistant summary (first one that's descriptive)
        assistant_summary = ""
        for at in assistant_texts:
            if len(at) > 30:
                assistant_summary = at
                break

        try:
            t1 = datetime.fromisoformat(s["first_ts"].replace("Z", "+00:00"))
            t2 = datetime.fromisoformat(s["last_ts"].replace("Z", "+00:00"))
            duration_min = max(1, int((t2 - t1).total_seconds() / 60))
        except Exception:
            duration_min = 0

        sessions_list.append({
            "id": sid[:8],
            "full_id": sid,
            "title": title,
            "description": description,
            "actions": actions_summary,
            "files": files_list,
            "assistant_summary": assistant_summary,
            "cwd": cwd,
            "models": sorted(s["models"]),
            "families": sorted(s["families"]),
            "tokens": s["tokens"],
            "input": s["input"],
            "output": s["output"],
            "requests": s["requests"],
            "date": s["date"],
            "start": s["first_ts"],
            "end": s["last_ts"],
            "duration_min": duration_min,
        })
    sessions_list.sort(key=lambda x: x["end"] or "", reverse=True)

    # ---- daily_totals for heatmap (all days) ----
    daily_totals_map = {}
    for date_str, models_data in daily_by_model.items():
        day_tokens = 0
        day_input = 0
        day_output = 0
        day_requests = 0
        model_tokens = {}
        for m, d in models_data.items():
            t = d["input"] + d["output"]
            day_tokens += t
            day_input += d["input"]
            day_output += d["output"]
            day_requests += d["requests"]
            fam = get_model_family(m)
            model_tokens[fam] = model_tokens.get(fam, 0) + t
        top_model = max(model_tokens, key=model_tokens.get) if model_tokens else "none"
        daily_totals_map[date_str] = {
            "tokens": day_tokens,
            "input": day_input,
            "output": day_output,
            "requests": day_requests,
            "top_model": top_model,
        }

    # ---- Predictions (last 7 days) ----
    all_dates_sorted = sorted(daily_by_model.keys())
    last_7_dates = all_dates_sorted[-7:] if len(all_dates_sorted) >= 7 else all_dates_sorted
    last_3_dates = all_dates_sorted[-3:] if len(all_dates_sorted) >= 3 else all_dates_sorted
    prev_4_dates = all_dates_sorted[-7:-3] if len(all_dates_sorted) >= 7 else all_dates_sorted[:max(0, len(all_dates_sorted)-3)]

    predicted_daily = {}
    predicted_week = {}
    last7_by_family = defaultdict(list)
    for dstr in last_7_dates:
        fam_day = defaultdict(int)
        for m, d in daily_by_model[dstr].items():
            fam = get_model_family(m)
            fam_day[fam] += d["input"] + d["output"]
        for fam in ["opus", "sonnet", "haiku"]:
            last7_by_family[fam].append(fam_day.get(fam, 0))

    for fam in ["opus", "sonnet", "haiku"]:
        vals = last7_by_family[fam]
        avg = sum(vals) / len(vals) if vals else 0
        predicted_daily[fam] = round(avg)
        predicted_week[fam] = round(avg * 7)

    # Trend calculation
    last3_avg = {}
    prev4_avg = {}
    for fam in ["opus", "sonnet", "haiku"]:
        l3 = []
        for dstr in last_3_dates:
            t = 0
            for m, d in daily_by_model.get(dstr, {}).items():
                if get_model_family(m) == fam:
                    t += d["input"] + d["output"]
            l3.append(t)
        p4 = []
        for dstr in prev_4_dates:
            t = 0
            for m, d in daily_by_model.get(dstr, {}).items():
                if get_model_family(m) == fam:
                    t += d["input"] + d["output"]
            p4.append(t)
        last3_avg[fam] = sum(l3) / len(l3) if l3 else 0
        prev4_avg[fam] = sum(p4) / len(p4) if p4 else 0

    trends = {}
    for fam in ["opus", "sonnet", "haiku"]:
        if prev4_avg[fam] > 0:
            change_pct = ((last3_avg[fam] - prev4_avg[fam]) / prev4_avg[fam]) * 100
            if change_pct > 10:
                trends[fam] = {"trend": "subiendo", "pct": round(change_pct, 1)}
            elif change_pct < -10:
                trends[fam] = {"trend": "bajando", "pct": round(change_pct, 1)}
            else:
                trends[fam] = {"trend": "estable", "pct": round(change_pct, 1)}
        else:
            trends[fam] = {"trend": "estable", "pct": 0}

    # daily values for sparkline (last 7 days)
    last7_daily_values = {}
    for fam in ["opus", "sonnet", "haiku"]:
        last7_daily_values[fam] = last7_by_family[fam]

    predictions = {
        "predicted_daily_tokens": predicted_daily,
        "predicted_week_total": predicted_week,
        "trends": trends,
        "last7_daily": last7_daily_values,
        "last7_dates": [d[5:] for d in last_7_dates],
    }

    # ---- Efficiency metrics (today) ----
    efficiency = {}
    for fam in ["opus", "sonnet", "haiku"]:
        fam_tokens = 0
        fam_input = 0
        fam_output = 0
        fam_requests = 0
        fam_sessions = 0
        fam_minutes = 0
        for sid, s in all_sessions.items():
            if fam in s["families"]:
                fam_tokens += s["tokens"]
                fam_input += s["input"]
                fam_output += s["output"]
                fam_requests += s["requests"]
                fam_sessions += 1
                if s["first_ts"] and s["last_ts"]:
                    try:
                        t1 = datetime.fromisoformat(s["first_ts"].replace("Z", "+00:00"))
                        t2 = datetime.fromisoformat(s["last_ts"].replace("Z", "+00:00"))
                        if t1.strftime("%Y-%m-%d") == today_str:
                            fam_minutes += max(1, (t2 - t1).total_seconds() / 60)
                    except Exception:
                        pass

        today_tokens_fam = sum(d["total"] for m, d in today_by_model.items() if get_model_family(m) == fam)
        today_input_fam = sum(d["input"] for m, d in today_by_model.items() if get_model_family(m) == fam)
        today_output_fam = sum(d["output"] for m, d in today_by_model.items() if get_model_family(m) == fam)
        today_reqs_fam = sum(d["requests"] for m, d in today_by_model.items() if get_model_family(m) == fam)

        # Count today's sessions for this family
        today_sessions_count = 0
        for sid, s in all_sessions.items():
            if fam in s["families"] and s.get("date") == today_str:
                today_sessions_count += 1

        efficiency[fam] = {
            "tokens_per_minute": round(today_tokens_fam / fam_minutes, 1) if fam_minutes > 0 else 0,
            "output_input_ratio": round(today_output_fam / today_input_fam, 2) if today_input_fam > 0 else 0,
            "avg_tokens_per_request": round(today_tokens_fam / today_reqs_fam) if today_reqs_fam > 0 else 0,
            "avg_session_tokens": round(today_tokens_fam / today_sessions_count) if today_sessions_count > 0 else 0,
        }

    # Charts
    sorted_days = sorted(daily_by_model.keys())[-14:]
    all_models = set()
    for dd in daily_by_model.values():
        all_models.update(dd.keys())
    for hd in hourly_by_model.values():
        all_models.update(hd.keys())
    all_models = sorted(all_models)

    daily_chart = {"labels": sorted_days, "models": {}}
    for model in all_models:
        daily_chart["models"][model] = {
            "input": [daily_by_model[d][model]["input"] for d in sorted_days],
            "output": [daily_by_model[d][model]["output"] for d in sorted_days],
            "requests": [daily_by_model[d][model]["requests"] for d in sorted_days],
        }

    hourly_chart = {"labels": list(range(24)), "models": {}}
    for model in all_models:
        hourly_chart["models"][model] = {
            "input": [hourly_by_model[h][model]["input"] for h in range(24)],
            "output": [hourly_by_model[h][model]["output"] for h in range(24)],
            "requests": [hourly_by_model[h][model]["requests"] for h in range(24)],
        }

    slot_chart = {"labels": list(slot_names.values()), "models": {}}
    for model in all_models:
        slot_chart["models"][model] = {
            "input": [slots_by_model[slot_names[i]][model]["input"] for i in range(4)],
            "output": [slots_by_model[slot_names[i]][model]["output"] for i in range(4)],
            "requests": [slots_by_model[slot_names[i]][model]["requests"] for i in range(4)],
        }

    # ---- Smart Usage Tips ----
    tips = []
    for fam in ["opus", "sonnet", "haiku"]:
        li = limits_info[fam]
        pct = li["pct_used"]
        burn = li["burn_rate_per_hour"]
        hrs = li["hours_remaining"]
        today_in = li["today_input"]
        today_out = li["today_output"]
        yest_tok = li["yesterday_tokens"]
        today_tok = li["today_tokens"]
        out_in_ratio = (today_out / today_in) if today_in > 0 else 0

        # Rule: opus > 50% and sonnet < 20%
        if fam == "opus" and pct > 50:
            sonnet_pct = limits_info["sonnet"]["pct_used"]
            if sonnet_pct < 20:
                tips.append("Tip: Cambia a Sonnet para tareas simples y conserva Opus para lo complejo")

        # Rule: burn_rate high and hours_remaining < 4
        if burn > 0 and hrs is not None and hrs < 4:
            fam_label = fam.capitalize()
            tips.append(f"Tip: A este ritmo te quedan {round(hrs, 1)}h de {fam_label}. Reduce el largo de tus prompts.")

        # Rule: output/input ratio > 5
        if out_in_ratio > 5:
            tips.append(f"Tip: Claude esta generando mucho output en {fam.capitalize()}. Usa instrucciones mas especificas.")

        # Rule: today > yesterday * 1.5
        if yest_tok > 0 and today_tok > yest_tok * 1.5:
            excess_pct = round(((today_tok - yest_tok) / yest_tok) * 100)
            tips.append(f"Tip: Hoy llevas {excess_pct}% mas que ayer en {fam.capitalize()}. Vigila tu consumo.")

    # Rule: most usage in one time slot
    slot_tokens = {}
    for slot_name, models_data in slots_by_model.items():
        total = 0
        for m, d in models_data.items():
            total += d["input"] + d["output"]
        slot_tokens[slot_name] = total
    if slot_tokens:
        total_slot_tokens = sum(slot_tokens.values())
        if total_slot_tokens > 0:
            top_slot = max(slot_tokens, key=slot_tokens.get)
            top_slot_pct = slot_tokens[top_slot] / total_slot_tokens
            if top_slot_pct > 0.7:
                franja = top_slot.split(" ")[0].lower()
                tips.append(f"Tip: Tu uso se concentra en la {franja}. Distribuye tu trabajo para evitar rate limits.")

    # Rule: session with > 50K tokens
    max_session_tokens = 0
    for s in sessions_list:
        if s.get("date") == today_str and s["tokens"] > max_session_tokens:
            max_session_tokens = s["tokens"]
    if max_session_tokens > 50000:
        tips.append(f"Tip: Tu sesion mas grande tiene {round(max_session_tokens/1000)}K tokens. Considera iniciar sesiones nuevas periodicamente.")

    # Default tip
    if not tips:
        tips.append("Tip: Tu uso esta equilibrado. Sigue asi.")

    # Limit to 3 tips
    tips = tips[:3]

    # ---- Real Limits (matching claude.ai settings) ----
    DAY_MAP = {"monday": 0, "tuesday": 1, "wednesday": 2, "thursday": 3,
               "friday": 4, "saturday": 5, "sunday": 6}

    def get_last_reset(reset_cfg):
        """Find the most recent reset datetime for a weekly limit."""
        target_day = DAY_MAP.get(reset_cfg["reset_day"].lower(), 0)
        reset_h = reset_cfg["reset_hour"]
        reset_m = reset_cfg["reset_minute"]
        # Walk backwards from now to find last reset
        candidate = now.replace(hour=reset_h, minute=reset_m, second=0, microsecond=0)
        # Set to this week's target day
        days_since = (now.weekday() - target_day) % 7
        candidate -= timedelta(days=days_since)
        # If candidate is in the future, go back a week
        if candidate > now:
            candidate -= timedelta(weeks=1)
        return candidate

    def get_next_reset(reset_cfg):
        """Find the next reset datetime for a weekly limit."""
        last = get_last_reset(reset_cfg)
        return last + timedelta(weeks=1)

    def time_until(target_dt):
        """Return dict with days, hours, minutes until target."""
        delta = target_dt - now
        if delta.total_seconds() <= 0:
            return {"days": 0, "hours": 0, "minutes": 0, "total_hours": 0}
        total_seconds = delta.total_seconds()
        days = int(total_seconds // 86400)
        hours = int((total_seconds % 86400) // 3600)
        minutes = int((total_seconds % 3600) // 60)
        return {"days": days, "hours": hours, "minutes": minutes,
                "total_hours": round(total_seconds / 3600, 1)}

    # Session window tokens (last N minutes)
    session_window = timedelta(minutes=PLAN_LIMITS["session_window_minutes"])
    session_cutoff = now - session_window
    session_window_tokens = 0
    session_window_by_family = defaultdict(int)
    session_last_activity = None  # Track most recent activity in window
    for r in records:
        try:
            ts = datetime.fromisoformat(r["timestamp"].replace("Z", "+00:00"))
        except Exception:
            continue
        if ts >= session_cutoff:
            total_tok = r["input_tokens"] + r["output_tokens"]
            session_window_tokens += total_tok
            session_window_by_family[get_model_family(r["model"])] += total_tok
            if session_last_activity is None or ts > session_last_activity:
                session_last_activity = ts

    # Weekly all-models tokens (since last reset)
    all_models_reset = get_last_reset(PLAN_LIMITS["weekly_all_models"])
    weekly_tokens_all = 0
    weekly_all_by_family = defaultdict(int)
    for r in records:
        try:
            ts = datetime.fromisoformat(r["timestamp"].replace("Z", "+00:00"))
        except Exception:
            continue
        if ts >= all_models_reset:
            total_tok = r["input_tokens"] + r["output_tokens"]
            weekly_tokens_all += total_tok
            weekly_all_by_family[get_model_family(r["model"])] += total_tok

    # Weekly Sonnet-only tokens (since last Sonnet reset)
    sonnet_reset = get_last_reset(PLAN_LIMITS["weekly_sonnet"])
    weekly_tokens_sonnet = 0
    for r in records:
        try:
            ts = datetime.fromisoformat(r["timestamp"].replace("Z", "+00:00"))
        except Exception:
            continue
        if ts >= sonnet_reset and "sonnet" in r["model"]:
            weekly_tokens_sonnet += r["input_tokens"] + r["output_tokens"]

    next_all_reset = get_next_reset(PLAN_LIMITS["weekly_all_models"])
    next_sonnet_reset = get_next_reset(PLAN_LIMITS["weekly_sonnet"])

    real_limits = {
        "session_window": {
            "window_minutes": PLAN_LIMITS["session_window_minutes"],
            "tokens": session_window_tokens,
            "by_family": dict(session_window_by_family),
            "last_activity": session_last_activity.isoformat() if session_last_activity else None,
            "resets_at": (session_last_activity + session_window).isoformat() if session_last_activity else None,
        },
        "weekly_all_models": {
            "tokens": weekly_tokens_all,
            "by_family": dict(weekly_all_by_family),
            "last_reset": all_models_reset.isoformat(),
            "next_reset": next_all_reset.isoformat(),
            "time_until_reset": time_until(next_all_reset),
            "reset_day": PLAN_LIMITS["weekly_all_models"]["reset_day"],
            "reset_hour": PLAN_LIMITS["weekly_all_models"]["reset_hour"],
            "reset_minute": PLAN_LIMITS["weekly_all_models"]["reset_minute"],
        },
        "weekly_sonnet": {
            "tokens": weekly_tokens_sonnet,
            "last_reset": sonnet_reset.isoformat(),
            "next_reset": next_sonnet_reset.isoformat(),
            "time_until_reset": time_until(next_sonnet_reset),
            "reset_day": PLAN_LIMITS["weekly_sonnet"]["reset_day"],
            "reset_hour": PLAN_LIMITS["weekly_sonnet"]["reset_hour"],
            "reset_minute": PLAN_LIMITS["weekly_sonnet"]["reset_minute"],
        },
    }

    return {
        "daily": daily_chart,
        "hourly": hourly_chart,
        "slots": slot_chart,
        "today": dict(today_by_model),
        "limits": limits_info,
        "sessions": sessions_list,
        "plan": LIMITS["plan"],
        "budget": DAILY_BUDGET,
        "api_prices": API_PRICES,
        "models": all_models,
        "total_records": len(records),
        "generated_at": now.isoformat(),
        "daily_totals": daily_totals_map,
        "predictions": predictions,
        "efficiency": efficiency,
        "tips": tips,
        "real_limits": real_limits,
        "calibration": {
            "weekly_code_tokens": weekly_tokens_all,
            "help": "Ingresa el % semanal de claude.ai para calcular el limite real",
        },
    }


def get_session_chat(session_prefix):
    """Get the full chat history for a session by its ID prefix."""
    jsonl_files = glob.glob(os.path.join(CLAUDE_DIR, "**", "*.jsonl"), recursive=True)
    messages = []

    for filepath in jsonl_files:
        try:
            with open(filepath, "r") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        obj = json.loads(line)
                    except json.JSONDecodeError:
                        logger.warning(f"Failed to parse line in {filepath}: invalid JSON")
                        continue

                    sid = obj.get("sessionId", "")
                    if not sid.startswith(session_prefix):
                        continue

                    ts = obj.get("timestamp", "")
                    msg_type = obj.get("type")

                    if msg_type == "user":
                        content = obj.get("message", {}).get("content", "")
                        if isinstance(content, str) and content.strip():
                            messages.append({
                                "role": "user",
                                "text": content.strip(),
                                "timestamp": ts,
                            })

                    elif msg_type == "assistant":
                        msg = obj.get("message", {})
                        model = msg.get("model", "")
                        usage = msg.get("usage", {})
                        blocks = msg.get("content", [])

                        texts = []
                        tools = []
                        for b in blocks:
                            if b.get("type") == "text" and b.get("text", "").strip():
                                texts.append(b["text"].strip())
                            elif b.get("type") == "tool_use":
                                tool_name = b.get("name", "")
                                tool_input = b.get("input", {})
                                tool_desc = ""
                                if tool_name in ("Write", "Edit"):
                                    fp = tool_input.get("file_path", "")
                                    short = Path(fp).name
                                    tool_desc = f"{tool_name}: {short}"
                                elif tool_name == "Bash":
                                    tool_desc = tool_input.get("description", "") or f"$ {tool_input.get('command', '')[:60]}"
                                elif tool_name == "Read":
                                    fp = tool_input.get("file_path", "")
                                    short = Path(fp).name
                                    tool_desc = f"Read: {short}"
                                elif tool_name == "Agent":
                                    tool_desc = f"Agent: {tool_input.get('description', '')}"
                                elif tool_name in ("Grep", "Glob"):
                                    tool_desc = f"{tool_name}: {tool_input.get('pattern', '')[:40]}"
                                else:
                                    tool_desc = tool_name
                                if tool_desc:
                                    tools.append(tool_desc)

                        combined_text = "\n\n".join(texts)
                        if combined_text or tools:
                            tokens = usage.get("input_tokens", 0) + usage.get("output_tokens", 0)
                            messages.append({
                                "role": "assistant",
                                "text": combined_text,
                                "tools": tools,
                                "model": model,
                                "tokens": tokens,
                                "timestamp": ts,
                            })
        except Exception as e:
            logger.warning(f"Failed to read file {filepath}: {e}")
            continue

    # Sort by timestamp and deduplicate
    messages.sort(key=lambda x: x.get("timestamp", ""))
    # Remove consecutive duplicates (same role + same text)
    deduped = []
    for m in messages:
        if deduped and deduped[-1]["role"] == m["role"] and deduped[-1]["text"] == m["text"]:
            # Merge tools if assistant
            if m["role"] == "assistant" and m.get("tools"):
                deduped[-1].setdefault("tools", []).extend(m["tools"])
            continue
        deduped.append(m)

    return deduped


class DashboardHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/usage":
            data = get_cached_data()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())
        elif self.path.startswith("/api/session/"):
            parts = self.path.split("/api/session/", 1)
            session_id = parts[1].strip() if len(parts) > 1 else ""
            if not session_id:
                self.send_response(400)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"error": "session_id required"}).encode())
                return
            if session_id:
                chat = get_session_chat(session_id)
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps({"messages": chat}).encode())
            else:
                self.send_response(400)
                self.end_headers()
        elif self.path == "/api/export/csv":
            data = get_cached_data()
            output = io.StringIO()
            writer = csv.writer(output)
            writer.writerow(["date", "session_id", "model", "tokens_total", "tokens_input", "tokens_output", "requests", "duration_min", "title", "cwd"])
            for s in data["sessions"]:
                writer.writerow([
                    s.get("date", ""),
                    s.get("full_id", ""),
                    ", ".join(s.get("families", [])),
                    s.get("tokens", 0),
                    s.get("input", 0),
                    s.get("output", 0),
                    s.get("requests", 0),
                    s.get("duration_min", 0),
                    s.get("title", ""),
                    s.get("cwd", ""),
                ])
            csv_bytes = output.getvalue().encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/csv; charset=utf-8")
            self.send_header("Content-Disposition", "attachment; filename=claude_usage_export.csv")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(csv_bytes)
        elif self.path == "/api/export/json":
            data = get_cached_data()
            export_data = json.dumps(data["sessions"], indent=2, ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Disposition", "attachment; filename=claude_usage_export.json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(export_data)
        elif self.path == "/manifest.json":
            manifest_path = os.path.join(os.path.dirname(__file__), "manifest.json")
            try:
                with open(manifest_path, "rb") as f:
                    content = f.read()
                self.send_response(200)
                self.send_header("Content-Type", "application/manifest+json")
                self.end_headers()
                self.wfile.write(content)
            except FileNotFoundError:
                self.send_response(404)
                self.end_headers()
        elif self.path == "/" or self.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            html_path = os.path.join(os.path.dirname(__file__), "index.html")
            with open(html_path, "rb") as f:
                self.wfile.write(f.read())
        else:
            super().do_GET()

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), DashboardHandler) as httpd:
        print(f"Token & Session Control running at http://localhost:{PORT}")
        print(f"Plan: {LIMITS['plan']}")
        print("Press Ctrl+C to stop")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down...")
