---
name: smoke-check
description: "Offline pack validation plus real Godot and device QA gate; adapted from CCGS /smoke-check"
user-invocable: true
---
Run `python tools/validate.py` and `python -m unittest discover -s tests -v`; import with Godot 4.7.2 and run its judge test. Then check every item in `production/qa/CHECKLIST.md` with real evidence. Record NOT_RUN/NOT_VERIFIED separately; never infer visual/manual QA from import or build. No runtime shell hooks are installed. This is a **project-authored adaptation**, not the upstream CCGS skill.
