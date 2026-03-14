---
name: create-usecase
description: Create a use case following the project's clean architecture patterns. Use when the user needs to implement business logic that orchestrates operations.
---

# Create Use Case

You are creating a use case in the Sytex codebase following clean architecture principles.

## Step 1: Understand the Use Case

Ask the user if not clear:
- What business operation should this perform?
- What entities/models are involved?
- What dependencies (repositories, other use cases) are needed?

## Step 2: Find Existing Patterns

Before writing, search for existing use cases in the same domain:

```bash
ls app/{domain}/usecases/
```

Read at least one to understand the naming and structure conventions.

## Step 3: Create the Use Case File

### Location

`app/{domain}/usecases/{verb}_{entity}_use_case.py`

Examples:
- `get_site_data_use_case.py`
- `create_workflow_use_case.py`
- `validate_form_creation_code.py`

### Template

```python
from typing import Optional

from {domain}.models import Entity
from {domain}.repositories import EntityRepository
from organizations.models import Organization
from sytex.exceptions import SytexBusinessError
from sytexauth.models import User
from utils.translation import _


class EntityNotFoundError(SytexBusinessError):
    def __init__(self, entity_id: int) -> None:
        super().__init__(_("Entity with ID {} not found").format(entity_id))


class VerbEntityUseCase:
    """
    Brief description of what this use case does.
    """

    def __init__(
        self,
        entity_repository: EntityRepository,
        another_dependency: AnotherClass,
    ) -> None:
        self._entity_repository = entity_repository
        self._another_dependency = another_dependency

    def __call__(
        self,
        *,
        entity_id: int,
        user: User,
        organization: Organization,
    ) -> Entity:
        """
        Description of the operation.

        Args:
            entity_id: ID of the entity
            user: User performing the action
            organization: Organization context

        Returns:
            The processed entity

        Raises:
            EntityNotFoundError: If entity doesn't exist
        """
        entity = self._entity_repository.get_by_id(entity_id)
        if not entity:
            raise EntityNotFoundError(entity_id)

        # Business logic here...

        return entity
```

## Step 4: Update the `__init__.py`

Add export to `app/{domain}/usecases/__init__.py`:

```python
from .verb_entity_use_case import VerbEntityUseCase, EntityNotFoundError
```

## Step 5: Register in Dependency Injection

Add to `app/{domain}/dependency_injection.py`:

```python
from {domain}.usecases import VerbEntityUseCase
from {domain}.repositories import EntityRepository
from {domain}.models import Entity


class DependencyContainer:
    # ... existing code ...

    @property
    def verb_entity_use_case(self) -> VerbEntityUseCase:
        return VerbEntityUseCase(
            entity_repository=EntityRepository(manager=Entity.objects),
            another_dependency=self.another_dependency,
        )
```

## Step 6: Create Unit Test

Create test at `app/{domain}/tests/test_verb_entity_use_case.py`:

```python
from unittest.mock import create_autospec

from django.test import SimpleTestCase

from {domain}.models import Entity
from {domain}.repositories import EntityRepository
from {domain}.usecases import VerbEntityUseCase, EntityNotFoundError


class VerbEntityUseCaseTestCase(SimpleTestCase):
    def setUp(self) -> None:
        self.repository = create_autospec(EntityRepository)
        self.use_case = VerbEntityUseCase(entity_repository=self.repository)

    def test_success(self) -> None:
        # Arrange
        entity = create_autospec(Entity)
        entity.id = 1
        self.repository.get_by_id.return_value = entity

        # Act
        result = self.use_case(entity_id=1)

        # Assert
        self.assertEqual(result, entity)

    def test_not_found_raises_error(self) -> None:
        # Arrange
        self.repository.get_by_id.return_value = None

        # Act & Assert
        with self.assertRaises(EntityNotFoundError):
            self.use_case(entity_id=999)
```

## Key Rules

- **NEVER** use Django ORM directly - always go through repositories
- Use `*` in `__call__` to force keyword-only arguments
- Custom exceptions inherit from `SytexBusinessError`
- All parameters must have type hints
- Use `_` prefix for private attributes
- Inject specific dependencies, not the DI container
