---
name: add-soft-delete
description: Add soft-delete support to an existing Django model. Use when the user wants objects to be marked as deleted instead of permanently removed from the database.
---

# Add Soft Delete to a Model

This skill adds soft-delete to an existing Django model using **Test Driven Development** by inheriting from `SoftDeleteModel`. Soft delete marks objects as deleted (`is_deleted=True`) instead of permanently removing them.

**What SoftDeleteModel provides:**
- `is_deleted` (BooleanField, default=False)
- `deleted_at` (DateTimeField, nullable)
- `deleted_by` (ForeignKey to User, nullable, SET_NULL)
- `who_created` (ForeignKey to User, nullable)
- `objects` = SoftDeleteManager (auto-filters `is_deleted=False`)
- `deleted_objects` = DeletedManager (only deleted objects)
- `all_objects` = AllManager (everything)
- `delete(user=user)` method with cascade soft-delete via `NestedObjects` collector
- `restore()` method to undo deletion (also cascades)
- `hard_delete()` for permanent removal

---

## Step 0: Gather Information

Ask the user if not clear:
- **Which model** needs soft-delete?
- **Cascade or no cascade?** Should children also be soft-deleted (cascade), or only the item itself (no cascade, children stay untouched)?
- **Any business rules?** (e.g., time limits, ownership checks, status validation)
- **Child models**: Does the model have related child objects? What should happen to them on soft-delete?
- **Parent models**: Does the model have ForeignKey references to parents? Classify each FK as **container** or **external reference** (see Step 3) to determine the correct `on_delete` behavior.

Then explore the codebase:
1. Read the model file to understand its current base class, fields, and relationships
2. Identify child models (models with ForeignKey pointing to this model)
3. Identify parent models (ForeignKeys on this model pointing to other models)
4. Read the model's serializer, views, urls, and dependency injection
5. Read the model's repository if one exists

---

## Step 1: Write Tests FIRST (TDD)

**Always start with tests before writing any implementation code.**

Create `app/{domain}/tests/test_soft_delete_{entity}_use_case.py`:

### Unit Tests for the Use Case

```python
from unittest.mock import create_autospec

from django.test import SimpleTestCase

from {domain}.models import YourModel
from {domain}.repositories import YourModelRepository
from {domain}.usecases.soft_delete_{entity}_use_case import (
    SoftDeleteYourModelUseCase,
    YourModelNotFoundError,
)
from organizations.models import Organization
from sytexauth.models import User


class SoftDeleteYourModelUseCaseTestCase(SimpleTestCase):
    def setUp(self) -> None:
        self.repository = create_autospec(YourModelRepository)
        self.use_case = SoftDeleteYourModelUseCase(
            repository=self.repository,
        )
        self.user = create_autospec(User)
        self.user.id = 1
        self.organization = create_autospec(Organization)
        self.organization.id = 1

    def test_soft_delete_success(self) -> None:
        """
        Given a valid entity ID
        When the use case is called
        Then the entity should be soft deleted via the repository
        """
        # Arrange
        instance = create_autospec(YourModel)
        instance.id = 1
        self.repository.get_by_id.return_value = instance

        # Act
        result = self.use_case(
            entity_id=1,
            user=self.user,
            organization=self.organization,
        )

        # Assert
        self.assertEqual(result, instance)
        self.repository.get_by_id.assert_called_once_with(1)
        self.repository.soft_delete.assert_called_once_with(instance, user=self.user)

    def test_soft_delete_not_found_raises_error(self) -> None:
        """
        Given a non-existent entity ID
        When the use case is called
        Then it should raise YourModelNotFoundError
        """
        # Arrange
        self.repository.get_by_id.return_value = None

        # Act & Assert
        with self.assertRaises(YourModelNotFoundError):
            self.use_case(
                entity_id=999,
                user=self.user,
                organization=self.organization,
            )

    # Add tests for any business rules:
    # - test_soft_delete_not_owner_raises_error
    # - test_soft_delete_too_old_raises_error
    # - test_soft_delete_already_deleted
    # - etc.
```

### Integration Tests (for cascade/child behavior)

Create `app/{domain}/tests/test_soft_delete_{entity}.py`:

