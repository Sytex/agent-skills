---
name: create-repository
description: Create a repository to abstract database access following project patterns. Use when the user needs to add data access operations.
---

# Create Repository

You are creating a repository in the Sytex codebase to abstract database operations.

## Step 1: Understand the Repository

Ask the user if not clear:
- What model/entity does this repository manage?
- What operations are needed (get, filter, create, update, delete)?

## Step 2: Find Existing Patterns

Before writing, search for existing repositories in the same domain:

```bash
ls app/{domain}/repositories/
```

Read at least one to understand the conventions.

## Step 3: Create the Repository File

### Location

`app/{domain}/repositories/{entity}_repository.py`

Examples:
- `site_repository.py`
- `custom_fields_repository.py`
- `workflow_assignments_repository.py`

### Template

```python
from typing import List, Optional

from django.db.models import Manager

from {domain}.models import Entity
from organizations.models import Organization
from sytexauth import PermissionsCheck
from sytexauth.models import User


class EntityRepository:
    def __init__(self, manager: Manager) -> None:
        self._manager = manager

    def get_by_id(self, entity_id: int) -> Optional[Entity]:
        """Get an entity by its ID."""
        return self._manager.filter(id=entity_id).first()

    def get_by_ids(self, entity_ids: List[int]) -> List[Entity]:
        """Get multiple entities by their IDs."""
        return list(self._manager.filter(id__in=entity_ids))

    def filter_by_organization(
        self,
        organization: Organization,
    ) -> List[Entity]:
        """Get all entities for an organization."""
        return list(self._manager.filter(organization=organization))

    def search(
        self,
        *,
        query: str,
        organization: Organization,
        max_results: int = 10,
    ) -> List[Entity]:
        """Search entities by name or code."""
        return list(
            self._manager.filter(
                organization=organization,
                name__icontains=query,
            )[:max_results]
        )

    def filter_by_permission(
        self,
        *,
        user: User,
        organization: Organization,
        entities: List[Entity],
    ) -> List[Entity]:
        """Filter entities by user permissions."""
        entities_qs = self._manager.filter(id__in=[e.id for e in entities])
        filtered_qs = PermissionsCheck().filter_queryset_by_permission(
            user,
            organization,
            entities_qs,
            Entity,
            permission="{domain}.entity.view",
        )
        return list(filtered_qs)

    def save(self, entity: Entity) -> None:
        """Save an entity."""
        entity.save()

    def create(self, **kwargs) -> Entity:
        """Create a new entity."""
        return self._manager.create(**kwargs)

    def delete(self, entity: Entity) -> None:
        """Delete an entity."""
        entity.delete()
```

## Step 4: Update the `__init__.py`

Add export to `app/{domain}/repositories/__init__.py`:

```python
from .entity_repository import EntityRepository
```

## Step 5: Register in Dependency Injection

Add to `app/{domain}/dependency_injection.py`:

```python
from {domain}.models import Entity
from {domain}.repositories import EntityRepository


class DependencyContainer:
    # ... existing code ...

    @property
    def entity_repository(self) -> EntityRepository:
        return EntityRepository(manager=Entity.objects)
```

## Step 6: Create Unit Test

Create test at `app/{domain}/tests/test_entity_repository.py`:

```python
from unittest.mock import MagicMock, create_autospec

from django.db.models import Manager
from django.test import SimpleTestCase

from {domain}.models import Entity
from {domain}.repositories import EntityRepository


class EntityRepositoryTestCase(SimpleTestCase):
    def setUp(self) -> None:
        self.manager = MagicMock(spec=Manager)
        self.repository = EntityRepository(manager=self.manager)

    def test_get_by_id_found(self) -> None:
        # Arrange
        entity = create_autospec(Entity)
        entity.id = 1
        self.manager.filter.return_value.first.return_value = entity

        # Act
        result = self.repository.get_by_id(1)

        # Assert
        self.assertEqual(result, entity)
        self.manager.filter.assert_called_once_with(id=1)

    def test_get_by_id_not_found(self) -> None:
        # Arrange
        self.manager.filter.return_value.first.return_value = None

        # Act
        result = self.repository.get_by_id(999)

        # Assert
        self.assertIsNone(result)
```

## Key Rules

- Repositories are the ONLY place for Django ORM calls
- Inject `Manager` (e.g., `Entity.objects`), not the model class
- Methods should be specific, not generic (avoid `def filter(**kwargs)`)
- Use keyword-only arguments with `*` for clarity
- All parameters and return types must have type hints
- Use `list()` to convert QuerySets to lists before returning
