---
name: tests
description: Create unit or integration tests following project patterns. Use when the user needs to create tests for use cases, repositories, tools, or other components.
---

# Create Test

You are creating a test for a component in the Sytex codebase.

## Step 1: Determine Test Type

Ask the user if not clear:
- **Unit test**: Isolated tests with mocked dependencies. Use `SimpleTestCase` + `create_autospec`.
- **Integration test**: Tests with database access. Use `TestCase` + Factories.

## Step 2: Find Existing Patterns

Before writing, search for existing tests in the same domain to copy the pattern:

```bash
# Find tests in the domain
ls app/{domain}/tests/
```

Read at least one existing test to understand the structure and patterns used.

## Step 3: Create the Test File

### Location

- Tests go in: `app/{domain}/tests/test_{component_name}.py`
- AI tools tests: `app/{domain}/tests/ai_tools/test_{tool_name}.py`
- Subdomain tests: `app/{domain}/{subdomain}/tests/test_{component_name}.py`

### Unit Test Template

```python
from unittest.mock import create_autospec

from django.test import SimpleTestCase

from {domain}.models import SomeModel
from {domain}.repositories import SomeRepository
from {domain}.usecases.{usecase_file} import SomeUseCase, SomeError


class SomeUseCaseTestCase(SimpleTestCase):
    def setUp(self) -> None:
        self.repository = create_autospec(SomeRepository)
        self.use_case = SomeUseCase(repository=self.repository)

    def test_success_case(self) -> None:
        """
        Given valid input
        When the use case is called
        Then it should return the expected result
        """
        # Arrange
        mock_model = create_autospec(SomeModel)
        mock_model.id = 1
        self.repository.get_by_id.return_value = mock_model

        # Act
        result = self.use_case(entity_id=1)

        # Assert
        self.assertEqual(result, mock_model)
        self.repository.get_by_id.assert_called_once_with(1)

    def test_error_case(self) -> None:
        """
        Given invalid input
        When the use case is called
        Then it should raise the appropriate error
        """
        # Arrange
        self.repository.get_by_id.return_value = None

        # Act & Assert
        with self.assertRaises(SomeError):
            self.use_case(entity_id=999)
```

### Integration Test Template

```python
from unittest.mock import MagicMock

from django.test import TestCase

from {domain}.models import SomeModel
from {domain}.tests.factories import SomeModelFactory
from organizations.models import Organization
from sytexauth.models import User


class SomeFeatureTestCase(TestCase):
    def setUp(self) -> None:
        self.organization = MagicMock(spec=Organization)
        self.organization.id = 1
        self.user = MagicMock(spec=User)
        self.user.id = 1

    def test_feature_works(self) -> None:
        # Arrange
        instance = SomeModelFactory()

        # Act
        result = some_operation(instance)

        # Assert
        self.assertEqual(result, expected_value)
```

## Step 4: Run the Test

```bash
# Start Docker containers
just run

# Unit tests
just unit_test {domain}.tests.test_{component_name}

# Integration tests
just test {domain}.tests.test_{component_name}

# Stop Docker containers after tests complete
just stop
```

## Key Points

- Use descriptive test method names: `test_{scenario}_{expected_behavior}`
- Follow Arrange/Act/Assert structure
- Use `create_autospec` for type-safe mocks in unit tests
- Use `MagicMock(spec=Class)` for simple mocks
- Mock all external dependencies in unit tests
- Add docstrings explaining Given/When/Then

## Best Practices

**What to test:**
- Test behavior through the public interface
- Test edge cases: empty values, `None`, boundaries
- Trust Django and third-party libraries

**How to test:**
- One concept per test
- Tests independent from each other
- Linear tests (no `if`/`for`/`while`)
- Use constants or descriptive variables

**Mocking:**
- Mock at the right level
- Mock external dependencies, not the class under test

**Maintenance:**
- Test behavior, not implementation
- `setUp` only for what's common to all tests
- Keep tests fast