**Note:** Factories do NOT need changes — soft-delete fields (`is_deleted`, `deleted_at`, `deleted_by`) use model defaults automatically.

```python
from django.test import TestCase
from django.utils import timezone

from {domain}.factories import YourModelFactory, ChildModelFactory
from {domain}.models import YourModel, ChildModel
from organizations.factories import OrganizationFactory
from sytexauth.factories import UserFactory


class SoftDeleteYourModelIntegrationTestCase(TestCase):
    def setUp(self) -> None:
        self.organization = OrganizationFactory()
        self.user = UserFactory(organization=self.organization)

    def test_soft_delete_sets_fields_correctly(self) -> None:
        """
        Given a valid instance
        When delete(user=user) is called
        Then is_deleted, deleted_at, deleted_by should be set
        """
        # Arrange
        instance = YourModelFactory(organization=self.organization)
        now = timezone.now()

        # Act
        instance.delete(user=self.user)

        # Assert
        instance.refresh_from_db()
        self.assertTrue(instance.is_deleted)
        self.assertGreaterEqual(instance.deleted_at, now)
        self.assertEqual(instance.deleted_by, self.user)

    def test_soft_delete_managers_filter_correctly(self) -> None:
        """
        Given a soft deleted object
        When querying with the three managers
        Then .objects excludes it, .all_objects includes it, .deleted_objects returns only it
        """
        # Arrange
        instance = YourModelFactory(organization=self.organization)
        total_before = YourModel.all_objects.count()

        # Act
        instance.delete(user=self.user)

        # Assert — record still in DB, just filtered
        self.assertEqual(YourModel.all_objects.count(), total_before)
        self.assertEqual(YourModel.objects.count(), total_before - 1)
        self.assertEqual(YourModel.deleted_objects.count(), 1)
        self.assertNotEqual(YourModel.objects.count(), YourModel.all_objects.count())

    def test_soft_delete_cascades_to_children(self) -> None:
        """
        Given a parent with child objects
        When the parent is soft deleted
        Then children should also be soft deleted with same deleted_at and deleted_by
        """
        # Arrange
        parent = YourModelFactory(organization=self.organization)
        child = ChildModelFactory(parent=parent)

        # Act
        parent.delete(user=self.user)

        # Assert parent
        parent.refresh_from_db()
        self.assertTrue(parent.is_deleted)
        self.assertIsNotNone(parent.deleted_at)
        self.assertEqual(parent.deleted_by, self.user)

        # Assert child — same timestamp and user as parent (atomic cascade)
        child.refresh_from_db()
        self.assertTrue(child.is_deleted)
        self.assertEqual(child.deleted_at, parent.deleted_at)
        self.assertEqual(child.deleted_by, self.user)

    def test_restore_restores_parent_and_children(self) -> None:
        """
        Given a soft deleted parent with soft deleted children
        When restore is called
        Then both are restored and deleted_by is cleared to None
        """
        # Arrange
        parent = YourModelFactory(organization=self.organization)
        child = ChildModelFactory(parent=parent)
        total_before = YourModel.all_objects.count()
        parent.delete(user=self.user)

        # Act — must fetch from all_objects since .objects filters it out
        parent_from_db = YourModel.all_objects.get(id=parent.id)
        parent_from_db.restore()

        # Assert
        self.assertEqual(YourModel.objects.count(), total_before)
        self.assertEqual(YourModel.deleted_objects.count(), 0)

        parent.refresh_from_db()
        self.assertFalse(parent.is_deleted)
        self.assertIsNone(parent.deleted_by)
        self.assertIsNone(parent.deleted_at)

        child.refresh_from_db()
        self.assertFalse(child.is_deleted)
        self.assertIsNone(child.deleted_by)

    # --- SOFT_DELETE_PROTECT regression tests ---
    # Add these if the model has FK relationships with SOFT_DELETE_PROTECT:

    # def test_parent_can_be_deleted_if_child_is_already_soft_deleted(self) -> None:
    #     """
    #     Given a child with SOFT_DELETE_PROTECT FK to parent
    #     When child is already soft-deleted
    #     Then parent deletion should succeed
    #     """
    #     # Arrange
    #     parent = ParentFactory(organization=self.organization)
    #     child = YourModelFactory(parent=parent, organization=self.organization)
    #     child.delete(user=self.user)
    #
    #     # Act & Assert — should NOT raise
    #     parent.delete(user=self.user)
    #     self.assertTrue(
    #         ParentModel.all_objects.get(id=parent.id).is_deleted
    #     )

    # def test_parent_cannot_be_deleted_if_child_is_not_soft_deleted(self) -> None:
    #     """
    #     Given a child with SOFT_DELETE_PROTECT FK to parent
    #     When child is NOT soft-deleted
    #     Then parent deletion should raise SoftDeleteProtectedError
    #     """
    #     # Arrange
    #     parent = ParentFactory(organization=self.organization)
    #     child = YourModelFactory(parent=parent, organization=self.organization)
    #
    #     # Act & Assert
    #     from sytex.models import SoftDeleteProtectedError
    #     with self.assertRaises(SoftDeleteProtectedError):
    #         parent.delete(user=self.user)
```

