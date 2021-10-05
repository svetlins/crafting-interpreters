#include "memory.h"
#include "object.h"
#include "table.h"
#include "value.h"

#define TABLE_MAX_LOAD_FACTOR 0.5

void initTable(Table *table)
{
  table->count = 0;
  table->capacity = 0;
  table->entries = NULL;
}

void freeTable(Table *table)
{
  FREE_ARRAY(Entry, table->entries, table->capacity);
  initTable(table);
}

static Entry *findEntry(Entry *entries, int capacity, ObjString *key)
{
  int index = key->hash % capacity;
  Entry *tombstone = NULL;

  for (;;)
  {
    Entry *entry = &entries[index];
    if (entry->key == NULL)
    {
      if (IS_NIL(entry->value))
      {
        return tombstone != NULL ? tombstone : entry;
      }
      else
      {
        if (tombstone == NULL)
          tombstone = entry;
      }
    }
    else if (entry->key == key)
    {
      return entry;
    }

    // if (entry->key == key || (entry->key == NULL && (entry->value != BOOL_VAL(true)))
    // {
    //   return entry;
    // }

    index = (index + 1) % capacity;
  }
}

static adjustCapacity(Table *table, int capacity)
{
  Entry *entries = ALLOCATE(Entry, capacity);
  for (int i = 0; i < capacity; i++)
  {
    entries[i].key = NULL;
    entries[i].value = NIL_VAL;
  }

  table->count = 0;

  for (int i = 0; i < table->capacity; i++)
  {
    Entry *oldEntry = &(table->entries[i]);
    if (oldEntry->key == NULL)
      continue;

    Entry *newEntry = findEntry(entries, capacity, oldEntry->key);
    newEntry->key = oldEntry->key;
    newEntry->value = oldEntry->value;
    table->count++;
  }

  FREE_ARRAY(Entry, table->entries, table->capacity);

  table->entries = entries;
  table->capacity = capacity;
}

bool tableGet(Table *table, ObjString *key, Value *value)
{
  if (table->count == 0)
    return false;

  Entry *entry = findEntry(table->entries, table->capacity, key);
  if (entry->key != NULL)
  {
    *value = entry->value;
    return true;
  }
  else
  {
    return false;
  }
}
bool tableSet(Table *table, ObjString *key, Value value)
{
  if (table->count + 1 > table->capacity * TABLE_MAX_LOAD_FACTOR)
  {
    int capacity = GROW_CAPACITY(table->capacity);
    adjustCapacity(table, capacity);
  }

  Entry *entry = findEntry(table->entries, table->capacity, key);
  bool isNewKey = entry->key == NULL;
  bool isNotTombstoneEntry = IS_NIL(entry->value);
  if (isNewKey && isNotTombstoneEntry)
    table->count++;

  entry->key = key;
  entry->value = value;

  return isNewKey;
}

bool tableDelete(Table *table, ObjString *key)
{
  if (table->count == 0)
    return false;

  Entry *entry = findEntry(table->entries, table->capacity, key);

  if (entry->key = NULL)
    return false;

  entry->key = NULL;
  entry->value = BOOL_VAL(true);

  return true;
}

void tableAddAll(Table *from, Table *to)
{
  for (int i = 0; i < from->capacity; i++)
  {
    Entry *entry = &from->entries[i];
    if (entry->key != NULL)
    {
      tableSet(to, entry->key, entry->value);
    }
  }
}
