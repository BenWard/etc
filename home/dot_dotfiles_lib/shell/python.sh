# Run pre-commit format/type checks
function pycheck {
  poetry run ruff format
  poetry run ruff check --fix
  poetry run mypy 
}