Run the tests to verify they **fail** (RED phase):

```bash
cd app && uv run python manage.py test -v2 --keepdb --settings sytex.settings-tests {domain}.tests.test_soft_delete_{entity}_use_case
```

---

## Step 2: Update the Model (GREEN phase)

Now implement the minimum code to make tests pass.

Change the model's base class to include `SoftDeleteModel`:

```python
# Before
from sytex import models

class YourModel(models.SytexModel):
    # fields...

# After
from sytex import models

class YourModel(models.SoftDeleteModel):  # or add SoftDeleteModel to existing bases
    # fields...
    # Remove any manually-defined is_deleted, deleted_at, deleted_by fields
    # SoftDeleteModel provides them automatically
```

If the model currently inherits from `SytexModel` and needs both behaviors:

```python
class YourModel(models.SoftDeleteModel, models.SytexModel):
    # SoftDeleteModel must come first so its manager takes precedence
```

**IMPORTANT:** After this change, `YourModel.objects.all()` will automatically exclude soft-deleted objects. Verify existing queries still work correctly.

---

## Step 3: Handle Parent/Child Relationships

### Child objects (models with FK to this model)

Cascade behavior is automatic via `NestedObjects` collector: all child objects with `is_deleted` attribute will be soft-deleted when the parent is deleted.

If a child model does NOT already have soft-delete support, you must decide:
1. **Add soft-delete to the child too** (repeat this skill for the child model)
2. **Let the child be hard-deleted** (default Django behavior for non-SoftDeleteModel children)

If the child model already inherits from `SoftDeleteModel`, cascade works out of the box.

### Parent objects (ForeignKeys on this model pointing to parents)

When adding soft-delete to a model, **first classify each FK** into one of two categories:

#### 1. Container FK (item belongs to a parent document)

The model is a **child item** that is part of a parent document and should be cascade-deleted with it. Examples: `QuotationItem.quotation`, `PurchaseOrderItem.purchase_order`, `StopperAttribute.stopper`.

**→ Keep `on_delete=CASCADE`.** This is required for cascade soft-delete to work. When the parent is soft-deleted via `SoftDeleteModel.delete()`, the `NestedObjects` collector traverses CASCADE relationships and soft-deletes all collected children together. Changing this to `SOFT_DELETE_PROTECT` would **block** the parent's soft-delete, raising `SoftDeleteProtectedError`.

How to identify a container FK:
- The model doesn't make sense without its parent (an item without its order)
- Deleting the parent should delete all its items
- It's typically a NOT NULL FK

#### 2. External reference FK (model references an independent entity)

The model references an **independent entity** that exists on its own. Examples: `Stopper.project`, `Stopper.task`, `PurchaseOrderItem.material`, `Quotation.supplier`.

**→ Change to `on_delete=SOFT_DELETE_PROTECT`.** This prevents the referenced entity from hard-deleting this model via cascade.

```python
class YourModel(models.SoftDeleteModel):
    # Container FK — keep CASCADE (item belongs to parent)
    parent_document = models.ForeignKey(
        "ParentDocument",
        on_delete=models.CASCADE,  # DO NOT change
    )

    # External reference FK — change to SOFT_DELETE_PROTECT
    supplier = models.ForeignKey(
        "Supplier",
        on_delete=models.SOFT_DELETE_PROTECT,  # was PROTECT or CASCADE
        null=True,
    )
```

