---
name: no-slop
description: Review changes and fix sloppy Python code
---

# No Slop

You are reviewing and fixing sloppy Python code in the current branch changes. Follow these steps:

## Step 1: Get Changed Files

Run these commands to see what Python files have changed:

```bash
git diff --name-only HEAD
git diff --staged --name-only
git status --porcelain
```

Filter for `.py` files only.

## Step 2: Analyze Each Changed Python File

For each changed Python file, read the file and check for these violations:

### Rule 1: No Imports Inside Classes or Functions

**Bad:**
```python
class MyClass:
    def my_method(self):
        from some_module import SomeClass  # WRONG
        import json  # WRONG
```

**Good:**
```python
from some_module import SomeClass
import json

class MyClass:
    def my_method(self):
        # use SomeClass and json here
```

### Rule 2: No Relative Imports

**Bad:**
```python
from ..models import User  # WRONG
from .utils import helper  # WRONG
from . import something  # WRONG
```

**Good:**
```python
from myapp.models import User
from myapp.utils import helper
from myapp import something
```

Use absolute imports from the Django app root.

### Rule 3: No Logger (Unless User Requested)

**Remove these unless the user explicitly asked for logging:**
```python
import logging  # REMOVE
logger = logging.getLogger(__name__)  # REMOVE
logger.info(...)  # REMOVE
logger.debug(...)  # REMOVE
logger.error(...)  # REMOVE
logger.warning(...)  # REMOVE
```

## Step 3: Fix the Issues

For each file with violations:

1. Move all imports to the top of the file (after docstrings/comments)
2. Convert relative imports to absolute imports
3. Remove logger imports and usages (unless user requested logging)
4. Preserve the original functionality

## Step 4: Report Changes

After fixing, summarize:
- Which files were modified
- What violations were found and fixed
- Any issues that couldn't be auto-fixed

## Important Notes

- Only modify files that have actual violations
- Preserve existing code formatting where possible
- If unsure about the correct absolute import path, ask the user
- Do NOT add logger unless the user explicitly requests it
