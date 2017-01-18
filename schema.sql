CREATE TABLE lists (
  id serial PRIMARY KEY,
  name text UNIQUE NOT NULL
);

CREATE TABLE todos (
  id serial PRIMARY KEY,
  name text UNIQUE NOT NULL,
  status boolean NOT NULL DEFAULT false,
  list_id integer NOT NULL REFERENCES lists(id)
);