`SOFT_DELETE_PROTECT` behavior:
- If ALL child objects pointing to the parent are already soft-deleted → allows parent deletion (sets FK to NULL)
- If ANY child object is NOT soft-deleted → raises `SoftDeleteProtectedError` (blocks parent deletion)

**Requirements for `SOFT_DELETE_PROTECT`:**
- The FK **must be nullable** (`null=True`), because it sets the FK to NULL on parent deletion
- If the FK is NOT NULL and references an entity that is never deleted (e.g., `Status`, `Currency`), keep it as `PROTECT`

Rules by original `on_delete` value:
- **`on_delete=CASCADE` (external reference)**: **MUST change to `SOFT_DELETE_PROTECT`**. If left as CASCADE, deleting the referenced entity will **permanently hard-delete** this soft-delete model, bypassing soft-delete entirely.
- **`on_delete=PROTECT` (external reference)**: Change to `SOFT_DELETE_PROTECT` so the referenced entity CAN be deleted when all referencing children are already soft-deleted. Exception: keep `PROTECT` for NOT NULL FKs to entities that are never deleted.
- **`on_delete=CASCADE` (container)**: **Keep as CASCADE**. Required for cascade soft-delete.
- **`on_delete=SET_NULL`**: No change needed, works fine with soft-delete.

### Checklist for relationships

Before implementing, map out all relationships and classify each FK:

```
YourModel
  ├── FK to ParentDocument (CONTAINER → keep CASCADE)
  ├── FK to ExternalEntityA (EXTERNAL, nullable → change to SOFT_DELETE_PROTECT)
  ├── FK to ExternalEntityB (EXTERNAL, NOT NULL, never deleted → keep PROTECT)
  ├── ChildX.parent → FK to YourModel (ChildX has is_deleted? → cascade works)
  └── ChildY.parent → FK to YourModel (ChildY has NO is_deleted? → add soft-delete or leave as hard delete)
```

**CRITICAL:** Any **external reference** FK with `on_delete=CASCADE` MUST be changed to `SOFT_DELETE_PROTECT`. Otherwise, deleting the referenced entity will permanently hard-delete this model, completely bypassing soft-delete. But **container** FKs MUST stay as `CASCADE` for cascade soft-delete to work.

---

## Step 4: Create Migration

Try auto-generating first:

```bash
just makemigrations {app_label}
```

