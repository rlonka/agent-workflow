# Tests worth keeping

A good test verifies **behaviour through a public interface** and reads like a
specification: "user can check out with a valid cart" says what capability exists and
survives any refactor that keeps that capability.

## Good

```python
def test_checkout_with_valid_cart_is_confirmed():
    cart = Cart()
    cart.add(product)
    assert checkout(cart, payment_method).status == "confirmed"
```

- tests behaviour callers care about, through the public API only;
- describes *what*, not *how*; one logical assertion;
- survives internal refactors.

## Bad

**Coupled to the implementation:** breaks on a refactor although behaviour didn't change.

```python
# BAD: asserts on an internal collaborator
def test_checkout_calls_payment_service(mocker):
    process = mocker.patch("shop.payment_service.process")
    checkout(cart, payment)
    process.assert_called_once_with(cart.total)

# BAD: bypasses the interface to verify    # GOOD: verifies through the interface
def test_create_user_saves_row(db):         def test_created_user_is_retrievable():
    create_user(name="Alice")                   user = create_user(name="Alice")
    assert db.query("SELECT ...")               assert get_user(user.id).name == "Alice"
```

Red flags: mocking internal collaborators, testing private functions, asserting on call
counts or order, a test name that describes *how*.

**Tautological:** the expected value is computed the way the code computes it, so the test
passes by construction. Expected values come from an independent source: a known literal,
a worked example, the spec.

```python
# BAD                                                   # GOOD
expected = sum(i.price for i in items)                  assert total([Item(10), Item(5)]) == 15
assert total(items) == expected
```

## When to mock

Only at **system boundaries**: external APIs, time and randomness, sometimes the database
(prefer a test database) or the file system. Never mock your own modules or anything else
you control.

Make boundaries easy to mock: pass the dependency in instead of constructing it inside,
and prefer one function per external operation (`get_user`, `create_order`) over one
generic `fetch(endpoint, options)` that every mock has to branch on.
