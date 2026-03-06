-- Recipe Hub seed data
-- Designed to be safe to re-run (uses ON CONFLICT).

-- Users
INSERT INTO users (email, username, password_hash, display_name, bio)
VALUES
  ('demo1@recipehub.local', 'demo1', 'demo_password_hash', 'Demo User 1', 'Demo account for local testing'),
  ('demo2@recipehub.local', 'demo2', 'demo_password_hash', 'Demo User 2', 'Second demo account for local testing')
ON CONFLICT (email) DO NOTHING;

-- Tags
INSERT INTO tags (name, slug)
VALUES
  ('Breakfast', 'breakfast'),
  ('Dinner', 'dinner'),
  ('Vegetarian', 'vegetarian'),
  ('Dessert', 'dessert'),
  ('Quick', 'quick')
ON CONFLICT (slug) DO NOTHING;

-- Recipes
-- Ensure we have an author id (demo1)
WITH author AS (
  SELECT id FROM users WHERE email = 'demo1@recipehub.local' LIMIT 1
)
INSERT INTO recipes (author_user_id, title, description, prep_minutes, cook_minutes, servings, visibility)
SELECT
  author.id,
  'Avocado Toast',
  'Crispy toast topped with smashed avocado, lemon, salt, and pepper.',
  5,
  5,
  1,
  'public'
FROM author
ON CONFLICT DO NOTHING;

WITH author AS (
  SELECT id FROM users WHERE email = 'demo1@recipehub.local' LIMIT 1
)
INSERT INTO recipes (author_user_id, title, description, prep_minutes, cook_minutes, servings, visibility)
SELECT
  author.id,
  'One-Pot Pasta',
  'A simple one-pot pasta with tomatoes, garlic, and basil.',
  10,
  15,
  2,
  'public'
FROM author
ON CONFLICT DO NOTHING;

-- Ingredients & steps for Avocado Toast
WITH r AS (
  SELECT id FROM recipes WHERE title = 'Avocado Toast' ORDER BY id DESC LIMIT 1
)
INSERT INTO recipe_ingredients (recipe_id, position, name, quantity, unit, note)
SELECT r.id, x.position, x.name, x.quantity, x.unit, x.note
FROM r
JOIN (VALUES
  (1, 'Bread', '2', 'slices', NULL),
  (2, 'Avocado', '1', 'whole', 'ripe'),
  (3, 'Lemon juice', '1', 'tsp', NULL),
  (4, 'Salt', NULL, NULL, 'to taste'),
  (5, 'Black pepper', NULL, NULL, 'to taste')
) AS x(position, name, quantity, unit, note) ON TRUE
ON CONFLICT (recipe_id, position) DO NOTHING;

WITH r AS (
  SELECT id FROM recipes WHERE title = 'Avocado Toast' ORDER BY id DESC LIMIT 1
)
INSERT INTO recipe_steps (recipe_id, position, instruction)
SELECT r.id, x.position, x.instruction
FROM r
JOIN (VALUES
  (1, 'Toast the bread until golden.'),
  (2, 'Mash avocado with lemon juice, salt, and pepper.'),
  (3, 'Spread avocado mixture on toast and serve.')
) AS x(position, instruction) ON TRUE
ON CONFLICT (recipe_id, position) DO NOTHING;

-- Tag relations
WITH r AS (
  SELECT id FROM recipes WHERE title = 'Avocado Toast' ORDER BY id DESC LIMIT 1
),
t AS (
  SELECT id, slug FROM tags WHERE slug IN ('breakfast', 'quick', 'vegetarian')
)
INSERT INTO recipe_tags (recipe_id, tag_id)
SELECT r.id, t.id FROM r CROSS JOIN t
ON CONFLICT DO NOTHING;

-- Ingredients & steps for One-Pot Pasta
WITH r AS (
  SELECT id FROM recipes WHERE title = 'One-Pot Pasta' ORDER BY id DESC LIMIT 1
)
INSERT INTO recipe_ingredients (recipe_id, position, name, quantity, unit, note)
SELECT r.id, x.position, x.name, x.quantity, x.unit, x.note
FROM r
JOIN (VALUES
  (1, 'Spaghetti', '200', 'g', NULL),
  (2, 'Cherry tomatoes', '200', 'g', NULL),
  (3, 'Garlic', '2', 'cloves', 'minced'),
  (4, 'Olive oil', '1', 'tbsp', NULL),
  (5, 'Basil', NULL, NULL, 'fresh'),
  (6, 'Salt', NULL, NULL, 'to taste')
) AS x(position, name, quantity, unit, note) ON TRUE
ON CONFLICT (recipe_id, position) DO NOTHING;

WITH r AS (
  SELECT id FROM recipes WHERE title = 'One-Pot Pasta' ORDER BY id DESC LIMIT 1
)
INSERT INTO recipe_steps (recipe_id, position, instruction)
SELECT r.id, x.position, x.instruction
FROM r
JOIN (VALUES
  (1, 'Add pasta, tomatoes, garlic, olive oil, and enough water to cover into a pot.'),
  (2, 'Simmer until pasta is cooked; stir occasionally.'),
  (3, 'Season with salt and top with basil.')
) AS x(position, instruction) ON TRUE
ON CONFLICT (recipe_id, position) DO NOTHING;

WITH r AS (
  SELECT id FROM recipes WHERE title = 'One-Pot Pasta' ORDER BY id DESC LIMIT 1
),
t AS (
  SELECT id, slug FROM tags WHERE slug IN ('dinner', 'quick', 'vegetarian')
)
INSERT INTO recipe_tags (recipe_id, tag_id)
SELECT r.id, t.id FROM r CROSS JOIN t
ON CONFLICT DO NOTHING;

-- Favorite (demo2 favorites Avocado Toast)
WITH u AS (
  SELECT id FROM users WHERE email = 'demo2@recipehub.local' LIMIT 1
),
r AS (
  SELECT id FROM recipes WHERE title = 'Avocado Toast' ORDER BY id DESC LIMIT 1
)
INSERT INTO favorites (user_id, recipe_id)
SELECT u.id, r.id FROM u CROSS JOIN r
ON CONFLICT DO NOTHING;