**If `just makemigrations` fails or hangs** (common when combining `SoftDeleteModel` with `SytexModel` — see [Known Issues](#known-issues--gotchas)), write the migration manually using the templates in that section.

Review the migration before proceeding.

---

## Step 5: Implement Repository Methods

If a repository exists for this model, add soft-delete methods. **Ask the user which approach to use:**

### Option A: Cascade (soft-deletes children too)

Uses `SoftDeleteModel.delete()` which traverses all related objects via `NestedObjects` collector and soft-deletes them. Use this when children should also be marked as deleted.

```python
def soft_delete(self, instance: YourModel, user: User) -> None:
    instance.delete(user=user)

def restore(self, instance: YourModel) -> None:
    instance.restore()
```

**Note:** This will be blocked by `SOFT_DELETE_PROTECT` if non-deleted children exist on protected FKs. The `delete_recursive` method in `SytexModelViewset` handles this by recursively deleting protected children first.

### Option B: No cascade (only soft-deletes the item itself)

Sets fields directly without going through the collector. Use this when children (e.g., task assignments) should remain untouched.

```python
from django.utils import timezone

def soft_delete(self, instance: YourModel, user: User) -> None:
    instance.is_deleted = True
    instance.deleted_at = timezone.now()
    instance.deleted_by = user
    instance.save(update_fields=["is_deleted", "deleted_at", "deleted_by"])

def restore(self, instance: YourModel) -> None:
    instance.is_deleted = False
    instance.deleted_at = None
    instance.deleted_by = None
    instance.save(update_fields=["is_deleted", "deleted_at", "deleted_by"])
```

**Note:** With this approach, child FK `on_delete` handlers are NOT triggered. No need to change child FKs to `SOFT_DELETE_PROTECT`.

If no repository exists, create one using the `/create-repository` skill first.

---

## Step 6: Implement Use Case

Create `app/{domain}/usecases/soft_delete_{entity}_use_case.py`:

```python
from django.utils.translation import gettext_lazy as _

from {domain}.models import YourModel
from {domain}.repositories import YourModelRepository
from organizations.models import Organization
from sytex.exceptions import SytexBusinessError
from sytexauth.models import User


class YourModelNotFoundError(SytexBusinessError):
    def __init__(self) -> None:
        super().__init__(_("Object not found"))


class SoftDeleteYourModelUseCase:
    """Soft delete a YourModel instance."""

    def __init__(self, repository: YourModelRepository) -> None:
        self._repository = repository

    def __call__(
        self,
        *,
        entity_id: int,
        user: User,
        organization: Organization,
    ) -> YourModel:
        instance = self._repository.get_by_id(entity_id)
        if not instance:
            raise YourModelNotFoundError()

        # Add any business rules here:
        # - Permission checks
        # - Ownership validation
        # - Time limits
        # - etc.

        self._repository.soft_delete(instance, user=user)
        return instance
```

Export in `app/{domain}/usecases/__init__.py`:

```python
from .soft_delete_{entity}_use_case import SoftDeleteYourModelUseCase
```

---

## Step 7: Run Tests (GREEN phase)

Run the tests to verify they **pass**:

```bash
cd app && uv run python manage.py test -v2 --keepdb --settings sytex.settings-tests {domain}.tests.test_soft_delete_{entity}_use_case
```

Fix any failures before proceeding.

---

## Step 8: Update Serializer

Add `is_deleted` to the serializer fields:

```python
class YourModelSerializer(serializers.ModelSerializer):
    is_deleted = serializers.BooleanField(read_only=True)

    class Meta:
        model = YourModel
        fields = [
            # ... existing fields ...
            "is_deleted",
        ]
        read_only_fields = [
            # ... existing read_only_fields ...
            "is_deleted",
        ]
```

---

## Step 9: Update or Create View/Endpoint

**Decide based on your viewset and requirements:**

### Option A: No override needed (cascade via SytexModelViewset)

If the viewset inherits from `SytexModelViewset` AND cascade behavior is desired AND there are no extra business rules:

**Do nothing.** `SytexModelViewset.destroy()` already:
1. Detects `SoftDeleteModel` instances
2. Calls `perform_destroy()` → `delete_recursive()` → `execute_recursive_deletion()`
3. Handles `SoftDeleteProtectedError` by recursively deleting protected children
4. Returns 204 on success

### Option B: Override destroy (no cascade or business rules)

If you need **non-cascade soft-delete** or **business rule validation**, override `destroy()` to use the use case:

```python
def destroy(self, request, *args, **kwargs):
    instance = self.get_object()
    try:
        di.soft_delete_{entity}_use_case(
            entity_id=instance.id,
            user=request.user,
            organization=request.organization,
        )
    except (YourModelNotFoundError, YourBusinessRuleError) as e:
        return Response(
            data={"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST,
        )
    return Response(status=status.HTTP_204_NO_CONTENT)
```

### Option C: New endpoint (no existing viewset)

If the model has no viewset at all, create one and register it in urls:

```python
router.register(r"{endpoint}", YourModelViewSet, basename="{endpoint}")
```

---

## Step 10: Register in Dependency Injection

Add to `app/{domain}/dependency_injection.py`:

```python
from {domain}.usecases import SoftDeleteYourModelUseCase
from {domain}.repositories import YourModelRepository
from {domain}.models import YourModel


class DependencyContainer:
    # ... existing code ...

    @property
    def soft_delete_{entity}_use_case(self) -> SoftDeleteYourModelUseCase:
        return SoftDeleteYourModelUseCase(
            repository=YourModelRepository(manager=YourModel.objects),
        )
```

---

## Step 11: Update Data Warehouse Queries

Check if the model has a corresponding query file in `app/data_warehouse/`. If it does, add `is_deleted = 0` filtering to exclude soft-deleted records from the data warehouse sync.

### How to find the query file

Search in `app/data_warehouse/` for a subdirectory matching the model name (e.g., `stoppers/`, `forms/`, `tasks/`). Each entity subdirectory contains an `update_{entity}_data_warehouse_query.py` file with raw SQL.

### What to change

Add `AND {alias}.is_deleted = 0` to **every** WHERE clause that filters the main entity. This includes:

1. **The main WHERE clause** at the bottom of the query
2. **All subquery WHERE clauses** inside LEFT JOINs that reference the main entity table

### Example: Main WHERE clause (stoppers)

**Before:**
```sql
WHERE sto.organization_id = {organization_id}
AND sto.id IN ({", ".join([str(entity_id) for entity_id in entity_ids_to_update])})
```

**After:**
```sql
WHERE sto.organization_id = {organization_id}
AND sto.is_deleted = 0
AND sto.id IN ({", ".join([str(entity_id) for entity_id in entity_ids_to_update])})
```

### Example: Subqueries in LEFT JOINs (from forms query)

When the query has LEFT JOIN subqueries that reference the main entity (e.g., for status history), add `is_deleted = 0` there too:

```sql
LEFT JOIN (
    SELECT
        sh.object_id as object_id,
        MAX(sh.when_created) as max_date
    FROM {sytex_db_name}.shared_statushistory sh
        LEFT JOIN {sytex_db_name}.forms_form f ON f.id = sh.object_id
    WHERE
        f.organization_id = {organization_id}
        AND f.is_deleted = 0  -- ADD THIS LINE
        AND f.id IN ({", ".join([str(entity_id) for entity_id in entity_ids_to_update])})
        AND sh.content_type_id = (...)
        AND sh.to_status_id = 11
    GROUP BY object_id
) last_in_progress ON f.id = last_in_progress.object_id
```

### Reference

See `app/data_warehouse/forms/update_forms_data_warehouse_query.py` for a complete example with `is_deleted = 0` applied to both the main WHERE clause and all subquery WHERE clauses.

---

## Step 12: Final Test Run

Run all tests one more time to confirm everything works:

```bash
cd app && uv run python manage.py test -v2 --keepdb --settings sytex.settings-tests {domain}.tests.test_soft_delete_{entity}_use_case
```

---

## Reference Implementations

- **Full SoftDeleteModel base**: `app/sytex/models.py:219` - `SoftDeleteModel`, `SoftDeleteManager`, `SoftDeleteQuerySet`, `DeletedManager`, `AllManager`
- **SOFT_DELETE_PROTECT**: `app/sytex/models.py:37` - custom `on_delete` for FK relationships
- **Cascade delete mechanism**: `app/sytex/models.py:548` - `delete_recursive` and `execute_recursive_deletion`
- **Full SoftDeleteModel example**: `app/forms/models.py` (Form model with cascade to children)
- **Soft-delete tests**: `app/forms/tests/tests.py` - `FormSoftDeleteTestCase` (cascade, managers, restore, SOFT_DELETE_PROTECT regressions)
- **Cascade tests**: `app/forms/tests/tests_forms.py` - `FormModelTestCase` (deleted_at/deleted_by propagation to children)
- **PurchaseOrderItem soft-delete**: `app/accounting/usecases/soft_delete_purchase_order_item_use_case.py`, `app/accounting/tests/test_soft_delete_purchase_order_item.py`

---

## Known Issues / Gotchas

### 1. `just makemigrations` interactive prompt failure

When combining `SoftDeleteModel` with `SytexModel` (or `SytexModelNoOrganization`), the `who_created` field conflicts. `SoftDeleteModel` defines `who_created` with `null=True` and `on_delete=SOFT_DELETE_PROTECT`, while `SytexModel` defines it with `NOT NULL` and `on_delete=PROTECT`. Due to Python's MRO, `SoftDeleteModel`'s version wins, causing Django to detect a field alteration. `just makemigrations` then prompts interactively to confirm, which fails in Docker with `EOFError`.

**Workaround**: Write the migration manually:

```python
import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models
import sytex.models

class Migration(migrations.Migration):
    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("<app_label>", "<previous_migration>"),
    ]
    operations = [
        migrations.AddField(model_name="<model_lower>", name="is_deleted", field=models.BooleanField(default=False)),
        migrations.AddField(model_name="<model_lower>", name="deleted_at", field=models.DateTimeField(blank=True, null=True)),
        migrations.AddField(model_name="<model_lower>", name="deleted_by", field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="%(app_label)s_%(class)s_deleted", to=settings.AUTH_USER_MODEL)),
        migrations.AlterField(model_name="<model_lower>", name="who_created", field=models.ForeignKey(null=True, on_delete=sytex.models.SOFT_DELETE_PROTECT, related_name="%(app_label)s_%(class)s_created", to=settings.AUTH_USER_MODEL)),
    ]
```

### 2. Child FK migrations belong in the child's app

When changing a child model's FK to `SOFT_DELETE_PROTECT`, create a **separate migration in the child's app**, not the parent's:

```python
from django.db import migrations, models
import sytex.models

class Migration(migrations.Migration):
    dependencies = [
        ("<parent_app>", "<parent_migration>"),
        ("<child_app>", "<previous_child_migration>"),
    ]
    operations = [
        migrations.AlterField(
            model_name="<child_model_lower>",
            name="<fk_field_name>",
            field=models.ForeignKey(on_delete=sytex.models.SOFT_DELETE_PROTECT, to="<parent_app>.<parent_model>"),
        ),
    ]
```

### 3. Viewset integration — when to override `destroy()`

`SytexModelViewset.destroy()` already handles `SoftDeleteModel` via `delete_recursive()`, which **cascades** through related objects. You only need to override `destroy()` if:
- You want **non-cascade** behavior (only soft-delete the item, leave children untouched)
- You have **business rules** to validate before deletion (e.g., status checks)
- The viewset doesn't use `SytexModelViewset`

See Step 9 for the three options.

### 4. Data Warehouse impact — `post_delete` signal no longer fires

**IMPORTANT:** One key purpose of soft-delete is to **preserve data warehouse records**. When a model switches from hard-delete to soft-delete, `SoftDeleteModel.delete()` calls `save()` instead of Django's actual `delete()`, so the `post_delete` signal is **never fired**. This means:

- The `entity_post_delete` signal receiver in `data_warehouse/signal_receivers.py` will NOT be triggered
- The `DeleteEntityRecordFromDataWarehouseUseCase` will NOT be called
- The data warehouse record is **preserved** — this is the intended behavior

**Action required:** If the model is listed in `types_with_data_warehouse` in `data_warehouse/signal_receivers.py`, check for existing tests that assert `post_delete` triggers DW deletion (e.g., `RemoveXFromDwWhenDeletedTestCase`). Update those tests to assert the **opposite**: that soft-delete does NOT remove the record from the data warehouse.

Example test update:
```python
def test_soft_delete_does_not_remove_from_dw(self):
    """Soft-delete preserves the data warehouse record."""
    with patch("data_warehouse.celery_tasks.di") as di_mock:
        instance.delete_recursive(user=self.user, confirm=True)
        di_mock.__getitem__.assert_not_called()
```

---

## Checklist

- [ ] Tests written FIRST (unit tests for use case, integration tests for cascade)
- [ ] Tests fail (RED phase confirmed)
- [ ] Model updated with soft-delete support (inherits `SoftDeleteModel`)
- [ ] Parent/child relationships reviewed and `on_delete` updated where needed
- [ ] Child models have soft-delete if cascade is required
- [ ] ForeignKeys to parents changed from `PROTECT` to `SOFT_DELETE_PROTECT` where appropriate
- [ ] Migration created (`just makemigrations` or manually if interactive prompt fails -- see Known Issues)
- [ ] Repository has soft-delete methods
- [ ] Use case created with business rules
- [ ] Tests pass (GREEN phase confirmed)
- [ ] Serializer includes `is_deleted` field
- [ ] Endpoint handles soft-delete (new or existing)
- [ ] Dependency injection updated
- [ ] Existing queries verified (`.objects` now auto-filters deleted)
- [ ] Data warehouse query updated with `is_deleted = 0` (if model has a query in `app/data_warehouse/`)
- [ ] Data warehouse `post_delete` tests updated (soft-delete preserves DW records)
