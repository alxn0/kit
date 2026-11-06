---
description: Python development patterns, tooling (uv, ruff, ty, polars), naming, structure, and testing conventions. Auto-loads when working with .py files.
paths: "**/*.py"
---

# Python Development Patterns

## Language Preferences

- **Python Version**: Target latest, minimum 3.10
- **Code Style**: Follow PEP 8 with 80-character line length
- **Type Hints**: Prefer simple static typing. AVOID using
types from imported modules.

## Tools & Environment

**Code Quality**:
- **Formatting**: `ruff` for consistent formatting
- **Linting**: `ruff` for comprehensive code analysis
- **Type Checking**: `ty` (when using type hints)

**Project Management**:
- **Package Manager**: `uv` primary for project management.
    - `pixi` for `pytorch`, `tensorflow`, `c++` and other dependancies
    that works better in conda ecosystem.
- **Dependencies**: Specified in `pyproject.toml` or `requirements.txt`

## Preferred Libraries

**Data Processing**:
- `polars` (primary DataFrame library)
- `pandas` (when ecosystem requires it)

**Scientific Computing**:
- `scipy` (primary for scientific computing)
- `scikit-learn` (machine learning)
- `numpy` (numerical operations)

**Web Frameworks**:
- `streamlit` (data apps and dashboards)

**Testing**:
- `pytest` with fixtures and parametrization

**Configuration**:
- `dataclasses` for structured config
- `python-dotenv` for environment variables

## Naming Conventions

- **Files & Modules**: `snake_case` (`data_processor.py`)
- **Functions & Variables**: `snake_case` (`process_data`, `user_count`)
- **Classes**: `PascalCase` (`DataProcessor`, `ConfigManager`)
- **Constants**: `SCREAMING_SNAKE_CASE` (`MAX_RETRY_ATTEMPTS`)
- **Private Members**: Single underscore prefix (`_internal_method`)

## Project Structure

**Standard Layout**:
```
project/
├── project_name/          # Source code (flat structure preferred)
├── tests/                 # Test suite
├── docs/                  # Documentation
├── tmp/                   # Temporary files (testing, scratch)
├── pyproject.toml         # Project configuration
└── requirements.txt       # Dependencies (if not using pyproject.toml)
```

**Module Organization**:
- Store modules in `project/project_name` without nested directories
- Use nested directories ONLY when explicitly requested or necessary
- Organize by feature/domain, NOT by technical layer

## Programming Paradigms

**Functional Programming First**:
- PREFER functional programming over class-oriented design
- Use comprehensions for simple transformations
- Use functional programming functions (`map`, `filter`, `reduce`) for complex operations
- Prefer generators for large sequences
- Favor pure functions and immutable data

**Object-Oriented Design** (use only when clear advantage):
- Data objects with `dataclass` that need methods (modify, export, visualize)
- REST clients or API wrappers
- When there's clear benefit for readability and usability

**Class Design Principles**:
- Favor composition over inheritance
- Use `dataclasses` for data containers
- Keep classes focused on single responsibilities
- Avoid unnecessary abstraction

## Data Processing Patterns

**Data Objects**:
- Prefer `dataclass` with type annotations

**DataFrame Operations**:
- Prefer method chaining for readability
- Define schemas explicitly for validation
- Use lazy evaluation for large datasets
- Process data in chunks when memory-constrained

## Error Handling

**Exception Strategy**:
- Create custom exception hierarchies for domain errors
- Validate early with descriptive error messages
- Use specific exceptions over generic ones
- Use context managers for resource cleanup

## Testing Patterns

**Pytest Best Practices**:
- Use fixtures for shared setup/teardown
- Parametrize tests for multiple scenarios
- Test files in `tests/` directory, named `test_*.py`
- One test file per module: `test_data_processor.py`
- Use descriptive test names: `test_process_data_with_invalid_input`

## Performance Considerations

**Optimization Strategy**:
- Leverage lazy evaluation and generators (yield)
- Cache computation with class property decorator

## Common Design Patterns
**Decorators**: Cross-cutting concerns (logging, timing, auth)
